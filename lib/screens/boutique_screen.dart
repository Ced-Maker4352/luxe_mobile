import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../models/types.dart';
import '../services/stripe_service.dart';
import '../providers/session_provider.dart';
import 'access_granted_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/hero_carousel.dart';

class BoutiqueScreen extends StatefulWidget {
  const BoutiqueScreen({super.key});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  // Default to the first package
  late PackageDetails _selectedPackage;
  bool _isProcessing = false;
  final TextEditingController _promoController = TextEditingController();

  // 100% Discount / Admin Bypass Codes
  final List<String> _bypassCodes = [
    'LUXEFREE',
    'CCDN_APPS',
    'LUXE_ADMIN_FREE',
    'LUXE100',
  ];

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedPackage = packages.first;
  }

  Future<void> _handlePackageSelection(
    PackageDetails pkg, {
    String? tierId,
  }) async {
    // --- 1. UPGRADE TRIGGERS (AOV OPTIMIZATION) ---
    if (tierId == null) {
      if (pkg.id == PortraitPackage.socialQuick) {
        final upgrade = await _showUpgradeModal(
          title: "WAIT! UPGRADE & SAVE",
          content:
              "For just \$24 more, unlock 6x more images, commercial rights, and studio styles.",
          confirmText: "YES, UPGRADE TO CREATOR (\$29)",
          cancelText: "NO, I'LL STICK TO BASIC",
          savings: "BEST VALUE",
        );
        if (upgrade) {
          final creatorPkg = packages.firstWhere(
            (p) => p.id == PortraitPackage.creatorPack,
          );
          if (mounted) {
            setState(() => _selectedPackage = creatorPkg);
            _handlePackageSelection(creatorPkg);
          }
          return;
        }
      } else if (pkg.id == PortraitPackage.creatorPack) {
        final upgrade = await _showUpgradeModal(
          title: "UNLOCK PROFESSIONAL STUDIO",
          content:
              "Upgrade to Professional for 4K exports, cinematic lighting, and 80 high-res photos.",
          confirmText: "VIEW PROFESSIONAL SHOOT (\$99)",
          cancelText: "CONTINUE WITH CREATOR",
          savings: "MOST POPULAR",
        );
        if (upgrade) {
          final proPkg = packages.firstWhere(
            (p) => p.id == PortraitPackage.professionalShoot,
          );
          if (mounted) {
            setState(() => _selectedPackage = proPkg);
            _handlePackageSelection(proPkg);
          }
          return;
        }
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to continue')),
        );
      }
      return;
    }

    final promoCode = _promoController.text.trim().toUpperCase();
    final paymentTargetId = tierId ?? pkg.id.name;

    setState(() => _isProcessing = true);

    // --- PROMO BYPASS LOGIC ---
    if (_bypassCodes.contains(promoCode)) {
      debugPrint('Stripe: Bypass code detected: \$promoCode. Granting access.');
      // 1. Update Supabase Profile (Bypass)
      try {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'email': user.email,
          'is_subscribed': true,
          'subscription_tier': paymentTargetId,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (dbError) {
        debugPrint('Error updating profile: \$dbError');
      }

      // 2. Grant Access Directly
      if (mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.setSelectedPackage(pkg);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AccessGrantedScreen(package: pkg, isPromoCode: true),
          ),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    if (kIsWeb) {
      final link = StripeService.getPaymentLink(
        paymentTargetId,
        promoCode: promoCode,
      );
      if (link != null) {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          // Show confirmation dialog for web flow
          if (mounted) {
            final confirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.softCharcoal,
                title: const Text(
                  'Complete Payment',
                  style: TextStyle(color: AppColors.matteGold),
                ),
                content: const Text(
                  'Please complete the payment in the new tab.\n\nOnce done, click "I Have Paid" to continue.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false), // Cancel
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true), // Confirm
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.matteGold,
                    ),
                    child: const Text(
                      'I Have Paid',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              // Proceed as if payment succeeded
              // 1. Update Supabase Profile
              try {
                await Supabase.instance.client.from('profiles').upsert({
                  'id': user.id,
                  'email': user.email,
                  'is_subscribed': true,
                  'subscription_tier': paymentTargetId,
                  'updated_at': DateTime.now().toIso8601String(),
                });
              } catch (dbError) {
                debugPrint('Error updating profile: \$dbError');
              }

              // 2. Grant Access
              if (mounted) {
                final session = Provider.of<SessionProvider>(
                  context,
                  listen: false,
                );
                session.setSelectedPackage(pkg);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AccessGrantedScreen(package: pkg, isPromoCode: false),
                  ),
                );
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch payment link')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment link not configured for this package'),
          ),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // Proceed with Stripe Payment using authenticated email
      final success = await StripeService.handlePayment(
        paymentTargetId,
        user.email!,
        promoCode: promoCode,
      );

      if (success && mounted) {
        // 1. Update Supabase Profile with subscription status
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'email': user.email,
            'is_subscribed': true,
            'subscription_tier': paymentTargetId,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (dbError) {
          debugPrint('Error updating profile: \$dbError');
          // We continue granting access since payment succeeded
        }

        // 2. Grant Access
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.setSelectedPackage(pkg);
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
    final session = context.watch<SessionProvider>();
    final isEnterprise = session.isEnterpriseMode;

    return Scaffold(
      backgroundColor: isEnterprise
          ? AppColors.enterpriseNavy
          : AppColors.midnightNavy,
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
                  Consumer<SessionProvider>(
                    builder: (context, session, child) {
                      final isEnterprise = session.isEnterpriseMode;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "LUXE AI STUDIO",
                              textAlign: TextAlign.center,
                              style:
                                  AppTypography.h2Display(
                                    color: isEnterprise
                                        ? AppColors.enterpriseGold
                                        : AppColors.matteGold,
                                  ).copyWith(
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black,
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isEnterprise
                                  ? "Production-Ready Visual Systems for Modern Teams"
                                  : "Your Vision. Professionally Realized.",
                              textAlign: TextAlign.center,
                              style:
                                  AppTypography.h3Display(
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ).copyWith(
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 4.0,
                                        color: Colors.black,
                                        offset: Offset(1.0, 1.0),
                                      ),
                                    ],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isEnterprise
                                  ? "Generate cohesive executive headshots, campaign imagery, and brand-consistent visuals — without scheduling studios or coordinating shoots."
                                  : "Upload once. Create unlimited campaigns.\nFrom social content to executive portraits.",
                              textAlign: TextAlign.center,
                              style:
                                  AppTypography.small(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ).copyWith(
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
                      );
                    },
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
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: packages.length,

                  itemBuilder: (context, index) {
                    final pkg = packages[index];
                    final isSelected = pkg.id == _selectedPackage.id;
                    final isPro = pkg.id == PortraitPackage.professionalShoot;

                    // AOV Highlight: Pro tier gets subtle glow and badge
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPackage = pkg),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: AppMotion.micro,
                            curve: AppMotion.cinematic,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.matteGold.withValues(alpha: 0.15)
                                  : (isPro
                                        ? AppColors.matteGold.withValues(
                                            alpha: 0.05,
                                          )
                                        : Colors.transparent),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.matteGold
                                    : (isPro
                                          ? AppColors.matteGold.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.matteGold.withValues(
                                              alpha: 0.1,
                                            )),
                                width: isSelected ? 2.0 : (isPro ? 1.5 : 0.5),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isPro && isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.matteGold.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(12),
                            child: AnimatedScale(
                              scale: isSelected ? 1.02 : 1.0,
                              duration: AppMotion.micro,
                              curve: AppMotion.cinematic,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getPackageIcon(pkg.id),
                                    color: isSelected
                                        ? AppColors.matteGold
                                        : (isPro
                                              ? AppColors.matteGold
                                              : Colors.white54),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    pkg.name.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: AppTypography.microBold(
                                      color: isSelected
                                          ? AppColors.matteGold
                                          : Colors.white70,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pkg.price,
                                    style: AppTypography.bodyMedium(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // MOST POPULAR BADGE
                          if (isPro)
                            Positioned(
                              top: -10,
                              right: 0,
                              left: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.matteGold,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    isEnterprise
                                        ? "PROFESSIONAL PRODUCTION"
                                        : "MOST POPULAR",
                                    style: AppTypography.microBold(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // === SUBSCRIPTION SECTION ===
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    isEnterprise ? "PRODUCTION TIERS" : "STUDIO PACKAGES",
                    style: AppTypography.microBold(color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSubscriptionButton(
                        "STARTER",
                        "\$19/mo",
                        "sub_monthly_19",
                      ),
                      const SizedBox(width: 8),
                      _buildSubscriptionButton(
                        "PRO",
                        "\$49/mo",
                        "sub_monthly_49",
                      ),
                      const SizedBox(width: 8),
                      _buildSubscriptionButton(
                        "UNLIMITED",
                        "\$99/mo",
                        "sub_monthly_99",
                      ),
                    ],
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  color: AppColors.softCharcoal,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dynamic Image + Title Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.matteGold.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _selectedPackage.exampleImage,
                                width: 80,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPackage.name.toUpperCase(),
                                  style: AppTypography.h3Display(
                                    color: AppColors.matteGold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '\$',
                                        style: AppTypography.priceDisplay()
                                            .copyWith(fontSize: 16),
                                      ),
                                      TextSpan(
                                        text: _selectedPackage.price.replaceAll(
                                          '\$',
                                          '',
                                        ),
                                        style: AppTypography.priceDisplay()
                                            .copyWith(fontSize: 32),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedPackage.description,
                                  style: AppTypography.small(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Features
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedPackage.features.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check,
                                  color: AppColors.matteGold,
                                  size: 12,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  f,
                                  style: AppTypography.smallSemiBold(
                                    color: Colors.white70,
                                  ).copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // Missing Features (AOV - Loss Aversion)
                      if (_selectedPackage.id != PortraitPackage.agencyMaster &&
                          _selectedPackage.id !=
                              PortraitPackage.professionalShoot) ...[
                        const SizedBox(height: 12),
                        Text(
                          "MISSING IN THIS TIER:",
                          style: AppTypography.microBold(color: Colors.white24),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                if (_selectedPackage.id ==
                                        PortraitPackage.socialQuick ||
                                    _selectedPackage.id ==
                                        PortraitPackage.creatorPack)
                                  "4K Export (Pro Only)",
                                if (_selectedPackage.id ==
                                        PortraitPackage.socialQuick ||
                                    _selectedPackage.id ==
                                        PortraitPackage.creatorPack)
                                  "Studio Lighting (Pro Only)",
                                if (_selectedPackage.id !=
                                    PortraitPackage.agencyMaster)
                                  "Group Mode (Agency Only)",
                              ].map((f) {
                                return Text(
                                  "• $f",
                                  style: AppTypography.micro(
                                    color: Colors.white24,
                                  ),
                                );
                              }).toList(),
                        ),
                      ],

                      // Price Anchoring Text
                      if (_selectedPackage.id ==
                          PortraitPackage.professionalShoot) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.matteGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.matteGold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.matteGold,
                                size: 14,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Standard studio session value: \$500–\$1,200",
                                  style: AppTypography.smallSemiBold(
                                    color: AppColors.matteGold,
                                  ).copyWith(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_selectedPackage.id ==
                          PortraitPackage.agencyMaster) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Equivalent to a multi-day studio production (\$5,000+ value)",
                          style: AppTypography.small(
                            color: Colors.white54,
                          ).copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: PremiumButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _handlePackageSelection(_selectedPackage),
                          isLoading: _isProcessing,
                          child: Text(
                            _selectedPackage.buttonLabel.toUpperCase(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Micro-copy Reassurance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isEnterprise
                                ? "No physical coordination. Scalable results. Brand compliant."
                                : "No photographer. No studio rental. No reshoots.",
                            style: AppTypography.micro(color: Colors.white30),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "SECURE PAYMENT VIA STRIPE",
                          style: AppTypography.micro(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      if (isEnterprise) ...[
                        const SizedBox(height: 32),
                        _buildEnterpriseUseGrid(),
                        const SizedBox(height: 32),
                        _buildTrustSignals(),
                      ],

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Hidden Toggle for Demo (Double tap footer or small button)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.small(
          onPressed: () => session.setEnterpriseMode(!isEnterprise),
          backgroundColor: Colors.white10,
          child: Icon(
            isEnterprise ? Icons.business : Icons.person,
            color: Colors.white24,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEnterpriseUseGrid() {
    final uses = [
      ("Executive Headshots", Icons.person_outline),
      ("Corporate Directories", Icons.list_alt),
      ("Music Group Campaigns", Icons.groups_3_outlined),
      ("Agency Production", Icons.campaign_outlined),
      ("Real Estate Teams", Icons.home_work_outlined),
      ("Brand Ambassador", Icons.stars_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BUILT FOR TEAMS",
          style: AppTypography.microBold(color: AppColors.matteGold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: uses.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(uses[index].$2, color: AppColors.softPlatinum, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    uses[index].$1,
                    textAlign: TextAlign.center,
                    style: AppTypography.small(
                      color: AppColors.coolGray,
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrustSignals() {
    final signals = [
      "Commercial Usage Included",
      "Secure Cloud Processing",
      "Scalable Batch Output",
      "Brand Compliance Ready",
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: signals.map((s) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.softPlatinum,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  s,
                  style: AppTypography.small(
                    color: AppColors.coolGray,
                  ).copyWith(fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubscriptionButton(String label, String price, String tierId) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handlePackageSelection(_selectedPackage, tierId: tierId),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.cinematic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.microBold(color: Colors.white70),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: AppTypography.smallSemiBold(
                  color: AppColors.matteGold,
                ).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPackageIcon(PortraitPackage id) {
    switch (id) {
      case PortraitPackage.socialQuick:
        return Icons.rocket_launch_outlined;
      case PortraitPackage.creatorPack:
        return Icons.camera_enhance_outlined;
      case PortraitPackage.professionalShoot:
        return Icons.business_center_outlined;
      case PortraitPackage.agencyMaster:
        return Icons.diamond_outlined;
      default:
        return Icons.star_outline;
    }
  }

  Future<bool> _showUpgradeModal({
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
    required String savings,
  }) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: AppColors.softCharcoal,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AppMotion.standard,
            curve: AppMotion.cinematic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, AppMotion.modalRise * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.matteGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        savings,
                        style: AppTypography.microBold(
                          color: Colors.black,
                        ).copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.h3Display(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular(
                      color: Colors.white70,
                    ).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  PremiumButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmText),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      cancelText,
                      style: AppTypography.small(color: Colors.white30),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }
}
