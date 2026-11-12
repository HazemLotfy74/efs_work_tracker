import 'dart:typed_data';

import 'package:archive/archive.dart';

/// The cell formats the HR workbook uses. Their order is the index in
/// `styles.xml` (`cellXfs`), so only append.
enum XlsxStyle {
  text,

  /// Text that starts like a formula (`=`, `+`, `-`, `@`): Excel's quote
  /// prefix shows it as typed. Values are never written as formulas anyway.
  textQuoted,
  wrap,
  bold,
  title,
  subtitle,
  header,
  date,
  time,
  hours,
  integer,
  percent,
  good,
  warning,
  bad,
  totalLabel,
  totalHours,
  totalInteger,
  label,
}

/// One cell: a [String], [num], [DateTime] (local wall-clock time, stored as
/// an Excel date serial) or `null` (empty).
class XlsxCell {
  const XlsxCell(this.value, [this.style = XlsxStyle.text]);

  final Object? value;
  final XlsxStyle style;
}

class XlsxSheet {
  XlsxSheet({
    required this.name,
    required this.widths,
    this.headerRow,
    this.landscape = true,
  });

  /// At most 31 characters, none of `[]:*?/\`.
  final String name;

  /// Column widths in characters.
  final List<double> widths;

  /// 0-based row with the column headers: rows down to it stay frozen,
  /// it gets an auto filter and repeats on every printed page.
  final int? headerRow;
  final bool landscape;

  final List<List<XlsxCell?>> rows = [];

  void add(List<XlsxCell?> row) => rows.add(row);
}

/// A minimal Office Open XML (`.xlsx`) writer: inline strings, numbers,
/// dates, a fixed style table, frozen header rows, auto filters and print
/// setup. Enough for formatted reports; it writes no formulas.
class XlsxWorkbook {
  XlsxWorkbook({required this.title, required this.creator, DateTime? created})
    : created = (created ?? DateTime.now()).toUtc();

  final String title;
  final String creator;
  final DateTime created;
  final List<XlsxSheet> sheets = [];

