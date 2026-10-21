
import 'package:flutter/material.dart';

import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../widgets/attendance_details_view_body.dart';

class AttendanceDetailsView extends StatelessWidget {
  const AttendanceDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0,vertical: 18),
        child: AttendanceDetailsViewBody(),
      ),
    );
  }

}
