import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/types.dart';
import '../shared/constants.dart';
import '../services/gemini_service.dart';

import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StudioDashboardScreen extends StatefulWidget {
  final bool startInStitchMode;
  const StudioDashboardScreen({super.key, this.startInStitchMode = false});

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

  // Adjustment sliders state (Using ValueNotifier for 60fps real-time updates)
  final ValueNotifier<double> _brightness = ValueNotifier<double>(100);
  final ValueNotifier<double> _contrast = ValueNotifier<double>(100);
  final ValueNotifier<double> _saturation = ValueNotifier<double>(100);

  // NEW: Framing Options
  // NEW: Missing web features - Gender & Style
  String _gender = 'female'; // 'female', 'male', 'unspecified'
  String _styleTemperature = 'neutral'; // 'cool', 'warm', 'neutral'
  String _framingMode = 'portrait'; // 'portrait', 'full-body', 'head-to-toe'
  String _selectedClothingStyle = ''; // from promptCategories['Styling & Vibe']
  Map<int, String> _stitchPersonStyles =
      {}; // per-person clothing styles for stitch mode

  // Stitch Studio state
  String _selectedGroupType = ''; // key from stitchGroupPresets
  String _selectedGroupStyle = ''; // selected style variation
  final TextEditingController _stitchPromptController = TextEditingController();

  // V2 Split View State
  String _activeControl =
      'main'; // 'main', 'camera', 'backdrop', 'prompt', 'style', 'retouch', 'stitch', 'print', 'download', 'share'
  GenerationResult? _focusedResult;
  Uint8List? _decodedImageBytes;

  Future<void> _decodeFocusedImage() async {
    if (_focusedResult == null) return;
    if (_focusedResult!.imageUrl.startsWith('data:')) {
      try {
        final base64String = _focusedResult!.imageUrl.split(',')[1];
        setState(() {
          _decodedImageBytes = base64Decode(base64String);
        });
      } catch (e) {
        debugPrint("Error decoding image: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.startInStitchMode) {
      _activeControl = 'stitch';
    }
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
    _stitchPromptController.dispose();
    _brightness.dispose();
    _contrast.dispose();
    _saturation.dispose();
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
            '${session.selectedPackage!.basePrompt} $_customPrompt ${_customBgPrompt.isNotEmpty ? " Background: $_customBgPrompt" : ""} \nTarget Gender: $_gender \nColor Temperature: $_styleTemperature ${_selectedClothingStyle.isNotEmpty ? "\nClothing Style: $_selectedClothingStyle" : ""} \nFRAMING: $framingText';
      }

      // Append Adjustment Logic to Prompt
      fullPrompt +=
          """
      
      Adjustments:
      - Brightness: ${_brightness.value.toInt()}% (Normal=100%)
      - Contrast: ${_contrast.value.toInt()}% (Normal=100%)
      - Saturation: ${_saturation.value.toInt()}% (Normal=100%)
      - Skin Finish: ${_selectedSkinTexture.label}
      """;

      String? clothingRef;
      if (session.hasClothingReference) {
        clothingRef = base64Encode(session.clothingReferenceBytes!);
      }

      final resultText = await service.generatePortrait(
        referenceImageBase64: base64Encode(session.uploadedImageBytes!),
        basePrompt: fullPrompt,
        opticProtocol: session.selectedRig!.opticProtocol,
        backgroundImageBase64: null, // TODO: Handle background image if needed
        clothingReferenceBase64: clothingRef,
        skinTexturePrompt: _selectedSkinTexture.prompt,
        preserveAgeAndBody: session.preserveAgeAndBody,
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

      final newResult = GenerationResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: imageUrl,
        mediaType: 'image',
        packageType: session.selectedPackage!.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      session.addResult(newResult);
      if (mounted) {
        setState(() {
          _focusedResult = newResult;
        });
        _decodeFocusedImage();
      }
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

  Future<void> _pickStitchImage(SessionProvider session) async {
    if (session.stitchImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 people allowed.')),
      );
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      session.addStitchImage(bytes);
    }
  }

  Future<void> _generateStitch(SessionProvider session) async {
    if (session.stitchImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 people for a group stitch.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    session.setGenerating(true);
    try {
      debugPrint('Studio: Starting Stitch Generation...');
      final service = GeminiService();

      final imagesB64 = session.stitchImages
          .map((bytes) => base64Encode(bytes))
          .toList();

      // Build composite stitch prompt from: group type + style + user prompt + base prompt
      final promptParts = <String>[];
      if (_selectedGroupType.isNotEmpty) {
        promptParts.add('Group type: $_selectedGroupType.');
      }
      if (_selectedGroupStyle.isNotEmpty) {
        promptParts.add('Style: $_selectedGroupStyle.');
      }
      if (_stitchPromptController.text.trim().isNotEmpty) {
        promptParts.add(_stitchPromptController.text.trim());
      }
      if (session.selectedPackage != null) {
        promptParts.add(session.selectedPackage!.basePrompt);
      }
      if (_customPrompt.isNotEmpty) {
        promptParts.add(_customPrompt);
      }
      if (_customBgPrompt.isNotEmpty) {
        promptParts.add('Background: $_customBgPrompt');
      }
      final fullPrompt = promptParts.join(' ');

      // Build per-person style descriptions
      final perPersonStyles = <String>[];
      for (int i = 0; i < session.stitchImages.length; i++) {
        final style = _stitchPersonStyles[i] ?? '';
        if (style.isNotEmpty) {
          perPersonStyles.add('Person ${i + 1}: $style');
        }
      }

      String? clothingRef;
      if (session.hasClothingReference) {
        clothingRef = base64Encode(session.clothingReferenceBytes!);
      }

      final resultText = await service.generateGroupStitch(
        identityImagesBase64: imagesB64,
        prompt: fullPrompt,
        vibe: session.stitchVibe,
        backgroundImageBase64: null,
        clothingReferenceBase64: clothingRef,
        perPersonStyles: perPersonStyles.isNotEmpty ? perPersonStyles : null,
        preserveAgeAndBody: session.preserveAgeAndBody,
      );

      String imageUrl;
      if (resultText.startsWith('data:image')) {
        imageUrl = resultText;
      } else {
        imageUrl =
            'data:image/jpeg;base64,${base64Encode(session.stitchImages.first)}';
      }

      final newResult = GenerationResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: imageUrl,
        mediaType: 'image_stitch',
        packageType: PortraitPackage.STITCH,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      session.addResult(newResult);
      if (mounted) {
        setState(() {
          _focusedResult = newResult;
        });
        _decodeFocusedImage();
      }
    } catch (e) {
      debugPrint("Stitch failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Stitch failed: $e')));
      }
    } finally {
      session.setGenerating(false);
    }
  }

  Future<void> _saveToGallery() async {
    final session = context.read<SessionProvider>();
    if (session.results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image to download.')));
      return;
    }

    final imageUrl = session.results.first.imageUrl;
    Uint8List? bytes;

    try {
      if (imageUrl.startsWith('data:')) {
        final base64String = imageUrl.split(',').last;
        bytes = base64Decode(base64String);
      }

      if (bytes != null) {
        final result = await ImageGallerySaver.saveImage(bytes);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to Gallery: $result')));
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _shareImage() async {
    final session = context.read<SessionProvider>();
    if (session.results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image to share.')));
      return;
    }

    final imageUrl = session.results.first.imageUrl;
    Uint8List? bytes;

    try {
      if (imageUrl.startsWith('data:')) {
        final base64String = imageUrl.split(',').last;
        bytes = base64Decode(base64String);
      }

      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/shared_image.png').create();
        await file.writeAsBytes(bytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Check out my Luxe AI portrait! ✨');
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activeControl != 'main') {
          // Close any open drawer first
          setState(() {
            _activeControl = 'main';
            _focusedResult = null;
          });
        } else {
          // We're on main — navigate back safely
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/boutique');
          }
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

  // Helper: build a color filter matrix from brightness/contrast/saturation
  ColorFilter _buildRetouchFilter(
    double brightness,
    double contrast,
    double saturation,
  ) {
    // Normalize 0-200 range to multipliers
    final double b = brightness / 100.0; // 1.0 = normal
    final double c = contrast / 100.0;
    final double s = saturation / 100.0;

    // Brightness offset (shift toward white or black)
    final double bOffset = (b - 1.0) * 255;

    // Contrast: scale around 0.5 midpoint
    final double cOffset = (1.0 - c) * 128;

    // Saturation: interpolate between grayscale and full color
    final double sr = (1.0 - s) * 0.2126;
    final double sg = (1.0 - s) * 0.7152;
    final double sb = (1.0 - s) * 0.0722;

    return ColorFilter.matrix(<double>[
      (sr + s) * c,
      sg * c,
      sb * c,
      0,
      bOffset + cOffset,
      sr * c,
      (sg + s) * c,
      sb * c,
      0,
      bOffset + cOffset,
      sr * c,
      sg * c,
      (sb + s) * c,
      0,
      bOffset + cOffset,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  Widget _buildEditorImageArea(GenerationResult result) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: ValueListenableBuilder<double>(
            valueListenable: _brightness,
            builder: (context, b, _) => ValueListenableBuilder<double>(
              valueListenable: _contrast,
              builder: (context, c, _) => ValueListenableBuilder<double>(
                valueListenable: _saturation,
                builder: (context, s, _) => ColorFiltered(
                  colorFilter: _buildRetouchFilter(b, c, s),
                  child: _decodedImageBytes != null
                      ? Image.memory(_decodedImageBytes!, fit: BoxFit.contain)
                      : (result.imageUrl.startsWith('data:')
                            ? Image.memory(
                                base64Decode(result.imageUrl.split(',')[1]),
                                fit: BoxFit.contain,
                              )
                            : Image.network(
                                result.imageUrl,
                                fit: BoxFit.contain,
                              )),
                ),
              ),
            ),
          ),
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
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/boutique');
              }
            },
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
      case 'style':
        return _buildDrawerWithHeader('STYLE STUDIO', _buildStyleDrawer());
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
                _buildToolIcon(Icons.style_outlined, 'Style', 'style'),
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
                  onTap: () {
                    setState(() {
                      _focusedResult = result;
                    });
                    _decodeFocusedImage();
                  },
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
                              gaplessPlayback: true,
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
      onTap: () {
        final session = context.read<SessionProvider>();
        setState(() {
          _activeControl = controlKey;
          // Auto-focus latest if retouching and none focused
          if (controlKey == 'retouch' &&
              _focusedResult == null &&
              session.results.isNotEmpty) {
            _focusedResult = session.results.last;
            _decodeFocusedImage();
          }
        });
      },
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
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mic (Stub)
                        IconButton(
                          icon: const Icon(
                            Icons.mic,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'VOICE PROTOCOL: V-AURA Integration Coming Soon',
                                ),
                                backgroundColor: Color(0xFFD4AF37),
                              ),
                            );
                          },
                        ),
                        // Enhance (Live — calls GeminiService.enhancePrompt)
                        IconButton(
                          icon: const Icon(
                            Icons.auto_fix_high,
                            color: Color(0xFFD4AF37),
                            size: 20,
                          ),
                          onPressed: () async {
                            final draft = _promptController.text.trim();
                            if (draft.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Type a prompt to enhance.'),
                                ),
                              );
                              return;
                            }
                            // Show loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enhancing prompt with AI...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            try {
                              final enhanced = await GeminiService()
                                  .enhancePrompt(draft);
                              if (enhanced.isNotEmpty && mounted) {
                                setState(() {
                                  _promptController.text = enhanced;
                                  _customPrompt = enhanced;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✨ Prompt enhanced!'),
                                    backgroundColor: Color(0xFFD4AF37),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Enhance failed: $e')),
                                );
                              }
                            }
                          },
                        ),
                        // Clear (Functional)
                        if (_promptController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () {
                              _promptController.clear();
                              setState(() => _customPrompt = '');
                            },
                          ),
                      ],
                    ),
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
                          entry.key.toUpperCase(),
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
                              setState(() {
                                _customBgPrompt = tip;
                                _selectedBackdrop =
                                    null; // Clear wheel selection
                              });
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
                  'SKIN ARCHITECTURE',
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
                const SizedBox(height: 100), // Bottom safety padding
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
      onTap: session.isGenerating
          ? null
          : () {
              // Route to stitch generation if user has stitch images loaded
              if (session.stitchImages.isNotEmpty ||
                  _activeControl == 'stitch') {
                _generateStitch(session);
              } else {
                _generatePortrait(session);
              }
            },
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
    tags.add('Gender: ${_gender.toUpperCase()}');
    if (_styleTemperature != 'neutral')
      tags.add('Grade: ${_styleTemperature.toUpperCase()}');
    if (_selectedClothingStyle.isNotEmpty)
      tags.add('Style: $_selectedClothingStyle');

    // Stitch specific tags
    final session = context.read<SessionProvider>();
    if (session.stitchImages.isNotEmpty) {
      if (_selectedGroupType.isNotEmpty) tags.add('Group: $_selectedGroupType');
      tags.add('Vibe: ${session.stitchVibe.toUpperCase()}');
    }

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

  Widget _buildStyleDrawer() {
    final clothingOptions = promptCategories['Styling & Vibe'] ?? [];
    final session = context.watch<SessionProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. IDENTITY PROTOCOL
          const Text(
            'IDENTITY PROTOCOL',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRESERVE AGE & BODY',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Locks age and body type',
                      style: TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                  ],
                ),
                Switch(
                  value: session.preserveAgeAndBody,
                  onChanged: (val) => session.setPreserveAgeAndBody(val),
                  activeColor: const Color(0xFFD4AF37),
                  activeTrackColor: const Color(
                    0xFFD4AF37,
                  ).withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white24,
                  inactiveTrackColor: Colors.white10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. GENDER
          const Text(
            'TARGET GENDER',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['female', 'male', 'unspecified'].map((g) {
              final isActive = _gender == g;
              return GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(
                    g.toUpperCase(),
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 2. CLOTHING STYLE
          const Text(
            'CLOTHING STYLE',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: clothingOptions.map((style) {
              final isActive = _selectedClothingStyle == style;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedClothingStyle = isActive ? '' : style;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(
                    style.toUpperCase(),
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : Colors.white54,
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 3. COLOR GRADING
          const Text(
            'COLOR GRADING',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['neutral', 'warm', 'cool'].map((s) {
              final isActive = _styleTemperature == s;
              return GestureDetector(
                onTap: () => setState(() => _styleTemperature = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(
                    s.toUpperCase(),
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 4. VIRTUAL TRY-ON
          const Text(
            'VIRTUAL TRY-ON',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                if (session.hasClothingReference)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          session.clothingReferenceBytes!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        onPressed: () => session.clearClothingReference(),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _pickClothingReference,
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFFD4AF37),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "ADD CLOTHING PHOTO",
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  "Upload a photo of a garment to apply it to your generation.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // APPLY STYLE — triggers regeneration
          Consumer<SessionProvider>(
            builder: (context, session, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: session.isGenerating
                      ? null
                      : () {
                          setState(() {
                            _activeControl = 'main';
                            _focusedResult = null;
                          });
                          if (session.stitchImages.isNotEmpty) {
                            _generateStitch(session);
                          } else {
                            _generatePortrait(session);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: session.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'APPLY STYLE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 120), // Bottom safety padding
        ],
      ),
    );
  }

  Widget _buildRetouchDrawer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SKIN TEXTURE (Synced with constants)
          const Text(
            'SKIN ARCHITECTURE',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skinTextures.map((tex) {
              final isActive = _selectedSkinTexture.id == tex.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedSkinTexture = tex),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFD4AF37).withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(
                    tex.label,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : Colors.white54,
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 4. FINE TUNE SLIDERS (ValueNotifier driven for performance)
          const Text(
            'FINE TUNE',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSlider('BRIGHTNESS', _brightness),
          _buildSlider('CONTRAST', _contrast),
          _buildSlider('SATURATION', _saturation),

          const SizedBox(height: 24),

          // APPLY RETOUCH — triggers regeneration with current retouch settings
          Consumer<SessionProvider>(
            builder: (context, session, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: session.isGenerating
                      ? null
                      : () {
                          // Close drawer and trigger generation with retouch settings
                          setState(() {
                            _activeControl = 'main';
                            _focusedResult = null;
                          });
                          // Route to correct generation based on mode
                          if (session.stitchImages.isNotEmpty) {
                            _generateStitch(session);
                          } else {
                            _generatePortrait(session);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: session.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'APPLY RETOUCH',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 120), // Bottom safety padding
        ],
      ),
    );
  }

  Widget _buildSlider(String label, ValueNotifier<double> notifier) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFD4AF37),
                inactiveTrackColor: Colors.white10,
                thumbColor: const Color(0xFFD4AF37),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 200,
                onChanged: (v) => notifier.value = v,
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildStitchDrawer() {
    final session = context.watch<SessionProvider>();
    final groupTypes = stitchGroupPresets.keys.toList();
    final styleVariations = _selectedGroupType.isNotEmpty
        ? (stitchGroupPresets[_selectedGroupType] ?? [])
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        120,
      ), // Increased bottom padding to clear footer
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. GROUP TYPE ──
          const Text(
            'GROUP TYPE',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.1, 0.9, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: groupTypes.length,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final type = groupTypes[index];
                  final isActive = _selectedGroupType == type;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedGroupType = isActive ? '' : type;
                      _selectedGroupStyle = '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFD4AF37)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? Colors.black : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 2. STYLE VARIATIONS (shown when a group type is selected) ──
          if (styleVariations.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '${_selectedGroupType.toUpperCase()} STYLES',
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: styleVariations.map((style) {
                final isActive = _selectedGroupStyle == style;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedGroupStyle = isActive ? '' : style;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFD4AF37)
                            : Colors.white10,
                      ),
                    ),
                    child: Text(
                      style.split(',').first.toUpperCase(),
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFFD4AF37)
                            : Colors.white38,
                        fontSize: 9,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // ── 3. STITCH PROMPT ──
          const Text(
            'GROUP PROMPT',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stitchPromptController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Add scene details, mood, location...',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                // Enhance
                IconButton(
                  icon: const Icon(
                    Icons.auto_fix_high,
                    color: Color(0xFFD4AF37),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () async {
                    final draft = _stitchPromptController.text.trim();
                    if (draft.isEmpty) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enhancing...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    try {
                      final enhanced = await GeminiService().enhancePrompt(
                        draft,
                      );
                      if (enhanced.isNotEmpty && mounted) {
                        setState(() => _stitchPromptController.text = enhanced);
                      }
                    } catch (_) {}
                  },
                ),
                // Clear
                if (_stitchPromptController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.white24,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () =>
                        setState(() => _stitchPromptController.clear()),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // ── 4. SQUAD SELECTOR ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STITCH SQUAD (${session.stitchImages.length}/5)',
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (session.stitchImages.isNotEmpty)
                const Text(
                  'TAP TO REMOVE',
                  style: TextStyle(fontSize: 8, color: Colors.white12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.1, 0.8, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: [
                  if (session.stitchImages.length < 5)
                    GestureDetector(
                      onTap: () => _pickStitchImage(session),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Color(0xFFD4AF37), size: 20),
                            SizedBox(height: 2),
                            Text(
                              'ADD',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...session.stitchImages.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: MemoryImage(entry.value),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: Colors.white12),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => session.removeStitchImage(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── 5. PER-PERSON STYLING ──
          if (session.stitchImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'PER-PERSON STYLE',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...session.stitchImages.asMap().entries.map((entry) {
              final idx = entry.key;
              final bytes = entry.value;
              final currentStyle = _stitchPersonStyles[idx] ?? '';
              final clothingOptions = promptCategories['Styling & Vibe'] ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        bytes,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'P${idx + 1}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black,
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.1, 0.8, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: SizedBox(
                          height: 26,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            children: clothingOptions.map((style) {
                              final isActive = currentStyle == style;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _stitchPersonStyles[idx] = isActive
                                      ? ''
                                      : style;
                                }),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(
                                            0xFFD4AF37,
                                          ).withValues(alpha: 0.1)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isActive
                                          ? const Color(0xFFD4AF37)
                                          : Colors.white10,
                                    ),
                                  ),
                                  child: Text(
                                    style.toUpperCase(),
                                    style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFFD4AF37)
                                          : Colors.white38,
                                      fontSize: 8,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 12),

          // ── 6. VIBE CHECK ──
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => session.setStitchVibe('matching'),
                  child: _buildVibeChip(
                    'MATCHING',
                    session.stitchVibe == 'matching',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => session.setStitchVibe('individual'),
                  child: _buildVibeChip(
                    'INDIVIDUAL',
                    session.stitchVibe == 'individual',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── 7. GENERATE ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: session.isGenerating
                  ? null
                  : () => _generateStitch(session),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: session.isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'GENERATE GROUP PHOTO',
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

  Widget _buildVibeChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFD4AF37).withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFFD4AF37) : Colors.white12,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFFD4AF37) : Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrintDrawer() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Center(
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
                _buildDownloadOption('HIGH RES', 'PNG • 4K', _saveToGallery),
                const SizedBox(width: 12),
                _buildDownloadOption('STANDARD', 'JPG • 1080p', _saveToGallery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(
    String label,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Center(
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
                _buildShareOption(Icons.link, 'COPY LINK', _shareImage),
                const SizedBox(width: 16),
                _buildShareOption(Icons.camera_alt, 'INSTAGRAM', _shareImage),
                const SizedBox(width: 16),
                _buildShareOption(Icons.send, 'MESSAGE', _shareImage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

  Future<void> _pickClothingReference() async {
    final session = context.read<SessionProvider>();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      session.uploadClothingReference(bytes, image.name);
    }
  }
}
