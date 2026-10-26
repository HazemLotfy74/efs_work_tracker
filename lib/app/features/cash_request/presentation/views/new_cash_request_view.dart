import 'package:efs_work_tracker/app/features/cash_request/presentation/widgets/new_cash_request_view_body.dart';
import 'package:flutter/material.dart';

class NewCashRequestView extends StatelessWidget {
  const NewCashRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0,vertical: 18),
        child: NewCashRequestViewBody(),
      ),
    );
  }
}
