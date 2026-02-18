import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../shared/constants.dart';

class LogoLabDrawer extends StatefulWidget {
  const LogoLabDrawer({super.key});

  @override
  State<LogoLabDrawer> createState() => _LogoLabDrawerState();
}

class _LogoLabDrawerState extends State<LogoLabDrawer> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedStyle = 'Minimalist';
  bool _isGenerating = false;
  String? _logoUrl;
  String? _error;

  final List<Map<String, String>> _styles = [
    {'name': 'Minimalist', 'icon': 'simple_line'},
    {'name': 'Monogram', 'icon': 'letters'},
    {'name': 'Royal Crest', 'icon': 'shield'},
    {'name': 'Modern Serif', 'icon': 'type'},
    {'name': 'Geometric', 'icon': 'shapes'},
  ];

  Future<void> _generateLogo() async {
    if (_nameController.text.isEmpty) {
      setState(() => _error = 'Please enter a brand name');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final result = await GeminiService().generateBrandLogo(
        _nameController.text,
        _selectedStyle,
      );

      if (mounted) {
        setState(() {
          _logoUrl = result;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Logo generation failed. Please try again.';
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.midnightNavy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          if (_logoUrl == null) _buildGeneratorForm() else _buildResultView(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOGO LABORATORY™',
              style: AppTypography.microBold(color: AppColors.matteGold),
            ),
            const SizedBox(height: 4),
            const Text(
              'LUXURY BRAND ASSETS',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white38),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildGeneratorForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BRAND NAME',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. VALENTINO',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppColors.softPlatinum.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.softPlatinum.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'VISUAL STYLE',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _styles.map((style) {
            final isSelected = _selectedStyle == style['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedStyle = style['name']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.matteGold.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.matteGold
                        : AppColors.softPlatinum.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  style['name']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.matteGold : Colors.white60,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: PremiumButton(
            onPressed: _isGenerating ? null : _generateLogo,
            isLoading: _isGenerating,
            child: const Text('GENERATE ASSET'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.softPlatinum.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Image.network(
              _logoUrl!,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator(
                  color: AppColors.matteGold,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'ASSET TYPE: VECTOR MONOGRAM',
          style: TextStyle(
            color: AppColors.mutedGray,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _logoUrl = null),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.matteGold),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'RE-TOOL',
                  style: TextStyle(color: AppColors.matteGold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logo Saved to Vault')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('SAVE TO VAULT'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
