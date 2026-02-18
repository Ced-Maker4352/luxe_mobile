import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/constants.dart';
import '../widgets/app_drawer.dart';
import 'boutique_screen.dart';

class ProfileGrandScreen extends StatefulWidget {
  const ProfileGrandScreen({super.key});

  @override
  State<ProfileGrandScreen> createState() => _ProfileGrandScreenState();
}

class _ProfileGrandScreenState extends State<ProfileGrandScreen> {
  final _supabase = Supabase.instance.client;
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  // Real stats from DB
  int _projectsCreated = 0;
  int _stylesExplored = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      _user = _supabase.auth.currentUser;
      if (_user != null) {
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', _user!.id)
            .maybeSingle();

        final generationsList = await _supabase
            .from('generations')
            .select('id')
            .eq('user_id', _user!.id);

        final stylesList = await _supabase
            .from('generations')
            .select('style')
            .eq('user_id', _user!.id);

        final distinctStyles = (stylesList as List<dynamic>)
            .map((g) => (g as Map<String, dynamic>)['style'] as String?)
            .where((s) => s != null && s.isNotEmpty)
            .toSet();

        setState(() {
          _profile = profileData;
          _projectsCreated = generationsList.length;
          _stylesExplored = distinctStyles.length;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatTier(String? tier) {
    if (tier == null || tier.isEmpty) return 'Free';
    const tierNames = {
      'socialQuick': 'Social Quick',
      'creatorPack': 'Creator Pack',
      'professionalShoot': 'Professional Shoot',
      'agencyMaster': 'Agency Master',
      'sub_monthly_19': 'Starter Monthly',
      'sub_monthly_49': 'Pro Monthly',
      'sub_monthly_99': 'Unlimited Monthly',
    };
    return tierNames[tier] ?? tier;
  }

  String _formatMemberSince(String? createdAt) {
    if (createdAt == null) return 'Recently';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return 'Recently';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final photoCredits = (_profile?['photo_generations'] as int?) ?? 0;
    final videoCredits = (_profile?['video_generations'] as int?) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.softCharcoal,
      appBar: AppBar(
        backgroundColor: AppColors.midnightNavy,
        elevation: 0,
        title: Text(
          'PROFILE',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: AppColors.matteGold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.matteGold),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.matteGold),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.matteGold.withValues(
                        alpha: 0.2,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.matteGold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _profile?['full_name'] ??
                          _user?.email?.split('@')[0] ??
                          'User',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user?.email ?? 'No email',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── CREDIT BALANCE CARD ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.matteGold.withValues(alpha: 0.15),
                            AppColors.midnightNavy,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.matteGold.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: AppColors.matteGold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CREDITS REMAINING',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: AppColors.matteGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCreditPill(
                                  icon: Icons.photo_camera,
                                  label: 'PHOTOS',
                                  count: photoCredits,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCreditPill(
                                  icon: Icons.videocam,
                                  label: 'VIDEOS',
                                  count: videoCredits,
                                ),
                              ),
                            ],
                          ),
                          if (photoCredits == 0 && videoCredits == 0) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BoutiqueScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                ),
                                label: const Text('BUY MORE CREDITS'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.matteGold,
                                  foregroundColor: Colors.black,
                                  textStyle: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    fontSize: 12,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildInfoCard(
                      'Account Type',
                      _formatTier(_profile?['subscription_tier'] as String?),
                      Icons.workspace_premium,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Member Since',
                      _formatMemberSince(_profile?['created_at'] as String?),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Projects Created',
                      '$_projectsCreated',
                      Icons.photo_library,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Styles Explored',
                      '$_stylesExplored',
                      Icons.palette,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () async {
                        await _supabase.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.matteGold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'SIGN OUT',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AppColors.softCharcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCreditPill({
    required IconData icon,
    required String label,
    required int count,
  }) {
    final isEmpty = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isEmpty
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEmpty
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isEmpty ? Colors.redAccent : AppColors.matteGold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isEmpty ? Colors.redAccent : Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.midnightNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.matteGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.matteGold, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
