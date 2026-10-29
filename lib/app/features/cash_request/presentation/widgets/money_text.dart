import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../../core/extensions/context_l10n.dart';

/// 250 EGP, or 250.50 EGP when there are piasters.
String formatMoney(BuildContext context, num amount, String currency) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final whole = amount == amount.truncate();
  final text = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: whole ? 0 : 2,
  ).format(amount);
  return context.l10n.moneyAmount(text, currency);
}

/// The amount typed by the employee, or `null` if it is not a number with
/// at most two decimal places. Accepts Arabic digits and decimal commas.
num? parseAmount(String text) {
  final buffer = StringBuffer();
  for (final rune in text.trim().runes) {
    final char = String.fromCharCode(rune);
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(0x30 + rune - 0x0660); // Arabic-Indic ٠-٩
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(0x30 + rune - 0x06F0); // Persian ۰-۹
    } else if (char == ',' || char == '٫') {
      buffer.write('.');
    } else if (char == '٬' || char == ' ') {
      // Thousands separators.
    } else {
      buffer.write(char);
    }
  }
  final normalized = buffer.toString();
  if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(normalized)) return null;
  return num.parse(normalized);
}
