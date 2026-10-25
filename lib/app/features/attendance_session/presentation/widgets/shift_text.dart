import 'package:flutter/widgets.dart';

import '../../../../../core/extensions/date_time_format.dart';
import '../../domain/entities/shift_entity.dart';

/// Shift times as text, e.g. "8:00 AM" and "8:00 AM – 4:00 PM".
extension ShiftText on ShiftEntity {
  String startText(BuildContext context) =>
      startOn(DateTime.now()).formatTime(context);

  String endText(BuildContext context) =>
      endOn(DateTime.now()).formatTime(context);

  String rangeText(BuildContext context) =>
      '${startText(context)} – ${endText(context)}';
}
