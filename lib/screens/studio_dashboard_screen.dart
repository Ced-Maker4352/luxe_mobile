import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/types.dart';
import '../shared/constants.dart';
import '../services/gemini_service.dart';

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
  String _customBgPrompt = '';
  final TextEditingController _bgPromptController = TextEditingController();

  // Adjustment sliders state
  double _brightness = 100;
  double _contrast = 100;
  double _saturation = 100;

  // NEW: Framing Options
  String _framingMode = 'portrait'; // 'portrait', 'full-body', 'head-to-toe'

  // V2 Split View State
  String _activeControl =
      'main'; // 'main', 'camera', 'backdrop', 'prompt', 'retouch', 'stitch', 'print', 'download', 'share'
  GenerationResult? _focusedResult;

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

      // Removed auto-generation to prevent wasting credits/resources.
      // User must explicitly click GENERATE.
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _bgPromptController.dispose();
    super.dispose();
  }

  Future<void> _generatePortrait(SessionProvider session) async {
    debugPrint('Studio: _generatePortrait called');
    debugPrint(
      'Studio: Session State -> hasUploadedImage: ${session.hasUploadedImage}, Package: ${session.selectedPackage?.name}',
    );

    if (!session.hasUploadedImage || session.selectedPackage == null) {
      if (!session.hasUploadedImage)
        debugPrint('Studio: FAILURE - Missing image bytes');
      if (session.selectedPackage == null)
        debugPrint('Studio: FAILURE - Missing package');

      // Auto-recover for testing if package is missing
      if (session.selectedPackage == null && packages.isNotEmpty) {
        debugPrint('Studio: Attempting auto-recovery for package...');
        session.selectPackage(packages.first);
        if (session.selectedPackage != null) {
          debugPrint(
            'Studio: Auto-recovery successful. Selected: ${session.selectedPackage!.name}',
          );
        }
      }

      if (!session.hasUploadedImage) return;
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
      debugPrint(
        '!!!!! Studio: Starting generation with Gemini (DEBUG V2) !!!!!',
      );
      final service = GeminiService();

      // Combine package prompt with user custom prompt or single style prompt
      String fullPrompt;
      final framingInstructions = {
        'portrait':
            'Maintain the current portrait framing (shoulders and above).',
        'full-body':
            'Generate a 3/4 body shot from head to approximately knee level. Show most of the outfit.',
        'head-to-toe':
            'Generate a COMPLETE head-to-toe full body shot. The entire person must be visible from the top of their head to their feet standing on the ground. Ensure shoes/feet are clearly visible at the bottom of the frame.',
      };

      String framingText = framingInstructions[_framingMode] ?? '';

      if (session.isSingleStyleMode && session.selectedStyle != null) {
        fullPrompt =
            '${session.selectedPackage!.basePrompt} ${session.selectedStyle!.promptAddition} $_customPrompt ${_customBgPrompt.isNotEmpty ? " Background: $_customBgPrompt" : ""} \nFRAMING: $framingText';
        debugPrint('Studio: Using Single Style Prompt: $fullPrompt');
      } else {
        fullPrompt =
            '${session.selectedPackage!.basePrompt} $_customPrompt ${_customBgPrompt.isNotEmpty ? " Background: $_customBgPrompt" : ""} \nFRAMING: $framingText';
      }

      // Append Adjustment Logic to Prompt
      fullPrompt +=
          """
      
      Adjustments:
      - Brightness: ${_brightness.toInt()}% (Normal=100%)
      - Contrast: ${_contrast.toInt()}% (Normal=100%)
      - Saturation: ${_saturation.toInt()}% (Normal=100%)
      - Skin Finish: ${_selectedSkinTexture.label}
      """;

      final resultText = await service.generatePortrait(
        referenceImageBase64: base64Encode(session.uploadedImageBytes!),
        basePrompt: fullPrompt,
        opticProtocol: session.selectedRig!.opticProtocol,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // Fallback: Add original image so screen isn't empty
      if (session.results.isEmpty) {
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
      }
    } finally {
      session.setGenerating(false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // V2 INLINE CONTROLS (Modal code removed)
  // ═══════════════════════════════════════════════════════════

  // (Legacy modal popup code removed — all replaced by V2 inline pickers)

  // ═══════════════════════════════════════════════════════════
  // MAIN BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _activeControl == 'main',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _activeControl = 'main';
            _focusedResult = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(),

              // 1. TOP: IMAGE AREA (Always Visible, Expanded)
              Expanded(
                flex: 6,
                child: Consumer<SessionProvider>(
                  builder: (context, session, child) {
                    if (session.isGenerating && session.results.isEmpty) {
                      return _buildLoadingState();
                    }
                    if (_focusedResult != null) {
                      return _buildEditorImageArea(_focusedResult!);
                    }
                    if (session.results.isNotEmpty) {
                      return _buildResultsViewer(session);
                    }
                    return _buildEmptyState();
                  },
                ),
              ),

              // 2. BOTTOM: CONTROL CENTER (Persistent 40%)
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF141414),
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: _buildControlCenter(),
                ),
              ),

              // 3. BOTTOM NAV (Persistent)
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsViewer(SessionProvider session) {
    // Show the most recent result or the one clicked
    final result = _focusedResult ?? session.results.last;

    // We can reuse _buildResultCard logic but stripped down to just image
    // Actually, let's use a standard image viewer
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: (result.imageUrl.startsWith('data:')
              ? Image.memory(
                  base64Decode(result.imageUrl.split(',')[1]),
                  fit: BoxFit.contain,
                )
              : Image.network(result.imageUrl, fit: BoxFit.contain)),
        ),
        // Floating "Back to Grid" or similar if needed?
        // For V2, let's assume we just swipe or use the bottom strip.
      ],
    );
  }

  Widget _buildEditorImageArea(GenerationResult result) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: (result.imageUrl.startsWith('data:')
              ? Image.memory(
                  base64Decode(result.imageUrl.split(',')[1]),
                  fit: BoxFit.contain,
                )
              : Image.network(result.imageUrl, fit: BoxFit.contain)),
        ),
      ],
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

  void _backToMain() {
    setState(() {
      _activeControl = 'main';
      _focusedResult = null;
    });
  }

  Widget _buildControlCenter() {
    switch (_activeControl) {
      case 'camera':
        return _buildCameraPicker();
      case 'backdrop':
        return _buildBackdropPicker();
      case 'prompt':
        return _buildPromptToInline();
      case 'retouch':
        return _buildDrawerWithHeader('RETOUCH LAB', _buildRetouchDrawer());
      case 'stitch':
        return _buildDrawerWithHeader('STITCH STUDIO', _buildStitchDrawer());
      case 'print':
        return _buildDrawerWithHeader('LUXE PRINT LAB', _buildPrintDrawer());
      case 'download':
        return _buildDrawerWithHeader('DOWNLOAD', _buildDownloadDrawer());
      case 'share':
        return _buildDrawerWithHeader('SHARE', _buildShareDrawer());
      default:
        return _buildMainToolbar();
    }
  }

  Widget _buildDrawerWithHeader(String title, Widget content) {
    return Column(
      children: [
        _buildPickerHeader(title, _backToMain),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildMainToolbar() {
    final session = context.watch<SessionProvider>();
    return Column(
      children: [
        // Control Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildControlButton(
                icon: Icons.camera_outlined,
                label:
                    session.selectedRig?.name.split('|').first.trim() ??
                    'CAMERA',
                onTap: () => setState(() => _activeControl = 'camera'),
              ),
              _buildDivider(),
              _buildControlButton(
                icon: Icons.wallpaper_outlined,
                label: _selectedBackdrop?.name ?? 'BACKDROP',
                onTap: () => setState(() => _activeControl = 'backdrop'),
              ),
              _buildDivider(),
              _buildControlButton(
                icon: Icons.edit_note_outlined,
                label: _customPrompt.isEmpty ? 'PROMPT' : 'STYLED',
                onTap: () => setState(() => _activeControl = 'prompt'),
              ),
              const SizedBox(width: 8),
              _buildGenerateButton(session),
            ],
          ),
        ),
        // Post-Generation Tools Row
        if (session.results.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolIcon(Icons.auto_fix_high, 'Retouch', 'retouch'),
                _buildToolIcon(Icons.merge_type, 'Stitch', 'stitch'),
                _buildToolIcon(Icons.print_outlined, 'Print', 'print'),
                _buildToolIcon(Icons.download_outlined, 'Save', 'download'),
                _buildToolIcon(Icons.share_outlined, 'Share', 'share'),
              ],
            ),
          ),
        const Divider(color: Colors.white12, height: 1),
        // Recent results thumbnail strip
        if (session.results.isNotEmpty)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              itemCount: session.results.length,
              itemBuilder: (context, index) {
                final result = session.results[index];
                final isSelected = _focusedResult?.id == result.id;
                return GestureDetector(
                  onTap: () => setState(() => _focusedResult = result),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: const Color(0xFFD4AF37), width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: result.imageUrl.startsWith('data:')
                          ? Image.memory(
                              base64Decode(result.imageUrl.split(',')[1]),
                              fit: BoxFit.cover,
                            )
                          : Image.network(result.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildToolIcon(IconData icon, String label, String controlKey) {
    return GestureDetector(
      onTap: () => setState(() => _activeControl = controlKey),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // WHEEL PICKERS

  Widget _buildCameraPicker() {
    final session = context.watch<SessionProvider>();
    return Column(
      children: [
        _buildPickerHeader(
          'CAMERA RIG',
          () => setState(() => _activeControl = 'main'),
        ),
        Expanded(
          child: Stack(
            children: [
              // Gold magnifier highlight band
              Center(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(0.05),
                        const Color(0xFFD4AF37).withOpacity(0.12),
                        const Color(0xFFD4AF37).withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
              // Wheel picker
              ListWheelScrollView.useDelegate(
                itemExtent: 72,
                perspective: 0.003,
                diameterRatio: 1.6,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  session.selectRig(cameraRigs[index]);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: cameraRigs.length,
                  builder: (context, index) {
                    final rig = cameraRigs[index];
                    final isSelected = session.selectedRig?.id == rig.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Camera icon
                          Text(
                            rig.icon,
                            style: TextStyle(fontSize: isSelected ? 22 : 16),
                          ),
                          const SizedBox(width: 14),
                          // Name + specs subtitle
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rig.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFFD4AF37)
                                        : Colors.white54,
                                    fontSize: isSelected ? 16 : 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${rig.specs.lens}  •  ${rig.specs.sensor}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Selection indicator
                          if (isSelected)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackdropPicker() {
    // Flatten BackgroundCategory list into a single list of BackgroundPreset
    final List<BackgroundPreset> flatPresets = backgroundPresets
        .expand((cat) => cat.items)
        .toList();

    return Column(
      children: [
        _buildPickerHeader(
          'BACKDROP',
          () => setState(() => _activeControl = 'main'),
        ),
        Expanded(
          child: Stack(
            children: [
              // Gold magnifier highlight band
              Center(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(0.05),
                        const Color(0xFFD4AF37).withOpacity(0.12),
                        const Color(0xFFD4AF37).withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
              // Wheel picker
              ListWheelScrollView.useDelegate(
                itemExtent: 56,
                perspective: 0.003,
                diameterRatio: 1.6,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedBackdrop = flatPresets[index];
                    _customBgPrompt = flatPresets[index].name;
                    _bgPromptController.text = flatPresets[index].name;
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: flatPresets.length,
                  builder: (context, index) {
                    final preset = flatPresets[index];
                    final isSelected = _selectedBackdrop?.id == preset.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Color dot indicator
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFFD4AF37)
                                  : Colors.white24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              preset.name,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white54,
                                fontSize: isSelected ? 15 : 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFD4AF37),
                              size: 16,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptToInline() {
    return Column(
      children: [
        _buildPickerHeader(
          'PROMPT',
          () => setState(() => _activeControl = 'main'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text input
                TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Describe your vision...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onChanged: (val) => setState(() => _customPrompt = val),
                ),
                const SizedBox(height: 14),
                // Framing mode chips
                const Text(
                  'FRAMING',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        {'label': 'Portrait', 'value': 'portrait'},
                        {'label': 'Full Body', 'value': 'full-body'},
                        {'label': 'Head to Toe', 'value': 'head-to-toe'},
                      ].map((item) {
                        final isActive = _framingMode == item['value'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _framingMode = item['value']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFD4AF37)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              item['label']!,
                              style: TextStyle(
                                color: isActive ? Colors.black : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 14),
                // AI Prompt Presets (from promptCategories)
                ...promptCategories.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 9,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.value.map((preset) {
                          final isActive = _customPrompt == preset;
                          return GestureDetector(
                            onTap: () {
                              _promptController.text = preset;
                              setState(() => _customPrompt = preset);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFD4AF37).withOpacity(0.15)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white12,
                                ),
                              ),
                              child: Text(
                                preset,
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
                const SizedBox(height: 6),
                // Location / Environment Presets
                const Text(
                  'LOCATIONS',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...environmentPromptTips.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.value.map((tip) {
                          final isActive = _customBgPrompt == tip;
                          return GestureDetector(
                            onTap: () {
                              _bgPromptController.text = tip;
                              setState(() => _customBgPrompt = tip);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFD4AF37).withOpacity(0.15)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white12,
                                ),
                              ),
                              child: Text(
                                tip,
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
                const SizedBox(height: 14),
                // Skin texture selector
                const Text(
                  'SKIN TEXTURE',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: skinTextures.length,
                    itemBuilder: (context, index) {
                      final tex = skinTextures[index];
                      final isActive = _selectedSkinTexture.id == tex.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSkinTexture = tex),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFD4AF37).withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFFD4AF37)
                                  : Colors.white24,
                            ),
                          ),
                          child: Text(
                            tex.label,
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFFD4AF37)
                                  : Colors.white54,
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerHeader(String title, VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.check, color: Colors.white),
          ),
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
    final session = context.watch<SessionProvider>();

    if (session.hasUploadedImage && session.uploadedImageBytes != null) {
      // PREVIEW MODE with Real-time Filters
      // Brightness matrix (offset)
      // Brightness 0-200 => Offset -100 to +100
      double b = (_brightness - 100) * 1.5;
      final brightnessMatrix = <double>[
        1,
        0,
        0,
        0,
        b,
        0,
        1,
        0,
        0,
        b,
        0,
        0,
        1,
        0,
        b,
        0,
        0,
        0,
        1,
        0,
      ];

      // Contrast matrix (slope)
      // Contrast 0-200 (100 center). 0->0, 200->2.
      double c = _contrast / 100.0;
      double t = 128 * (1 - c);
      final contrastMatrix = <double>[
        c,
        0,
        0,
        0,
        t,
        0,
        c,
        0,
        0,
        t,
        0,
        0,
        c,
        0,
        t,
        0,
        0,
        0,
        1,
        0,
      ];

      // Saturation matrix
      double s = _saturation / 100.0;
      double lumR = 0.2126;
      double lumG = 0.7152;
      double lumB = 0.0722;
      double oneMinusS = 1 - s;

      final saturationMatrix = <double>[
        (oneMinusS * lumR) + s,
        (oneMinusS * lumG),
        (oneMinusS * lumB),
        0,
        0,
        (oneMinusS * lumR),
        (oneMinusS * lumG) + s,
        (oneMinusS * lumB),
        0,
        0,
        (oneMinusS * lumR),
        (oneMinusS * lumG),
        (oneMinusS * lumB) + s,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ];

      return Stack(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                // Apply Filters: Saturation -> Contrast -> Brightness
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(brightnessMatrix),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(contrastMatrix),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(saturationMatrix),
                      child: Image.memory(
                        session.uploadedImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Adjustments Overlay
          _buildAdjustmentsOverlay(),
        ],
      );
    }

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

  // ═══════════════════════════════════════════════════════════
  // ADJUSTMENTS OVERLAY (Pre-generation)
  // ═══════════════════════════════════════════════════════════

  Widget _buildAdjustmentsOverlay() {
    final tags = <String>[];
    if (_brightness != 100) tags.add('Brightness ${_brightness.toInt()}%');
    if (_contrast != 100) tags.add('Contrast ${_contrast.toInt()}%');
    if (_saturation != 100) tags.add('Saturation ${_saturation.toInt()}%');
    tags.add('Skin: ${_selectedSkinTexture.label}');
    tags.add('Framing: ${_framingMode.replaceAll('-', ' ').toUpperCase()}');
    if (_customPrompt.isNotEmpty)
      tags.add(
        'Prompt: ${_customPrompt.length > 20 ? '${_customPrompt.substring(0, 20)}...' : _customPrompt}',
      );
    if (_selectedBackdrop != null) tags.add('BG: ${_selectedBackdrop!.name}');

    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildRetouchDrawer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SKIN CORE PROTOCOLS',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['MATTE SILK', 'DEWY GLOW', 'PORE LOCK', 'EDITORIAL'].map(
              (label) {
                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Applying $label...'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _activeControl = 'main';
                _focusedResult = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'FINALIZE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchDrawer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections,
              color: const Color(0xFFD4AF37).withOpacity(0.5),
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              'STITCH STUDIO',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Combine multiple generations into a single composition.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stitch feature coming soon!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'START STITCH',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintDrawer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: printProducts.length,
      itemBuilder: (context, index) {
        final product = printProducts[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          dense: true,
          title: Text(
            product.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${product.material} • FROM \$${product.price.toInt()}',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
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
    );
  }

  Widget _buildDownloadDrawer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download, color: Color(0xFFD4AF37), size: 36),
            const SizedBox(height: 12),
            const Text(
              'Save to your device',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDownloadOption('HIGH RES', 'PNG • 4K'),
                const SizedBox(width: 12),
                _buildDownloadOption('STANDARD', 'JPG • 1080p'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(String label, String subtitle) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $label...'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareDrawer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.share, color: Color(0xFFD4AF37), size: 36),
            const SizedBox(height: 12),
            const Text(
              'Share your creation',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShareOption(Icons.link, 'COPY LINK'),
                const SizedBox(width: 16),
                _buildShareOption(Icons.camera_alt, 'INSTAGRAM'),
                const SizedBox(width: 16),
                _buildShareOption(Icons.send, 'MESSAGE'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label coming soon!'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
              letterSpacing: 0.5,
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
