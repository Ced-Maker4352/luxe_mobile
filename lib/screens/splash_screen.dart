import 'package:flutter/material.dart';
import 'auth_gate.dart';
import '../shared/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: AppMotion.cinematic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: AppMotion.cinematic),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(CinematicPageRoute(page: const AuthGate()));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [AppColors.softCharcoal, AppColors.midnightNavy],
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LUXE AI STUDIO',
                          style: AppTypography.h1Display(),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 2,
                          width: 60,
                          color: AppColors.matteGold,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'PORTRAIT BOUTIQUE',
                          style: AppTypography.microBold(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Footer
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'BEYOND PHOTOGRAPHY',
                  style: AppTypography.micro(color: Colors.white24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
