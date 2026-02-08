import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../models/types.dart';
import '../services/stripe_service.dart';
import '../providers/session_provider.dart';
import 'access_granted_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/hero_carousel.dart';
import 'single_style_selection_screen.dart';

class BoutiqueScreen extends StatefulWidget {
  const BoutiqueScreen({super.key});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  // Default to the first package
  late PackageDetails _selectedPackage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedPackage = packages.first;
  }

  Future<void> _handlePackageSelection(PackageDetails pkg) async {
    // Show promo code dialog
    final promoController = TextEditingController();
    final emailController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Enter Your Details',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: promoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Promo Code (Optional)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'email': emailController.text,
              'promo': promoController.text,
            }),
            child: const Text(
              'Continue',
              style: TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );

    if (result == null || result['email']?.isEmpty == true) return;

    final email = result['email']!;
    final promo = result['promo']?.toUpperCase() ?? '';

    // Check for bypass codes
    if (promo == 'LUXEFREE' || promo == 'CCDN_APPS') {
      if (!mounted) return;
      final session = Provider.of<SessionProvider>(context, listen: false);
      session.selectPackage(pkg);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AccessGrantedScreen(package: pkg, isPromoCode: true),
        ),
      );
      return;
    }

    // Proceed with Stripe Payment
    setState(() => _isProcessing = true);
    try {
      final success = await StripeService.handlePayment(pkg.id.name, email);
      if (success && mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.selectPackage(pkg);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AccessGrantedScreen(package: pkg, isPromoCode: false),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: \$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // === TOP HERO SECTION ===
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. CAROUSEL LAYER
                  const HeroCarousel(),

                  // 2. TEXT OVERLAY LAYER
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "LUXE AI STUDIO",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Serif',
                            color: Color(0xFFD4AF37),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "YOUR VISION, AMPLIFIED",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // === MIDDLE GRID SECTION ===
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), // No scrolling
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final pkg = packages[index];
                    final isSelected = pkg.id == _selectedPackage.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPackage = pkg),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getPackageIcon(pkg.id),
                              color: const Color(0xFFD4AF37),
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pkg.name
                                  .replaceAll("The ", "")
                                  .replaceAll("Package", "")
                                  .trim()
                                  .toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // === BOTTOM DETAILS SECTION ===
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF141824), // Dark blue/charcoal from mockup
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Image + Title Row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _selectedPackage.exampleImage,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPackage.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37), // Gold
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedPackage.price,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      _selectedPackage.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Features
                    ..._selectedPackage.features
                        .take(3)
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFFD4AF37),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  f,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    const Spacer(),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _handlePackageSelection(_selectedPackage),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFD4AF37,
                                ), // Gold bg
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'SELECT COLLECTION',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SingleStyleSelectionScreen(
                                          package: _selectedPackage,
                                        ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'TRY ONE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    _selectedPackage.payAsYouGoPrice,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFD4AF37),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPackageIcon(PortraitPackage id) {
    switch (id) {
      case PortraitPackage.INDEPENDENT_ARTIST:
        return Icons.person;
      case PortraitPackage.STUDIO_PRO:
        return Icons.camera_alt;
      case PortraitPackage.VISIONARY_CREATOR:
        return Icons.visibility;
      case PortraitPackage.MASTER_PACKAGE:
        return Icons.diamond;
      case PortraitPackage.DIGITAL_NOMAD:
        return Icons.laptop_mac;
      case PortraitPackage.CREATIVE_DIRECTOR:
        return Icons.movie_creation;
      default:
        return Icons.star;
    }
  }
}
