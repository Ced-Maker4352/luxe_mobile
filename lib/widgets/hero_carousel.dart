import 'dart:async';
import 'package:flutter/material.dart';

class BeforeAfterPair {
  final String beforeImage;
  final String afterImage;
  final String label;

  const BeforeAfterPair({
    required this.beforeImage,
    required this.afterImage,
    required this.label,
  });
}

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  // Placeholder images - User should replace with their specific assets
  final List<BeforeAfterPair> _pairs = const [
    BeforeAfterPair(
      beforeImage:
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=800", // Casual
      afterImage:
          "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=800", // Glam
      label: "Everyday to Editorial",
    ),
    BeforeAfterPair(
      beforeImage:
          "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=800", // Male Casual
      afterImage:
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=800", // Male Pro
      label: "Snap to Studio",
    ),
    BeforeAfterPair(
      beforeImage:
          "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&q=80&w=800", // Casual Girl
      afterImage:
          "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&q=80&w=800", // Model Girl
      label: "Vision Amplified",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _pairs.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Carousel Background
        PageView.builder(
          controller: _pageController,
          itemCount: _pairs.length,
          itemBuilder: (context, index) {
            return _buildCarouselItem(_pairs[index]);
          },
        ),

        // Gradient Overlay for Text Readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.6), // Darker at bottom
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(BeforeAfterPair pair) {
    return Row(
      children: [
        // Before Image (Left Half)
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                pair.beforeImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[900]),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "BEFORE",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Divider
        Container(width: 2, color: const Color(0xFFD4AF37)),
        // After Image (Right Half)
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                pair.afterImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[800]),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "AFTER",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
