import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_service.dart';
import '../shared/constants.dart';

class IdentityLabDrawer extends StatefulWidget {
  final Uint8List imageBytes;
  final String? imageUrl;

  const IdentityLabDrawer({super.key, required this.imageBytes, this.imageUrl});

  @override
  State<IdentityLabDrawer> createState() => _IdentityLabDrawerState();
}

class _IdentityLabDrawerState extends State<IdentityLabDrawer> {
  bool _isAnalyzing = true;
  Map<String, dynamic>? _brandStrategy;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final base64Image = base64Encode(widget.imageBytes);
      final result = await GeminiService().generateBrandStrategy(base64Image);

      if (mounted) {
        setState(() {
          _brandStrategy = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to extract brand identity. Please try again.';
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightNavy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          Expanded(
            child: _isAnalyzing
                ? _buildLoadingState()
                : (_error != null ? _buildErrorState() : _buildContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.softPlatinum.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IDENTITY LAB™',
                style: AppTypography.microBold(color: AppColors.matteGold),
              ),
              const SizedBox(height: 4),
              Text(
                'BRAND EXTRACTION',
                style: AppTypography.small(color: AppColors.softPlatinum),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.softPlatinum),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.matteGold),
          const SizedBox(height: 24),
          Text(
            'ANALYZING VISUAL ASSETS...',
            style: AppTypography.microBold(color: AppColors.mutedGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Extracting color theory, fonts, and aesthetic narrative.',
            style: AppTypography.micro(color: AppColors.mutedGray),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            PremiumButton(
              onPressed: _analyzeImage,
              child: const Text('RETRY ANALYSIS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final colors = (_brandStrategy?['colors'] as List?)?.cast<String>() ?? [];
    final fonts = _brandStrategy?['fonts'] as Map<String, dynamic>? ?? {};
    final slogan =
        _brandStrategy?['slogan'] as String? ?? 'Defined By Excellence';
    final aesthetic =
        _brandStrategy?['aesthetic'] as String? ?? 'Luxury Minimalism';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PALETTE
          _buildSectionTitle('BRAND PALETTE'),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final hex = colors[index];
                final color = _parseHexColor(hex);
                return Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.softPlatinum.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hex.toUpperCase(),
                      style: AppTypography.micro(
                        color: AppColors.mutedGray,
                      ).copyWith(fontSize: 8),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // 2. TYPOGRAPHY
          _buildSectionTitle('TYPOGRAPHY PROTOCOL'),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Primary Display',
            fonts['primary'] ?? 'Playfair Display',
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Secondary Body', fonts['secondary'] ?? 'Inter'),

          const SizedBox(height: 32),

          // 3. BRAND VOICE
          _buildSectionTitle('BRAND VOICE'),
          const SizedBox(height: 16),
          _buildBrandCard('OFFICIAL SLOGAN', slogan, Icons.auto_awesome),
          const SizedBox(height: 12),
          _buildBrandCard('VISUAL AESTHETIC', aesthetic, Icons.remove_red_eye),

          const SizedBox(height: 48),

          // Action
          PremiumButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Identity Saved to Vault')),
              );
              Navigator.pop(context);
            },
            child: const Text('SAVE IDENTITY TO VAULT'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.microBold(
        color: AppColors.mutedGray,
      ).copyWith(letterSpacing: 2),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.microBold(color: Colors.white38),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.matteGold,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softPlatinum.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softPlatinum.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.matteGold),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.microBold(color: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.softPlatinum,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
