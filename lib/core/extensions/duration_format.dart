import 'package:flutter/widgets.dart';

import 'context_l10n.dart';

/// Text for durations, like `DateTimeFormatX` is for dates.
extension DurationFormatX on Duration {
  /// 7h 19m, or 34m under an hour. Units are translated.
  String formatHoursMinutes(BuildContext context) {
    final l10n = context.l10n;
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    return hours == 0
        ? l10n.durationMinutes(minutes)
        : l10n.durationHoursMinutes(hours, minutes);
  }

  /// 03:26:18, for a running timer.
  String formatStopwatch() {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final seconds = isNegative ? Duration.zero : this;
    return '${twoDigits(seconds.inHours)}:'
        '${twoDigits(seconds.inMinutes.remainder(60))}:'
        '${twoDigits(seconds.inSeconds.remainder(60))}';
  }
}
