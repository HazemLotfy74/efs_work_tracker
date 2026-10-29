import '../../l10n/app_localizations.dart';

/// The database keeps 1 to 2000 characters of a trimmed reason.
String? requestReasonValidator(String? reason, AppLocalizations l10n) {
  final length = (reason ?? '').trim().runes.length;
  if (length == 0) return l10n.requestReasonRequired;
  if (length > 2000) return l10n.requestReasonTooLong;
  return null;
}
