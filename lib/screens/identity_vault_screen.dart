import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';

class IdentityVaultScreen extends StatefulWidget {
  const IdentityVaultScreen({super.key});

  @override
  State<IdentityVaultScreen> createState() => _IdentityVaultScreenState();
}

class _IdentityVaultScreenState extends State<IdentityVaultScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _identities = [];

  @override
  void initState() {
    super.initState();
    _fetchIdentities();
  }

  Future<void> _fetchIdentities() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetching from generations table where type is 'identity' or similar
      // Or we can just show all brand-related generations.
      final response = await _supabase
          .from('generations')
          .select()
          .eq('user_id', user.id)
          .or('style_name.ilike.%brand%,style_name.ilike.%identity%')
          .order('created_at', ascending: false);

      setState(() {
        _identities = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching vault: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'IDENTITY VAULT™',
          style: AppTypography.microBold(color: AppColors.matteGold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.softPlatinum),
            onPressed: _fetchIdentities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.matteGold),
            )
          : _identities.isEmpty
          ? _buildEmptyState()
          : _buildVaultGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 64,
            color: AppColors.softPlatinum.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'VAULT IS EMPTY',
            style: AppTypography.microBold(color: AppColors.softPlatinum),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save identities from the Lab to see them here.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _identities.length,
      itemBuilder: (context, index) {
        final item = _identities[index];
        return _buildVaultItem(item);
      },
    );
  }

  Widget _buildVaultItem(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softPlatinum.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                item['image_url'],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['style_name']?.toUpperCase() ?? 'BRAND IDENTITY',
                  style: AppTypography.microBold(
                    color: AppColors.matteGold,
                  ).copyWith(fontSize: 9),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item['created_at']),
                  style: const TextStyle(color: Colors.white38, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
