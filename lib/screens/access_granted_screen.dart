import 'package:flutter/material.dart';
import 'package:luxe_mobile/models/types.dart';
import '../shared/constants.dart';

class AccessGrantedScreen extends StatefulWidget {
  final PackageDetails package;
  final bool isPromoCode;
  final bool singleStyleMode;
  final String? selectedStyleId;

  const AccessGrantedScreen({
    super.key,
    required this.package,
    this.isPromoCode = false,
    this.singleStyleMode = false,
    this.selectedStyleId,
  });

  @override
  State<AccessGrantedScreen> createState() => _AccessGrantedScreenState();
}

class _AccessGrantedScreenState extends State<AccessGrantedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceedToUpload() {
    Navigator.pushReplacementNamed(context, '/identity');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),

              // Animated checkmark
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.matteGold,
                            AppColors.matteGold.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.matteGold.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      widget.isPromoCode
                          ? 'VIP ACCESS GRANTED'
                          : (widget.singleStyleMode
                                ? 'STYLE UNLOCKED'
                                : 'PAYMENT ACCEPTED'),
                      style: const TextStyle(
                        color: AppColors.matteGold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.singleStyleMode
                          ? 'Get ready to create'
                          : 'Welcome to ${widget.package.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.singleStyleMode
                          ? 'Your single style session is ready.'
                          : widget.package.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Package details card
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.softCharcoal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.matteGold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR PACKAGE INCLUDES:',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...widget.package.features
                          .take(4)
                          .map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.diamond_outlined,
                                    color: AppColors.matteGold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Next steps info
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.matteGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.matteGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Next step: Upload your reference photo to begin your AI portrait session.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.matteGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE TO UPLOAD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
