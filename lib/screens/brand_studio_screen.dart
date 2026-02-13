import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../shared/web_helper.dart'
    if (dart.library.html) '../shared/web_helper_web.dart';
import '../providers/session_provider.dart';
import '../services/gemini_service.dart';
import '../shared/constants.dart';

class BrandStudioScreen extends StatefulWidget {
  const BrandStudioScreen({super.key});

  @override
  State<BrandStudioScreen> createState() => _BrandStudioScreenState();
}

class _BrandStudioScreenState extends State<BrandStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Strategy State
  Map<String, dynamic>? _brandStrategy;
  bool _isLoadingStrategy = false;

  // Logo State
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _logoStyleController = TextEditingController();
  String? _vectorLogoImage; // Simulation or same image
  bool _isGeneratingLogo = false;

  // Assets State (Simple list of last generated)
  final List<String> _logoHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _brandNameController.dispose();
    _logoStyleController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> _generateStrategy() async {
    final session = context.read<SessionProvider>();
    if (!session.hasUploadedImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload a portrait in Studio first.')),
      );
      return;
    }

    setState(() => _isLoadingStrategy = true);
    try {
      final service = GeminiService();
      final base64Image = base64Encode(session.uploadedImageBytes!);
      final strategy = await service.generateBrandStrategy(base64Image);
      setState(() {
        _brandStrategy = strategy;
      });
      // Pre-fill logo prompt
      if (strategy.containsKey('aesthetic')) {
        _logoStyleController.text = strategy['aesthetic'];
      }
      if (strategy.containsKey('slogan')) {
        // Maybe use slogan?
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Strategy failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingStrategy = false);
    }
  }

  Future<void> _generateLogo() async {
    if (_logoStyleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please describe the logo style.')),
      );
      return;
    }

    // Check credits? (Optional, implementing free for now as restoration)

    setState(() => _isGeneratingLogo = true);
    try {
      final service = GeminiService();
      final logo = await service.generateBrandLogo(
        _logoStyleController.text,
        _brandNameController.text,
      );

      if (logo.startsWith('Error')) throw Exception(logo);

      setState(() {
        _logoHistory.insert(0, logo);
        _tabController.animateTo(2); // Go to Assets/Result
      });

      // Auto-generate Clearback version
      _generateClearback(logo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logo generation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingLogo = false);
    }
  }

  Future<void> _generateClearback(String logoImage) async {
    try {
      final service = GeminiService();
      final clearback = await service.removeBackgroundForLogo(logoImage);
      if (!clearback.startsWith('Error')) {
        setState(() {
          _vectorLogoImage = clearback;
          // In a real app we might store this associated with the original
          // For now, adding to history if distinct
          _logoHistory.insert(0, clearback);
        });
      }
    } catch (e) {
      debugPrint("Clearback failed: $e");
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      final bytes = base64Decode(imageUrl.split(',')[1]);
      if (kIsWeb) {
        WebHelper.downloadImage(
          bytes,
          "luxe_logo_${DateTime.now().millisecondsSinceEpoch}.png",
        );
      } else {
        bool hasPermission = false;
        if (Platform.isAndroid) {
          hasPermission =
              await Permission.photos.request().isGranted ||
              await Permission.storage.request().isGranted;
        } else {
          hasPermission = await Permission.photos.request().isGranted;
        }

        if (hasPermission) {
          final result = await ImageGallerySaver.saveImage(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved to Gallery: $result')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Storage permission denied.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UI BUILDERS
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BRAND STUDIO',
          style: AppTypography.microBold(
            color: Colors.white,
          ).copyWith(letterSpacing: 3, fontSize: 14),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.matteGold,
          labelColor: AppColors.matteGold,
          unselectedLabelColor: Colors.white38,
          labelStyle: AppTypography.microBold(),
          tabs: [
            Tab(text: 'STRATEGY'),
            Tab(text: 'LOGO LAB'),
            Tab(text: 'ASSETS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStrategyTab(), _buildLogoTab(), _buildAssetsTab()],
      ),
    );
  }

  Widget _buildStrategyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'IDENTITY ARCHITECT',
            style: AppTypography.h3Display(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered brand analysis based on your portrait style.',
            style: AppTypography.micro(color: Colors.white54),
          ),
          const SizedBox(height: 24),

          if (_isLoadingStrategy)
            const Center(
              child: SizedBox(
                width: 120,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.matteGold,
                  ),
                ),
              ),
            )
          else if (_brandStrategy != null) ...[
            _buildInfoCard('AESTHETIC', _brandStrategy!['aesthetic']),
            const SizedBox(height: 12),
            _buildInfoCard('SLOGAN', _brandStrategy!['slogan']),
            const SizedBox(height: 12),
            _buildColorsPreview(_brandStrategy!['colors']),
            const SizedBox(height: 12),
            _buildInfoCard(
              'FONTS',
              "Primary: ${_brandStrategy!['fonts']['primary']}\nSecondary: ${_brandStrategy!['fonts']['secondary']}",
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.psychology, color: Colors.white24, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Analyze your vibe',
                    style: AppTypography.small(color: Colors.white54),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
          PremiumButton(
            onPressed: _isLoadingStrategy ? null : _generateStrategy,
            isLoading: _isLoadingStrategy,
            child: Text('GENERATE BRAND STRATEGY'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LOGO CREATION',
            style: AppTypography.h3Display(color: Colors.white),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _brandNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'BRAND NAME',
              labelStyle: AppTypography.microBold(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.matteGold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _logoStyleController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'VISUAL STYLE / PROMPT',
              hintText:
                  'e.g. Minimalist monogram, intertwining letters, gold foil texture...',
              hintStyle: AppTypography.micro(color: Colors.white12),
              labelStyle: AppTypography.microBold(color: Colors.white54),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.matteGold),
              ),
            ),
          ),

          const SizedBox(height: 32),
          if (_isGeneratingLogo)
            const Center(
              child: SizedBox(
                width: 120,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.matteGold,
                  ),
                ),
              ),
            )
          else
            PremiumButton(
              onPressed: _isGeneratingLogo ? null : _generateLogo,
              isLoading: _isGeneratingLogo,
              child: Text('CREATE LOGO'),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetsTab() {
    if (_logoHistory.isEmpty) {
      return Center(
        child: Text(
          'No assets yet.\nCreate a logo to get started.',
          textAlign: TextAlign.center,
          style: AppTypography.small(color: Colors.white38),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _logoHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final image = _logoHistory[index];
        final isVectorLike =
            image == _vectorLogoImage; // Identify clearback vs original

        // Detect if it is clearback by assuming odd index or matching reference
        // A simple heuristic:
        final label = isVectorLike ? 'VECTOR / CLEARBACK' : 'ORIGINAL CONCEPTS';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ASSET ${index + 1} • $label',
              style: AppTypography.micro(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, // White bg to see logo clearly
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(image.split(',')[1])),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.download, size: 16),
                    label: Text('PNG (HD)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: AppTypography.microBold(color: Colors.white),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    onPressed: () => _downloadImage(image),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.code, size: 16),
                    label: Text('VECTOR (SVG)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.matteGold,
                      textStyle: AppTypography.microBold(
                        color: AppColors.matteGold,
                      ),
                      side: const BorderSide(color: AppColors.matteGold),
                    ),
                    onPressed: () {
                      // Simulate vector download (user explicit request)
                      // For now downloading PNG but naming it vector-like/high-res
                      _downloadImage(image);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Vector format simulated (Hi-Res PNG saved). True SVG conversion requires external tool.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.microBold(color: AppColors.matteGold),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.bodyMedium(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildColorsPreview(List<dynamic> colors) {
    return SizedBox(
      height: 60,
      child: Row(
        children: colors.map<Widget>((c) {
          final color = _parseColor(c.toString());
          return Expanded(child: Container(color: color));
        }).toList(),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
