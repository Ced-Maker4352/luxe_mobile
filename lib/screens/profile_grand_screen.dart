import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/constants.dart';
import '../widgets/app_drawer.dart';

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
        // Load profile data
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', _user!.id)
            .maybeSingle();

        // Load generation stats
        final generationsList = await _supabase
            .from('generations')
            .select('id')
            .eq('user_id', _user!.id);

        final stylesList = await _supabase
            .from('generations')
            .select('style')
            .eq('user_id', _user!.id);

        // Count distinct non-null styles
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

  /// Format subscription tier for display
  String _formatTier(String? tier) {
    if (tier == null || tier.isEmpty) return 'Free';
    // Map internal IDs to display names
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

  /// Format created_at to "Month Year"
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
    return Scaffold(
      backgroundColor: AppColors.softCharcoal,
      appBar: AppBar(
        backgroundColor: AppColors.midnightNavy,
        elevation: 0,
        title: Text(
          'PROFILE GRAND',
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
                      child: Icon(
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
                    const SizedBox(height: 40),
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
