import 'package:efs_work_tracker/app/features/cash_request/presentation/widgets/all_cashes_view_body.dart';
import 'package:flutter/material.dart';

class AllCashesView extends StatelessWidget {
  const AllCashesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0,vertical: 18),
        child: AllCashesViewBody(),
      ),
    );
  }
}
