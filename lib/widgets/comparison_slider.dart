import 'package:flutter/material.dart';

class ComparisonSlider extends StatefulWidget {
  final ImageProvider beforeImage;
  final ImageProvider afterImage;
  final double height;

  const ComparisonSlider({
    Key? key,
    required this.beforeImage,
    required this.afterImage,
    this.height = 400,
  }) : super(key: key);

  @override
  State<ComparisonSlider> createState() => _ComparisonSliderState();
}

class _ComparisonSliderState extends State<ComparisonSlider> {
  double _splitX = 0.5; // Percentage (0.0 to 1.0)

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // If unbounded, force height. If bounded by parent (Expanded), use max.
        final height = constraints.maxHeight != double.infinity
            ? constraints.maxHeight
            : widget.height;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _splitX += details.delta.dx / width;
              _splitX = _splitX.clamp(
                0.001,
                0.999,
              ); // Prevent full collapse glitch
            });
          },
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                // Layer 1: After Image (Full Background, visible on right)
                Positioned.fill(
                  child: Image(image: widget.afterImage, fit: BoxFit.cover),
                ),

                // Layer 2: Before Image (Clipped, visible on left)
                ClipRect(
                  clipper: _SplitClipper(_splitX),
                  child: Image(
                    image: widget.beforeImage,
                    fit: BoxFit.cover,
                    width: width,
                    height: height,
                  ),
                ),

                // Divider Line
                Positioned(
                  left: (width * _splitX) - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Handle Circle
                Positioned(
                  left: (width * _splitX) - 16,
                  top: (height / 2) - 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.compare_arrows,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Labels
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _splitX > 0.15 ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'ORIGINAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _splitX < 0.85 ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'GENERATED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double percentage;

  _SplitClipper(this.percentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * percentage, size.height);
  }

  @override
  bool shouldReclip(_SplitClipper oldClipper) =>
      oldClipper.percentage != percentage;
}
