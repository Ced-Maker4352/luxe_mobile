import 'package:flutter/material.dart';
import 'auth_gate.dart';
import '../shared/constants.dart';
import '../widgets/cinematic_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: CinematicSplash(
        onComplete: () {
          if (mounted) {
            Navigator.of(
              context,
            ).pushReplacement(CinematicPageRoute(page: const AuthGate()));
          }
        },
      ),
    );
  }
}
