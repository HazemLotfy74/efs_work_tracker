import 'package:efs_work_tracker/app/features/overtime/presentation/widgets/overtime_view_body.dart';
import 'package:flutter/material.dart';

class OvertimeView extends StatelessWidget {
  const OvertimeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0,vertical: 18),
        child: OvertimeViewBody(),
      ),
    );
  }
}
