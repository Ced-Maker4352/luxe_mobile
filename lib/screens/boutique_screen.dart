import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../models/types.dart';
import '../services/stripe_service.dart';
import '../providers/session_provider.dart';
import 'access_granted_screen.dart';
import 'package:provider/provider.dart';

class BoutiqueScreen extends StatefulWidget {
  const BoutiqueScreen({super.key});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  String _selectedCategory = 'premium';
  bool _isProcessing = false;

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
      // Navigate to confirmation screen, then to upload page
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
      final success = await StripeService.handlePayment(
        pkg.id.name, // Convert enum to string like 'INDEPENDENT_ARTIST'
        email,
      );
      if (success && mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.selectPackage(pkg);
        // Navigate to confirmation screen, then to upload page
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
            content: Text('Payment failed: $e'),
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
    final filteredPackages = packages
        .where((p) => p.category == _selectedCategory)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'STUDIO BOUTIQUE',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 4,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Category Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryTab('PREMIUM', 'premium'),
                  const SizedBox(width: 20),
                  _buildCategoryTab('SNAPSHOT', 'snapshot'),
                ],
              ),
            ),
          ),

          // Package Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final pkg = filteredPackages[index];
                return _buildPackageCard(pkg);
              }, childCount: filteredPackages.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String label, String category) {
    final isActive = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFD4AF37) : Colors.white24,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 40,
            color: isActive ? const Color(0xFFD4AF37) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PackageDetails pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.network(
                pkg.exampleImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pkg.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      pkg.price,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pkg.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ...pkg.features
                    .take(3)
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check,
                              color: Color(0xFFD4AF37),
                              size: 14,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              f,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handlePackageSelection(pkg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'SELECT FOR COLLECTION',
                            style: TextStyle(letterSpacing: 2),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
