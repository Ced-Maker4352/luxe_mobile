import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/gemini_service.dart';
import '../models/types.dart';
import '../shared/constants.dart';
import 'asset_editor_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class StudioDashboardScreen extends StatefulWidget {
  const StudioDashboardScreen({super.key});

  @override
  State<StudioDashboardScreen> createState() => _StudioDashboardScreenState();
}

class _StudioDashboardScreenState extends State<StudioDashboardScreen> {
  final GeminiService _gemini = GeminiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionProvider>();

      // Auto-select first available rig if none selected
      if (session.selectedRig == null && cameraRigs.isNotEmpty) {
        session.selectRig(cameraRigs.first);
      }

      if (session.results.isEmpty && !session.isGenerating) {
        _generateInitialPortrait(session);
      }
    });
  }

  Future<void> _generateInitialPortrait(SessionProvider session) async {
    // Check if we have image bytes (works on web and mobile)
    if (!session.hasUploadedImage || session.selectedPackage == null) {
      debugPrint('Studio: Missing image bytes or package');
      return;
    }

    // Auto-select first rig if still none
    if (session.selectedRig == null && cameraRigs.isNotEmpty) {
      session.selectRig(cameraRigs.first);
    }

    if (session.selectedRig == null) {
      debugPrint('Studio: No camera rig available');
      return;
    }

    session.setGenerating(true);
    try {
      // Use bytes directly - no File() needed, works on web!
      final base64Image = base64Encode(session.uploadedImageBytes!);

      final resultUrl = await _gemini.generatePortrait(
        referenceImageBase64: base64Image,
        basePrompt: session.selectedPackage!.basePrompt,
        opticProtocol: session.selectedRig!.opticProtocol,
      );

      session.addResult(
        GenerationResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imageUrl: resultUrl.isNotEmpty
              ? resultUrl
              : 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=1000',
          mediaType: 'image',
          packageType: session.selectedPackage!.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      debugPrint("Generation failed: $e");
    } finally {
      session.setGenerating(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'STUDIO DASHBOARD',
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: () =>
                _generateInitialPortrait(context.read<SessionProvider>()),
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.isGenerating && session.results.isEmpty) {
            return _buildLoadingState();
          }

          if (session.results.isEmpty) {
            return const Center(
              child: Text(
                'No results yet.',
                style: TextStyle(color: Colors.white24),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: session.results.length,
            itemBuilder: (context, index) {
              final result = session.results[index];
              return _buildResultCard(result);
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFD4AF37)),
          const SizedBox(height: 30),
          const Text(
            'INITIATING OPTIC PROTOCOL...',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Developing high-fidelity asset...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(GenerationResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              result.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 400,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.auto_fix_high, 'RETOUCH', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AssetEditorScreen(result: result),
                    ),
                  );
                }),
                _buildActionButton(
                  Icons.local_printshop,
                  'PRINT',
                  () => _showPrintLab(context),
                ),
                _buildActionButton(Icons.download, 'DOWNLOAD', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintLab(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'LUXE PRINT LAB',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Museum-grade physical assets.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: printProducts.length,
                itemBuilder: (context, index) {
                  final product = printProducts[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${product.material} • FROM \$${product.price.toInt()}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFFD4AF37),
                      size: 14,
                    ),
                    onTap: () async {
                      if (product.partnerUrl != null) {
                        final uri = Uri.parse(product.partnerUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.grid_view_rounded, 'GALLERY'),
          _buildNavIcon(Icons.layers_outlined, 'PORTFOLIO'),
          _buildNavIcon(Icons.shopping_bag_outlined, 'BOUTIQUE'),
          _buildNavIcon(Icons.person_outline, 'LOGIN'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white30, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