  Uint8List encode() {
    final names = <String>{};
    for (final sheet in sheets) {
      if (!_validName.hasMatch(sheet.name) || !names.add(sheet.name)) {
        throw ArgumentError.value(sheet.name, 'sheet name');
      }
    }
    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes()))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRels))
      ..addFile(ArchiveFile.string('docProps/core.xml', _core()))
      ..addFile(ArchiveFile.string('docProps/app.xml', _app))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbook()))
      ..addFile(
        ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRels()),
      )
      ..addFile(ArchiveFile.string('xl/styles.xml', _styles));
    for (final (i, sheet) in sheets.indexed) {
      archive.addFile(
        ArchiveFile.string('xl/worksheets/sheet${i + 1}.xml', _sheet(sheet)),
      );
    }
    return ZipEncoder().encodeBytes(archive);
  }

  static final _validName = RegExp(r'^[^\[\]:*?/\\]{1,31}$');

  String _contentTypes() {
    final sheetTypes = [
      for (var i = 1; i <= sheets.length; i++)
        '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
    ].join();
    return '$_xmlHeader<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
        '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
        '$sheetTypes</Types>';
  }

  static const _rootRels =
      '$_xmlHeader<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
      '</Relationships>';

  static const _app =
      '$_xmlHeader<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">'
      '<Application>EFS WorkTrack</Application></Properties>';

  String _core() {
    final stamp = '${created.toIso8601String().split('.').first}Z';
    return '$_xmlHeader<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        '<dc:title>${_escape(title)}</dc:title><dc:creator>${_escape(creator)}</dc:creator>'
        '<dcterms:created xsi:type="dcterms:W3CDTF">$stamp</dcterms:created>'
        '<dcterms:modified xsi:type="dcterms:W3CDTF">$stamp</dcterms:modified>'
        '</cp:coreProperties>';
  }

  String _workbook() {
    final list = StringBuffer();
    final defined = StringBuffer();
    for (final (i, sheet) in sheets.indexed) {
      list.write(
        '<sheet name="${_escape(sheet.name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>',
      );
      final header = sheet.headerRow;
      if (header != null) {
        final quoted = "'${_escape(sheet.name.replaceAll("'", "''"))}'";
        final last = sheet.rows.length;
        final lastColumn = _column(sheet.widths.length - 1);
        defined
          ..write(
            '<definedName name="_xlnm._FilterDatabase" localSheetId="$i" hidden="1">'
            '$quoted!\$A\$${header + 1}:\$$lastColumn\$$last</definedName>',
          )
          ..write(
            '<definedName name="_xlnm.Print_Titles" localSheetId="$i">'
            '$quoted!\$${header + 1}:\$${header + 1}</definedName>',
          );
      }
    }
    return '$_xmlHeader<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<bookViews><workbookView/></bookViews><sheets>$list</sheets>'
        '${defined.isEmpty ? '' : '<definedNames>$defined</definedNames>'}'
        '</workbook>';
  }

  String _workbookRels() {
    final rels = StringBuffer();
    for (var i = 1; i <= sheets.length; i++) {
      rels.write(
        '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>',
      );
    }
    rels.write(
      '<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>',
    );
    return '$_xmlHeader<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">$rels</Relationships>';
  }

  String _sheet(XlsxSheet sheet) {
    final out = StringBuffer(
      '$_xmlHeader<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>',
    );
    final lastColumn = _column(sheet.widths.length - 1);
    out.write(
      '<dimension ref="A1:$lastColumn${sheet.rows.isEmpty ? 1 : sheet.rows.length}"/>',
    );
    final header = sheet.headerRow;
    out.write('<sheetViews><sheetView workbookViewId="0">');
    if (header != null) {
      out.write(
        '<pane ySplit="${header + 1}" topLeftCell="A${header + 2}" activePane="bottomLeft" state="frozen"/>'
        '<selection pane="bottomLeft" activeCell="A${header + 2}" sqref="A${header + 2}"/>',
      );
    }
    out.write(
      '</sheetView></sheetViews><sheetFormatPr defaultRowHeight="15"/><cols>',
    );
    for (final (i, width) in sheet.widths.indexed) {
      out.write(
        '<col min="${i + 1}" max="${i + 1}" width="$width" customWidth="1"/>',
      );
    }
    out.write('</cols><sheetData>');
    for (final (r, row) in sheet.rows.indexed) {
      out.write('<row r="${r + 1}">');
      for (final (c, cell) in row.indexed) {
        if (cell == null) continue;
        out.write(_cell('${_column(c)}${r + 1}', cell));
      }
      out.write('</row>');
    }
    out.write('</sheetData>');
    if (header != null && sheet.rows.length > header) {
      out.write(
        '<autoFilter ref="A${header + 1}:$lastColumn${sheet.rows.length}"/>',
      );
    }
    out
      ..write(
        '<pageMargins left="0.4" right="0.4" top="0.5" bottom="0.5" header="0.3" footer="0.3"/>',
      )
      ..write(
        '<pageSetup paperSize="9" orientation="${sheet.landscape ? 'landscape' : 'portrait'}" fitToWidth="1" fitToHeight="0"/>',
      )
      ..write('</worksheet>');
    return out.toString();
  }

  static String _cell(String ref, XlsxCell cell) {
    final value = cell.value;
    var style = cell.style;
    switch (value) {
      case null:
        return '<c r="$ref" s="${style.index}"/>';
      case num():
        if (!value.isFinite) return '<c r="$ref" s="${style.index}"/>';
        return '<c r="$ref" s="${style.index}"><v>$value</v></c>';
      case DateTime():
        return '<c r="$ref" s="${style.index}"><v>${excelSerial(value)}</v></c>';
      default:
        final text = _clean(value.toString());
        if (style == XlsxStyle.text && _formulaLike.hasMatch(text)) {
          style = XlsxStyle.textQuoted;
        }
        return '<c r="$ref" s="${style.index}" t="inlineStr"><is>'
            '<t xml:space="preserve">${_escape(text)}</t></is></c>';
    }
  }

  static final _formulaLike = RegExp(r'^[=+\-@\t\r]');

  /// Days since 1899-12-30 (Excel's date system), with the time of day as
  /// the fraction. [value]'s fields are used as they are (wall-clock time).
  static double excelSerial(DateTime value) {
    final asUtc = DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    );
    final ms = asUtc.difference(DateTime.utc(1899, 12, 30)).inMilliseconds;
    return ms / Duration.millisecondsPerDay;
  }

  /// `0` → `A`, `25` → `Z`, `26` → `AA`.
  static String _column(int index) {
    var name = '';
    for (var n = index + 1; n > 0; n = (n - 1) ~/ 26) {
      name = String.fromCharCode(65 + (n - 1) % 26) + name;
    }
    return name;
  }

  /// Drops characters XML 1.0 can't contain.
  static String _clean(String text) => text.replaceAll(
    RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F￾￿]'),
    '',
  );

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static const _xmlHeader =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';

  // Colors follow the app palette: green500 #008C43, green50 #E8F5EE,
  // amber50 #FFF4DC / amber800 #8D5A1D, red50 #FEEBED / red500 #C9334A.
  static final _styles = () {
    const fonts =
        '<fonts count="8">'
        '<font><sz val="10"/><color rgb="FF17352E"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="10"/><color rgb="FF17352E"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="16"/><color rgb="FF008C43"/><name val="Calibri"/><family val="2"/></font>'
        '<font><i/><sz val="10"/><color rgb="FF6B8079"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="10"/><color rgb="FF155843"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="10"/><color rgb="FF8D5A1D"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="10"/><color rgb="FFC9334A"/><name val="Calibri"/><family val="2"/></font>'
        '</fonts>';
    String fill(String rgb) =>
        '<fill><patternFill patternType="solid"><fgColor rgb="$rgb"/><bgColor indexed="64"/></patternFill></fill>';
    final fills =
        '<fills count="7"><fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill>'
        '${fill('FF008C43')}${fill('FFE8F5EE')}${fill('FFFFF4DC')}${fill('FFFEEBED')}${fill('FFF3F7F5')}</fills>';
    const borders =
        '<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border><left style="thin"><color rgb="FFDFE9E4"/></left><right style="thin"><color rgb="FFDFE9E4"/></right>'
        '<top style="thin"><color rgb="FFDFE9E4"/></top><bottom style="thin"><color rgb="FFDFE9E4"/></bottom><diagonal/></border></borders>';
    const numFmts =
        '<numFmts count="3"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/>'
        '<numFmt numFmtId="165" formatCode="hh:mm"/><numFmt numFmtId="166" formatCode="0.00"/></numFmts>';

    String xf(
      int numFmt,
      int font,
      int fill,
      int border, {
      bool wrap = false,
      bool quotePrefix = false,
    }) =>
        '<xf numFmtId="$numFmt" fontId="$font" fillId="$fill" borderId="$border" xfId="0"'
        '${numFmt > 0 ? ' applyNumberFormat="1"' : ''} applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"'
        '${quotePrefix ? ' quotePrefix="1"' : ''}>'
        '<alignment vertical="center"${wrap ? ' wrapText="1"' : ''}/></xf>';
    final xfs = <XlsxStyle, String>{
      XlsxStyle.text: xf(0, 0, 0, 1),
      XlsxStyle.textQuoted: xf(0, 0, 0, 1, quotePrefix: true),
      XlsxStyle.wrap: xf(0, 0, 0, 1, wrap: true),
      XlsxStyle.bold: xf(0, 1, 0, 1),
      XlsxStyle.title: xf(0, 3, 0, 0),
      XlsxStyle.subtitle: xf(0, 4, 0, 0),
      XlsxStyle.header: xf(0, 2, 2, 1, wrap: true),
      XlsxStyle.date: xf(164, 0, 0, 1),
      XlsxStyle.time: xf(165, 0, 0, 1),
      XlsxStyle.hours: xf(166, 0, 0, 1),
      XlsxStyle.integer: xf(1, 0, 0, 1),
      XlsxStyle.percent: xf(9, 0, 0, 1),
      XlsxStyle.good: xf(0, 5, 3, 1),
      XlsxStyle.warning: xf(0, 6, 4, 1),
      XlsxStyle.bad: xf(0, 7, 5, 1),
      XlsxStyle.totalLabel: xf(0, 1, 6, 1),
      XlsxStyle.totalHours: xf(166, 1, 6, 1),
      XlsxStyle.totalInteger: xf(1, 1, 6, 1),
      XlsxStyle.label: xf(0, 1, 6, 1),
    };
    final cellXfs = [for (final style in XlsxStyle.values) xfs[style]!];
    return '$_xmlHeader<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '$numFmts$fonts$fills$borders'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="${cellXfs.length}">${cellXfs.join()}</cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>';
  }();
}
