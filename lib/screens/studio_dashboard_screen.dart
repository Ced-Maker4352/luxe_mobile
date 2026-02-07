import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
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

class _StudioDashboardScreenState extends State<StudioDashboardScreen>
    with SingleTickerProviderStateMixin {
  // Scene settings
  BackgroundPreset? _selectedBackdrop;
  String _customPrompt = '';
  final TextEditingController _promptController = TextEditingController();

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
        _generatePortrait(session);
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generatePortrait(SessionProvider session) async {
    if (!session.hasUploadedImage || session.selectedPackage == null) {
      debugPrint('Studio: Missing image bytes or package');
      return;
    }

    if (session.selectedRig == null && cameraRigs.isNotEmpty) {
      session.selectRig(cameraRigs.first);
    }

    if (session.selectedRig == null) {
      debugPrint('Studio: No camera rig available');
      return;
    }

    session.setGenerating(true);
    try {
      // Preview mode: Use uploaded image with settings info
      final base64Image = base64Encode(session.uploadedImageBytes!);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      session.addResult(
        GenerationResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imageUrl: dataUrl,
          mediaType: 'image',
          packageType: session.selectedPackage!.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      debugPrint('Studio: Generated with rig: ${session.selectedRig!.name}');
    } catch (e) {
      debugPrint("Generation failed: $e");
    } finally {
      session.setGenerating(false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // POP-UP PANELS
  // ═══════════════════════════════════════════════════════════

  void _showCameraSelector() {
    final session = context.read<SessionProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            _buildSheetHandle(),
            const SizedBox(height: 20),
            const Text(
              'CAMERA RIG',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your virtual optic system',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cameraRigs.length,
                itemBuilder: (context, index) {
                  final rig = cameraRigs[index];
                  final isSelected = session.selectedRig?.id == rig.id;
                  return _buildCameraCard(rig, isSelected, () {
                    session.selectRig(rig);
                    Navigator.pop(context);
                    setState(() {});
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraCard(CameraRig rig, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37)
                : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(rig.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rig.name,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFD4AF37)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rig.specs.lens,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFD4AF37),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showBackdropSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            _buildSheetHandle(),
            const SizedBox(height: 20),
            const Text(
              'BACKDROP',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your scene environment',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: backgroundPresets.length,
                itemBuilder: (context, catIndex) {
                  final category = backgroundPresets[catIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          category.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: category.items.length,
                        itemBuilder: (context, index) {
                          final preset = category.items[index];
                          final isSelected = _selectedBackdrop?.id == preset.id;
                          return _buildBackdropTile(preset, isSelected);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdropTile(BackgroundPreset preset, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBackdrop = preset);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(preset.url, fit: BoxFit.cover),
              if (isSelected)
                Container(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPromptPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 20),
              const Text(
                'STYLE PROMPT',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Describe styling, clothing, or mood',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _promptController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'e.g., "Wearing a navy Armani suit, soft golden hour light"',
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Quick Presets
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickPreset('Business Formal'),
                  _buildQuickPreset('Casual Luxury'),
                  _buildQuickPreset('Dramatic Lighting'),
                  _buildQuickPreset('Studio Portrait'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _customPrompt = _promptController.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'APPLY PROMPT',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPreset(String label) {
    return GestureDetector(
      onTap: () {
        _promptController.text = label;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ),
    );
  }

  void _showPrintLab() {
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
            _buildSheetHandle(),
            const SizedBox(height: 24),
            const Text(
              'LUXE PRINT LAB',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Museum-grade physical assets',
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

  Widget _buildSheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MAIN BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(),
            // Floating Control Bar
            _buildControlBar(),
            // Main Content
            Expanded(
              child: Consumer<SessionProvider>(
                builder: (context, session, child) {
                  if (session.isGenerating && session.results.isEmpty) {
                    return _buildLoadingState();
                  }
                  if (session.results.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildResultsGrid(session);
                },
              ),
            ),
            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white54,
              size: 20,
            ),
          ),
          const Text(
            'STUDIO',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 4,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    final session = context.watch<SessionProvider>();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Camera Button
          _buildControlButton(
            icon: Icons.camera_outlined,
            label:
                session.selectedRig?.name.split('|').first.trim() ?? 'CAMERA',
            onTap: _showCameraSelector,
          ),
          _buildDivider(),
          // Backdrop Button
          _buildControlButton(
            icon: Icons.wallpaper_outlined,
            label: _selectedBackdrop?.name ?? 'BACKDROP',
            onTap: _showBackdropSelector,
          ),
          _buildDivider(),
          // Prompt Button
          _buildControlButton(
            icon: Icons.edit_note_outlined,
            label: _customPrompt.isEmpty ? 'PROMPT' : 'STYLED',
            onTap: _showPromptPanel,
          ),
          const SizedBox(width: 8),
          // Generate Button
          _buildGenerateButton(session),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFD4AF37), size: 22),
              const SizedBox(height: 4),
              Text(
                label.length > 10 ? '${label.substring(0, 10)}...' : label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildGenerateButton(SessionProvider session) {
    return GestureDetector(
      onTap: session.isGenerating ? null : () => _generatePortrait(session),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: session.isGenerating
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                ),
          color: session.isGenerating ? Colors.white12 : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: session.isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFD4AF37),
                ),
              )
            : const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),
          const Text('No assets yet', style: TextStyle(color: Colors.white24)),
          const SizedBox(height: 8),
          const Text(
            'Configure your scene and tap generate',
            style: TextStyle(color: Colors.white12, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(SessionProvider session) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: session.results.length,
      itemBuilder: (context, index) {
        final result = session.results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(GenerationResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: result.imageUrl.startsWith('data:')
                ? Image.memory(
                    base64Decode(result.imageUrl.split(',')[1]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 400,
                  )
                : Image.network(
                    result.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 400,
                  ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
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
                  _showPrintLab,
                ),
                _buildActionButton(Icons.download, 'DOWNLOAD', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download coming soon!')),
                  );
                }),
                _buildActionButton(Icons.share, 'SHARE', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon!')),
                  );
                }),
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
          Icon(icon, color: const Color(0xFFD4AF37), size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
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
          _buildNavIcon(Icons.grid_view_rounded, 'GALLERY', true, () {}),
          _buildNavIcon(Icons.layers_outlined, 'PORTFOLIO', false, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Portfolio coming soon!')),
            );
          }),
          _buildNavIcon(Icons.shopping_bag_outlined, 'BOUTIQUE', false, () {
            Navigator.pushNamed(context, '/boutique');
          }),
          _buildNavIcon(Icons.person_outline, 'PROFILE', false, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile coming soon!')),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFD4AF37) : Colors.white30,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFD4AF37) : Colors.white24,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
