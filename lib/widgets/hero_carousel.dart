import 'dart:async';
import 'package:flutter/material.dart';
import '../shared/constants.dart';

class LocalImageItem {
  final String assetPath;
  final String label;

  const LocalImageItem({required this.assetPath, required this.label});
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

  // Expecting 7 user-provided images in assets/images/
  // Label can be customized if needed, currently using generic "Before & After"
  final List<LocalImageItem> _items = const [
    LocalImageItem(
      assetPath: "assets/images/hero_1.jpg",
      label: "Instant Transformation",
    ),
    LocalImageItem(
      assetPath: "assets/images/hero_2.jpg",
      label: "Cinematic Quality",
    ),
    LocalImageItem(
      assetPath: "assets/images/hero_3.jpg",
      label: "Timeless Moments",
    ),
    LocalImageItem(
      assetPath: "assets/images/hero_4.jpg",
      label: "Professional Profile",
    ),
    LocalImageItem(
      assetPath: "assets/images/hero_5.jpg",
      label: "Elegant Portraits",
    ),
    LocalImageItem(
      assetPath: "assets/images/hero_6.jpg",
      label: "Business Ready",
    ),
    LocalImageItem(
      assetPath: "assets/images/hero_7.jpg",
      label: "Studio Perfection",
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
      if (_currentPage < _items.length - 1) {
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
          itemCount: _items.length,
          itemBuilder: (context, index) {
            return _buildCarouselItem(_items[index]);
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

  Widget _buildCarouselItem(LocalImageItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          item.assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.white54),
            ),
          ),
        ),

        // Optional Label at bottom right
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.matteGold,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
