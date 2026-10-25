import 'package:flutter/material.dart';

import '../../domain/entities/attendance_type.dart';
import '../widgets/success/attendance_success_view_body.dart';

/// Shown after the user confirms a check-in or a check-out.
class AttendanceSuccessView extends StatelessWidget {
  const AttendanceSuccessView({super.key, required this.type});

  final AttendanceType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
        child: SafeArea(child: AttendanceSuccessViewBody(type: type)),
      ),
    );
  }
}
