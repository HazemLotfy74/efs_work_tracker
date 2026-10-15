import 'package:flutter/material.dart';

import 'app/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const WorkTrackApp());
}

class WorkTrackApp extends StatelessWidget {
  const WorkTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WorkTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
