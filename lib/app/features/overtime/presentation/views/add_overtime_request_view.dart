import 'package:flutter/material.dart';

import '../widgets/add_overtime_request_view_body.dart';

class AddOvertimeRequest extends StatelessWidget {
  const AddOvertimeRequest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0,vertical: 18),
        child: AddOvertimeRequestViewBody(),
      ),
    );
  }
}
