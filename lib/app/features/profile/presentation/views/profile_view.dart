import 'package:flutter/material.dart';

import '../widgets/profile_view_body.dart';

/// Profile tab: the signed-in account and sign-out.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: ProfileViewBody(),
        ),
      ),
    );
  }
}
