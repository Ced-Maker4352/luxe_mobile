import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/types.dart';
import '../shared/constants.dart';
import '../services/gemini_service.dart';
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

  // NEW: Missing web features
  SkinTexture _selectedSkinTexture = skinTextures[1]; // Default to 'Soft'
  String _bgMode = 'presets'; // 'package', 'presets', 'upload', 'ai'
  String _customBgPrompt = '';
  final TextEditingController _bgPromptController = TextEditingController();
  bool _isEnhancingPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionProvider>();

      // Auto-select first available rig if none selected
      if (session.selectedRig == null && cameraRigs.isNotEmpty) {
        session.selectRig(cameraRigs.first);
      }

      // Auto-select first available package if none selected (Fix for missing generation)
      if (session.selectedPackage == null && packages.isNotEmpty) {
        session.selectPackage(packages.first);
      }

      if (session.results.isEmpty && !session.isGenerating) {
        _generatePortrait(session);
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _bgPromptController.dispose();
    super.dispose();
  }

  Future<void> _generatePortrait(SessionProvider session) async {
    if (!session.hasUploadedImage || session.selectedPackage == null) {
      if (!session.hasUploadedImage) debugPrint('Studio: Missing image bytes');
      if (session.selectedPackage == null)
        debugPrint('Studio: Missing package');
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
      debugPrint('Studio: Starting generation with Gemini...');
      final service = GeminiService();

      // Combine package prompt with user custom prompt
      final fullPrompt =
          '${session.selectedPackage!.basePrompt} $_customPrompt';

      final resultText = await service.generatePortrait(
        referenceImageBase64: base64Encode(session.uploadedImageBytes!),
        basePrompt: fullPrompt,
        opticProtocol: session.selectedRig!.promptAddition,
        backgroundImageBase64: null, // TODO: Handle background image if needed
        skinTexturePrompt: _selectedSkinTexture.prompt,
      );

      // Determine if result is an image or text fallback
      String imageUrl;
      if (resultText.startsWith('data:image') ||
          (resultText.length > 200 && !resultText.contains(' '))) {
        imageUrl = resultText.startsWith('data:')
            ? resultText
            : 'data:image/jpeg;base64,$resultText';
      } else {
        debugPrint(
          'Studio: API returned text (fallback to original): $resultText',
        );
        final base64Image = base64Encode(session.uploadedImageBytes!);
        imageUrl = 'data:image/jpeg;base64,$base64Image';
      }

      session.addResult(
        GenerationResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imageUrl: imageUrl,
          mediaType: 'image',
          packageType: session.selectedPackage!.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      debugPrint('Studio: Generated with rig: ${session.selectedRig!.name}');
      debugPrint('Studio: API Response length: ${resultText.length}');
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: cameraRigs.length,
                itemBuilder: (context, index) {
                  final rig = cameraRigs[index];
                  final isSelected = session.selectedRig?.id == rig.id;
                  return _buildCameraCard(rig, isSelected, () {
                    session.selectRig(rig);
                    Navigator.pop(context);
                  });
                },
              ),
            ),
            // Generate Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generatePortrait(session);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'GENERATE',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
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
                : Colors.white.withOpacity(0.05),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              _buildSheetHandle(),
              const SizedBox(height: 20),
              const Text(
                'SCENE ARCHITECTURE',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // Background Mode Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildModeTab('package', 'Package', setModalState),
                    const SizedBox(width: 8),
                    _buildModeTab('presets', 'Library', setModalState),
                    const SizedBox(width: 8),
                    _buildModeTab('upload', 'Upload', setModalState),
                    const SizedBox(width: 8),
                    _buildModeTab('ai', 'AI', setModalState),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Mode Content
              Expanded(
                child: _buildBgModeContent(scrollController, setModalState),
              ),
              // Generate Button (Bottom pinned)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Trigger generation immediately
                      _generatePortrait(context.read<SessionProvider>());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'GENERATE',
                          style: TextStyle(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, StateSetter setModalState) {
    final isActive = _bgMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() => _bgMode = mode);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? Colors.white : Colors.white24),
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBgModeContent(
    ScrollController controller,
    StateSetter setModalState,
  ) {
    switch (_bgMode) {
      case 'package':
        final session = context.read<SessionProvider>();
        final package = session.selectedPackage;
        // Package Details
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFFD4AF37),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                package?.name ?? 'Standard Package',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Includes ${package?.assetCount ?? 5} premium assets',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      package?.description ??
                          'Curated package environment optimized for this session type.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 20),
                    if (package?.features != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: package!.features
                            .map(
                              (feature) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  feature,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'presets':
        return ListView.builder(
          controller: controller,
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
        );
      case 'upload':
        // TODO: Implement image upload for custom backdrop
        return Center(
          child: GestureDetector(
            onTap: () {
              // Will add image picker integration
              Navigator.pop(context);
            },
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, color: Colors.white38, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Upload Custom Backdrop',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      case 'ai':
        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Prompt Input with Clear/Enhance buttons
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _bgPromptController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: "Describe your dream location...",
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        setModalState(() => _customBgPrompt = value);
                      },
                    ),
                    // Action Buttons Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Clear Button
                          if (_bgPromptController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _bgPromptController.clear();
                                setModalState(() => _customBgPrompt = '');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.withOpacity(0.7),
                                  size: 16,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          // Enhance Button
                          GestureDetector(
                            onTap: _isEnhancingPrompt
                                ? null
                                : () {
                                    // Simulated enhance - in real app would call AI
                                    setModalState(
                                      () => _isEnhancingPrompt = true,
                                    );
                                    Future.delayed(
                                      const Duration(seconds: 1),
                                      () {
                                        if (mounted) {
                                          final enhanced =
                                              "${_bgPromptController.text}, cinematic lighting, 8K detail";
                                          _bgPromptController.text = enhanced;
                                          setModalState(() {
                                            _customBgPrompt = enhanced;
                                            _isEnhancingPrompt = false;
                                          });
                                        }
                                      },
                                    );
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  _isEnhancingPrompt
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: Color(0xFFD4AF37),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.auto_fix_high,
                                          size: 12,
                                          color: Color(0xFFD4AF37),
                                        ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isEnhancingPrompt
                                        ? 'ENHANCING...'
                                        : 'ENHANCE',
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Prompt Categories
              ...promptCategories.entries.map(
                (entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4AF37),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.value
                          .map(
                            (prompt) => GestureDetector(
                              onTap: () {
                                final current = _bgPromptController.text;
                                _bgPromptController.text = current.isEmpty
                                    ? prompt
                                    : '$current $prompt';
                                setModalState(
                                  () => _customBgPrompt =
                                      _bgPromptController.text,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Text(
                                  prompt,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              // Curated Locations
              Row(
                children: [
                  const Icon(Icons.public, size: 12, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 8),
                  const Text(
                    'CURATED LOCATIONS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
                children: environmentPromptTips.entries
                    .expand(
                      (entry) => entry.value
                          .take(2)
                          .map(
                            (tip) => GestureDetector(
                              onTap: () {
                                _bgPromptController.text = tip;
                                setModalState(() => _customBgPrompt = tip);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      entry.key.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tip,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                    .toList()
                    .cast<Widget>(),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
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
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                const SizedBox(height: 16),

                // Skin Texture Selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: Color(0xFFD4AF37),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'SKIN FINISH',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _selectedSkinTexture.label,
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: skinTextures.map((texture) {
                            final isActive =
                                _selectedSkinTexture.id == texture.id;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(
                                    () => _selectedSkinTexture = texture,
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFD4AF37)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    texture.label.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.black
                                          : Colors.white38,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedSkinTexture.description,
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Prompt Input with Action Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _promptController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Describe styling, clothing, or mood...',
                          hintStyle: const TextStyle(
                            color: Colors.white24,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      // Action Bar (Clear, Mic, Enhance)
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Clear Button
                            if (_promptController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _promptController.clear();
                                  setModalState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            // Microphone Button (Visual Only for now)
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Voice input coming soon!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.mic_none,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                            // Enhance Button
                            GestureDetector(
                              onTap: _isEnhancingPrompt
                                  ? null
                                  : () {
                                      setModalState(
                                        () => _isEnhancingPrompt = true,
                                      );
                                      Future.delayed(
                                        const Duration(seconds: 1),
                                        () {
                                          if (mounted) {
                                            final enhanced =
                                                "${_promptController.text}, detailed, 8k resolution, cinematic lighting";
                                            _promptController.text = enhanced;
                                            setModalState(
                                              () => _isEnhancingPrompt = false,
                                            );
                                          }
                                        },
                                      );
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    if (_isEnhancingPrompt)
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Color(0xFFD4AF37),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.auto_fix_high,
                                        size: 12,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'ENHANCE',
                                      style: TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Presets
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickPreset('Business Formal', setModalState),
                    _buildQuickPreset('Casual Luxury', setModalState),
                    _buildQuickPreset('Dramatic Noir', setModalState),
                    _buildQuickPreset('Golden Hour', setModalState),
                  ],
                ),
                const SizedBox(height: 24),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _customPrompt = _promptController.text);
                      Navigator.pop(context);
                      // Trigger generation immediately
                      _generatePortrait(context.read<SessionProvider>());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'GENERATE',
                          style: TextStyle(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPreset(String label, StateSetter setModalState) {
    return GestureDetector(
      onTap: () {
        _promptController.text = label;
        setModalState(() {});
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
      color: Colors.white.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.3),
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
            color: Colors.white.withOpacity(0.1),
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
