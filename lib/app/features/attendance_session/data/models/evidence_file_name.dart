import '../../domain/entities/attendance_type.dart';

/// Who an evidence photo belongs to, from the employee's own profile.
typedef EvidenceOwner = ({
  String fullName,
  String username,
  String employeeCode,
});

/// The Storage name of a check-in or check-out selfie.
///
/// Always `<auth uid>/…`: the bucket's upload policy, `check_in` /
/// `check_out` (`private.assert_selfie`) and the read policy all key on
/// that folder. Inside it, [descriptive] names identify the photo:
///
/// `Ahmed_Mohamed_EMP-125_check_in_20261101_060530_a81f2c0d.jpg`
///
/// - name: the full name reduced to ASCII letters and digits; an Arabic
///   (or empty) name falls back to the username, which the database keeps
///   ASCII (`^[a-z0-9][a-z0-9._-]{2,63}$`);
/// - the employee code: stable and ASCII by constraint;
/// - `check_in` / `check_out`, so the two photos of a day never collide;
/// - when the photo was taken, in UTC (`yyyyMMdd_HHmmss`);
/// - 8 random hex characters, so every photo gets its own name.
abstract final class EvidenceFileName {
  /// Longest name part kept, so the key stays well under Storage limits.
  static const maxNameLength = 40;

  static String descriptive({
    required String userId,
    required EvidenceOwner owner,
    required AttendanceType type,
    required DateTime takenAt,
    required String uniqueId,
    required String extension,
  }) {
    final name = asciiName(owner.fullName);
    final person = name.isNotEmpty ? name : asciiName(owner.username);
    final code = asciiName(owner.employeeCode);
    final kind = switch (type) {
      AttendanceType.checkIn => 'check_in',
      AttendanceType.checkOut => 'check_out',
    };
    final parts = [
      if (person.isNotEmpty) person,
      if (code.isNotEmpty) code,
      kind,
      _timestamp(takenAt.toUtc()),
      uniqueId.replaceAll('-', '').substring(0, 8).toLowerCase(),
    ];
    return '$userId/${parts.join('_')}.$extension';
  }

  /// The original naming: `<auth uid>/<uuid>.<ext>`.
  static String opaque({
    required String userId,
    required String uniqueId,
    required String extension,
  }) => '$userId/$uniqueId.$extension';

  /// Letters, digits and `-` only, words joined by `_`, at most
  /// [maxNameLength] characters. Anything else (Arabic letters, spaces,
  /// punctuation, slashes) is dropped, so the result is always a safe
  /// Storage key segment, possibly empty.
  static String asciiName(String value) {
    final words = value
        .split(RegExp(r'[\s_.]+'))
        .map((word) => word.replaceAll(RegExp(r'[^A-Za-z0-9-]'), ''))
        .where(
          (word) => word.isNotEmpty && word.contains(RegExp('[A-Za-z0-9]')),
        )
        .toList();
    final joined = words.join('_');
    return joined.length <= maxNameLength
        ? joined
        : joined.substring(0, maxNameLength);
  }

  static String _timestamp(DateTime utc) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}${two(utc.month)}'
        '${two(utc.day)}_${two(utc.hour)}${two(utc.minute)}${two(utc.second)}';
  }
}
