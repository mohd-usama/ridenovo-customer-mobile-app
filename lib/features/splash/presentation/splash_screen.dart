import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/profile_setup_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/presentation/main_dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Instant local token check (no network delay on splash)
    await ref.read(authProvider.notifier).checkAuthStatus();

    // 2. Exact 2-second splash screen duration as requested
    await Future.delayed(const Duration(seconds: 2));

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    Widget targetScreen = const LoginScreen();

    if (authState.isAuthenticated) {
      final user = authState.user;
      // If user is explicitly a new user (isNewUser == true), route to Profile Setup.
      // Otherwise (existing user with isNewUser == false), route directly to Main Dashboard.
      if (user?.isNewUser == true) {
        targetScreen = const ProfileSetupScreen();
      } else {
        targetScreen = const MainDashboardScreen();
      }
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Animated Logo & Branding
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Logo Image
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.12),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            height: 120,
                            width: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
                                child: const Icon(Icons.two_wheeler, size: 60, color: Colors.white),
                              );
                            },
                          ),
                        ),
                        const Gap(28),

                        // App Brand Title
                        const Text(
                          'RIDONOVA',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w500, letterSpacing: 3.0, color: AppColors.secondary),
                        ),
                        const Gap(8),

                        // Tagline
                        Text(
                          'Ride Smart, Ride Safe',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // Loading Indicator
            const SpinKitThreeBounce(color: AppColors.primary, size: 24.0),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}
