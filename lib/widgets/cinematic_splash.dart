import 'package:flutter/material.dart';
import 'dart:async';
import '../shared/constants.dart';

enum CinematicScene {
  intro, // 0-6s
  split, // 6-14s
  groupMode, // 14-22s
  uiInteraction, // 22-30s
  usageSwaps, // 30-40s
  outro, // 40-45s
}

class CinematicSplash extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool isLooping; // for hero sections

  const CinematicSplash({super.key, this.onComplete, this.isLooping = false});

  @override
  State<CinematicSplash> createState() => _CinematicSplashState();
}

class _CinematicSplashState extends State<CinematicSplash>
    with TickerProviderStateMixin {
  CinematicScene _currentScene = CinematicScene.intro;
  Timer? _sceneTimer;
  late AnimationController _fadeController;
  late AnimationController _streakController;
  late AnimationController _cameraController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppMotion.major,
    );

    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (widget.isLooping) {
      _startCondensedLoop();
    } else {
      _startFullStory();
    }
  }

  @override
  void dispose() {
    _sceneTimer?.cancel();
    _fadeController.dispose();
    _streakController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _startFullStory() {
    _currentScene = CinematicScene.intro;
    _cameraController.forward(from: 0.0);
    _streakController.forward(from: 0.0);

    _scheduleScene(CinematicScene.split, 6);
    _scheduleScene(CinematicScene.groupMode, 14);
    _scheduleScene(CinematicScene.uiInteraction, 22);
    _scheduleScene(CinematicScene.usageSwaps, 30);
    _scheduleScene(CinematicScene.outro, 40);

    // Complete
    Timer(const Duration(seconds: 45), () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  void _startCondensedLoop() {
    _currentScene = CinematicScene.split;
    _scheduleScene(CinematicScene.groupMode, 4);
    _scheduleScene(CinematicScene.usageSwaps, 8);
    _scheduleScene(CinematicScene.split, 12, loop: true);
  }

  void _scheduleScene(CinematicScene next, int seconds, {bool loop = false}) {
    _sceneTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() {
          _currentScene = next;
          _cameraController.forward(from: 0.0);
          if (loop && widget.isLooping) {
            _startCondensedLoop();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.midnightNavy,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Light Streak (Scene 1)
          if (_currentScene == CinematicScene.intro)
            AnimatedBuilder(
              animation: _streakController,
              builder: (context, child) {
                return Positioned(
                  top: -200,
                  left: -200 + (1000 * _streakController.value),
                  child: Transform.rotate(
                    angle: 45 * 3.14 / 180,
                    child: Container(
                      width: 2,
                      height: 2000,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.matteGold.withValues(alpha: 0.1),
                            blurRadius: 100,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Main Scene Switcher
          AnimatedSwitcher(
            duration: const Duration(seconds: 2),
            switchInCurve: AppMotion.cinematic,
            switchOutCurve: AppMotion.cinematic,
            child: _buildSceneContent(),
          ),

          // Audio Hum (Placeholder concept)
          // In a real app, use audio_players or similar
        ],
      ),
    );
  }

  Widget _buildSceneContent() {
    switch (_currentScene) {
      case CinematicScene.intro:
        return _buildIntroScene();
      case CinematicScene.split:
        return _buildSplitScene();
      case CinematicScene.groupMode:
        return _buildGroupModeScene();
      case CinematicScene.uiInteraction:
        return _buildUIScene();
      case CinematicScene.usageSwaps:
        return _buildUsageSwapsScene();
      case CinematicScene.outro:
        return _buildOutroScene();
    }
  }

  Widget _buildIntroScene() {
    return KeyedSubtree(
      key: const ValueKey('intro'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 3),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    'LUXE AI STUDIO',
                    style: AppTypography.h1Display(
                      color: Colors.white,
                    ).copyWith(letterSpacing: 8 * value),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 3),
              curve: const Interval(0.5, 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    'A Digital Luxury Photoshoot Platform',
                    style: AppTypography.microBold(color: Colors.white54),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitScene() {
    return KeyedSubtree(
      key: const ValueKey('split'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Identity Lock Visualization
            Container(
              height: 300,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main ID Card (Real Image with Lock Overlay)
                  Transform.translate(
                    offset: const Offset(0, 0),
                    child: Container(
                      width: 180,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/hero_1.jpg'),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: AppColors.matteGold,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              color: AppColors.matteGold,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "IDENTITY\nLOCKED",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.matteGold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Floating Selfies (Real Images)
                  Positioned(
                    left: 20,
                    top: 40,
                    child: _buildRealSelfie('assets/images/hero_2.jpg'),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 60,
                    child: _buildRealSelfie('assets/images/hero_3.jpg'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Identity Lock™',
              style: AppTypography.h2Display(color: AppColors.matteGold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Face. Every Style.',
              style: AppTypography.bodyRegular(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealSelfie(String assetPath) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.softCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
        image: DecorationImage(image: AssetImage(assetPath), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildGroupModeScene() {
    return KeyedSubtree(
      key: const ValueKey('groupMode'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group Mode Visualization
            Container(
              height: 280,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Central Group Image (Composite Vibe)
                  Container(
                    width: 260,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.matteGold.withValues(alpha: 0.5),
                      ),
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/hero_6.jpg',
                        ), // Using independent_artist or hero_6 as group vibe
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.matteGold.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Individual Contributors (Orbiting)
                  Positioned(
                    top: 0,
                    child: _buildRealSelfie('assets/images/hero_4.jpg'),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: _buildRealSelfie('assets/images/hero_5.jpg'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 20,
                    child: _buildRealSelfie('assets/images/hero_7.jpg'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Group Mode™',
              style: AppTypography.h2Display(color: AppColors.matteGold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bring everyone into the same studio.',
              style: AppTypography.bodyRegular(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUIScene() {
    return KeyedSubtree(
      key: const ValueKey('ui'),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.upload_file,
                  color: AppColors.matteGold,
                  size: 48,
                ),
                const SizedBox(height: 24),
                // Processing shimmer
                SizedBox(
                  width: 200,
                  height: 2,
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.matteGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Upload once. Create together.',
                style: AppTypography.h3Display(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSwapsScene() {
    return KeyedSubtree(
      key: const ValueKey('swaps'),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _cameraController,
            builder: (context, child) {
              // Crossfade logic
              // Fades from hero_8 to hero_9 between 30% and 70% of the scene duration
              double opacity = 0.0;
              if (_cameraController.value > 0.3) {
                opacity = (_cameraController.value - 0.3) / 0.4;
                if (opacity > 1.0) opacity = 1.0;
              }

              return Transform.scale(
                scale: 1.0 + (0.1 * _cameraController.value),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image 1: hero_8
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/hero_8.jpg'),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                    // Image 2: hero_9 (Fading in)
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/hero_9.jpg'),
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Center(
            child: Text(
              'From boardrooms to billboards.',
              style: AppTypography.h2Display(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutroScene() {
    return KeyedSubtree(
      key: const ValueKey('outro'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LUXE AI STUDIO',
              style: AppTypography.h1Display(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Vision. Professionally Realized.',
              style: AppTypography.microBold(color: Colors.white54),
            ),
            const SizedBox(height: 48),
            // CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.matteGold),
                borderRadius: BorderRadius.circular(1),
              ),
              child: Text(
                'CREATE YOUR STUDIO',
                style: AppTypography.button(color: AppColors.matteGold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
