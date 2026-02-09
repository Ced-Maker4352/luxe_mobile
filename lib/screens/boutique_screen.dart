import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to continue')),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Proceed with Stripe Payment using authenticated email
      final success = await StripeService.handlePayment(
        pkg.id.name,
        user.email!,
      );

      if (success && mounted) {
        // 1. Update Supabase Profile with subscription status
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'email': user.email,
            'is_subscribed': true,
            'subscription_tier': pkg.id.name,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (dbError) {
          debugPrint('Error updating profile: $dbError');
          // We continue granting access since payment succeeded
        }

        // 2. Grant Access
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

            // === SNAPSHOT OPTIONS SECTION (Centered Row) ===
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSnapshotCard(
                    title: "DAILY SNAPSHOT",
                    price: "\$0.99",
                    icon: Icons.camera_alt_outlined,
                    onTap: () {
                      final snapshotPackage = packages.firstWhere(
                        (p) => p.id == PortraitPackage.SNAPSHOT_DAILY,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleStyleSelectionScreen(
                            package: snapshotPackage,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildSnapshotCard(
                    title: "STYLE REFRESH",
                    price: "\$1.99",
                    icon: Icons.auto_awesome_outlined,
                    isPremium: true,
                    onTap: () {
                      final snapshotPackage = packages.firstWhere(
                        (p) => p.id == PortraitPackage.SNAPSHOT_STYLE,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleStyleSelectionScreen(
                            package: snapshotPackage,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildSnapshotCard(
                    title: "BUDGET TIERS",
                    price: "FROM \$3",
                    icon: Icons.savings_outlined,
                    onTap: _showBudgetTiersModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // === BOTTOM DETAILS SECTION ===
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF141824),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dynamic Image + Title Row
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _selectedPackage.exampleImage,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPackage.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedPackage.price,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Description
                      Text(
                        _selectedPackage.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Features
                      ..._selectedPackage.features
                          .take(2)
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFFD4AF37),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 16),
                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              _handlePackageSelection(_selectedPackage),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'SELECT COLLECTION',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildSnapshotCard({
    required String title,
    required String price,
    required IconData icon,
    bool isPremium = false,
    required VoidCallback onTap,
  }) {
    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPremium
                ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isPremium
                  ? const Color(0xFFD4AF37)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPremium ? const Color(0xFFD4AF37) : Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isPremium ? const Color(0xFFD4AF37) : Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                price,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isPremium ? const Color(0xFFD4AF37) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetTiersModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SELECT BUDGET TIER",
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 18,
                color: Color(0xFFD4AF37),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            ...budgetTiers.map(
              (tier) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tier.bestValue
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "\$${tier.amount}",
                    style: TextStyle(
                      color: tier.bestValue
                          ? const Color(0xFFD4AF37)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  tier.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  tier.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                trailing: tier.bestValue
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "BEST VALUE",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to payment for budget tier
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
