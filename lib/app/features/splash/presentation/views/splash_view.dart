import 'dart:async';

import 'package:efs_work_tracker/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../auth/presentation/manager/auth_cubit/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Animations
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Start animation
    _controller.forward();

    // Navigate after 3 seconds
    _navigationTimer = Timer(const Duration(seconds: 3), _leave);
  }

  /// Goes home once the session is restored; the router redirects to
  /// sign-in or the password change when needed.
  Future<void> _leave() async {
    final auth = context.read<AuthCubit>();
    if (auth.state is AuthChecking) {
      await auth.stream.firstWhere((state) => state is! AuthChecking);
    }
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose(); // clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SvgPicture.asset(
              Assets.images.iconlogo.path,
              width: 100,
              height: 100,
            ),
          ),
        ),
      ),
    );
  }
}
