import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/types.dart';
import '../shared/constants.dart';
import '../services/gemini_service.dart';
import '../widgets/comparison_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/stripe_service.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../shared/web_helper.dart'
    if (dart.library.html) '../shared/web_helper_web.dart';

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

  // Adjustment sliders state (Using ValueNotifier for 60fps real-time updates) // Retouch State
  final ValueNotifier<double> _brightness = ValueNotifier<double>(100);
  final ValueNotifier<double> _contrast = ValueNotifier<double>(100);
  final ValueNotifier<double> _saturation = ValueNotifier<double>(100);
  final ValueNotifier<double> _temperature = ValueNotifier<double>(
    0,
  ); // -1.0 to 1.0
  final ValueNotifier<double> _tint = ValueNotifier<double>(0); // -1.0 to 1.0
  final ValueNotifier<double> _vignette = ValueNotifier<double>(
    0,
  ); // 0.0 to 1.0

  // Voice Interaction
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // NEW: Framing Options
  // NEW: Missing web features - Gender & Style
  String _gender = 'female'; // 'female', 'male', 'unspecified'
  String _styleTemperature = 'neutral'; // 'cool', 'warm', 'neutral'
  String _framingMode = 'portrait'; // 'portrait', 'full-body', 'head-to-toe'
  String _selectedClothingStyle = ''; // from promptCategories['Styling & Vibe']
  final Map<int, String> _stitchPersonStyles =
      {}; // per-person clothing styles for stitch mode
  String _selectedSchoolQuery = ''; // Filter for "Your School" wardrobe

  // Stitch Studio state
  String _selectedGroupType = ''; // key from stitchGroupPresets
  String _selectedGroupStyle = ''; // selected style variation
  final TextEditingController _stitchPromptController = TextEditingController();

  // Campus Studio State
  final TextEditingController _zipController = TextEditingController();
  List<dynamic> _campusResults = [];
  bool _isSearchingCampus = false;
  bool _isIdentifyingCampus = false;

  // V2 Split View State
  bool _isComparing = false;
  String _selectedWardrobeCategory = 'Classic';
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
        session.setSelectedRig(cameraRigs.first);
      }

      // Auto-select first available package if none selected (Fix for missing generation)
      if (session.selectedPackage == null && packages.isNotEmpty) {
        session.setSelectedPackage(packages.first);
      }

      // Sync local gender with session
      setState(() {
        _gender = session.soloGender;
      });

      // Fetch user profile for credits
      session.fetchUserProfile();

      // Removed auto-generation to prevent wasting credits/resources.
      // User must explicitly click GENERATE.
      // User must explicitly click GENERATE.
    });
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('STT Status: $val'),
        onError: (val) => debugPrint('STT Error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _promptController.text = val.recognizedWords;
              _customPrompt = val.recognizedWords;
              // Removed voice confidence tracking
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _bgPromptController.dispose();
    _stitchPromptController.dispose();
    _zipController.dispose();
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
      if (!session.hasUploadedImage) {
        debugPrint('Studio: FAILURE - Missing image bytes');
      }
      if (session.selectedPackage == null) {
        debugPrint('Studio: FAILURE - Missing package');
      }

      // Auto-recover for testing if package is missing
      if (session.selectedPackage == null && packages.isNotEmpty) {
        debugPrint('Studio: Attempting auto-recovery for package...');
        session.setSelectedPackage(packages.first);
        if (session.selectedPackage != null) {
          debugPrint(
            'Studio: Auto-recovery successful. Selected: ${session.selectedPackage!.name}',
          );
        }
      }

      if (!session.hasUploadedImage) return;
    }

    if (session.selectedRig == null && cameraRigs.isNotEmpty) {
      session.setSelectedRig(cameraRigs.first);
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
            '${session.selectedPackage!.basePrompt} ${session.selectedStyle!.promptAddition} $_customPrompt ${_customBgPrompt.isNotEmpty ? " Background: $_customBgPrompt" : ""} ${_selectedClothingStyle.isNotEmpty ? "\nClothing Style: $_selectedClothingStyle" : ""} \nTarget Gender: $_gender \nBody Type: ${session.selectedBodyType} \nColor Temperature: $_styleTemperature \nFRAMING: $framingText';
        debugPrint('Studio: Using Single Style Prompt: $fullPrompt');
      } else {
        fullPrompt =
            '${session.selectedPackage!.basePrompt} $_customPrompt ${_customBgPrompt.isNotEmpty ? " Background: $_customBgPrompt" : ""} \nTarget Gender: $_gender \nBody Type: ${session.selectedBodyType} \nColor Temperature: $_styleTemperature ${_selectedClothingStyle.isNotEmpty ? "\nClothing Style: $_selectedClothingStyle" : ""} \nFRAMING: $framingText';
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

      final identityImagesB64 = session.identityImages
          .map((bytes) => base64Encode(bytes))
          .toList();

      String? backgroundRef;
      if (session.hasBackgroundReference) {
        backgroundRef = base64Encode(session.backgroundReferenceBytes!);
      }

      String? campusLogoRef;
      if (session.hasCampusReference) {
        campusLogoRef = base64Encode(session.campusReferenceBytes!);
      }

      if (session.selectedCampus != null) {
        fullPrompt +=
            "\nSchool Branding: ${session.selectedCampus!.name}. Official Colors: ${session.selectedCampus!.colors.join(', ')}.";
      }

      final resultText = await service.generatePortrait(
        referenceImagesBase64: identityImagesB64,
        basePrompt: fullPrompt,
        opticProtocol: session.selectedRig!.opticProtocol,
        backgroundImageBase64: backgroundRef,
        clothingReferenceBase64: clothingRef,
        campusLogoBase64: campusLogoRef,
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

      // Decrement credits
      session.decrementCredit('image');
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
    final List<XFile> images = await picker.pickMultiImage();

    for (var image in images) {
      if (session.stitchImages.length >= 5) break;
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
          .map((subject) => base64Encode(subject.bytes))
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
        final gender = session.stitchImages[i].gender;
        String desc = 'Person ${i + 1} (${gender.toUpperCase()})';
        if (style.isNotEmpty) {
          desc += ': $style';
        }
        perPersonStyles.add(desc);
      }

      String? clothingRef;
      if (session.hasClothingReference) {
        clothingRef = base64Encode(session.clothingReferenceBytes!);
      }

      String? backgroundRef;
      if (session.hasBackgroundReference) {
        backgroundRef = base64Encode(session.backgroundReferenceBytes!);
      }

      final resultText = await service.generateGroupStitch(
        identityImagesBase64: imagesB64,
        prompt: fullPrompt,
        vibe: session.stitchVibe,
        backgroundImageBase64: backgroundRef,
        clothingReferenceBase64: clothingRef,
        perPersonStyles: perPersonStyles.isNotEmpty ? perPersonStyles : null,
        preserveAgeAndBody: session.preserveAgeAndBody,
      );

      String imageUrl;
      if (resultText.startsWith('data:image')) {
        imageUrl = resultText;
      } else {
        imageUrl =
            'data:image/jpeg;base64,${base64Encode(session.stitchImages.first.bytes)}';
      }

      final newResult = GenerationResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: imageUrl,
        mediaType: 'image_stitch',
        packageType: PortraitPackage.stitch,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      session.addResult(newResult);
      if (mounted) {
        setState(() {
          _focusedResult = newResult;
        });
        _decodeFocusedImage();
      }

      // Decrement credits (stitch counts as image)
      session.decrementCredit('image');
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

      if (bytes == null) return;

      if (kIsWeb) {
        // Web Download implementation
        WebHelper.downloadImage(
          bytes,
          "luxe_portrait_${DateTime.now().millisecondsSinceEpoch}.png",
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download started')));
      } else {
        // Mobile Implementation with Permission Check
        bool hasPermission = false;
        if (Platform.isAndroid) {
          // For Android 13+ (API 33+), we might need photos permission
          hasPermission =
              await Permission.photos.request().isGranted ||
              await Permission.storage.request().isGranted;
        } else {
          hasPermission = await Permission.photos.request().isGranted;
        }

        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied.')),
            );
          }
          return;
        }

        final result = await ImageGallerySaverPlus.saveImage(bytes);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to Gallery: $result')));
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('MissingPluginException')) {
          errorMsg = 'This feature is not supported on this platform.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $errorMsg')));
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
    final session = context.watch<SessionProvider>();
    final isEnterprise = session.isEnterpriseMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activeControl != 'main') {
          setState(() {
            _activeControl = 'main';
            _focusedResult = null;
          });
        } else {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/boutique');
          }
        }
      },
      child: Scaffold(
        backgroundColor: isEnterprise
            ? AppColors.enterpriseNavy
            : AppColors.midnightNavy,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                flex: 5, // Changed from 6 to 5
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
              Expanded(
                flex: 5, // Changed from 4 to 5
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.softCharcoal,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.softPlatinum.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  child: _buildControlCenter(isEnterprise),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsViewer(SessionProvider session) {
    final result = _focusedResult ?? session.results.last;
    final isDataUrl = result.imageUrl.startsWith('data:');
    final imageProvider = isDataUrl
        ? MemoryImage(base64Decode(result.imageUrl.split(',')[1]))
        : NetworkImage(result.imageUrl) as ImageProvider;

    return Stack(
      children: [
        // Main Image Area
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: _isComparing && session.hasUploadedImage
              ? ComparisonSlider(
                  beforeImage: MemoryImage(session.uploadedImageBytes!),
                  afterImage: imageProvider,
                )
              : Image(image: imageProvider, fit: BoxFit.contain),
        ),

        // Top Toolbar (Motion & Compare)
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              // Compare Toggle
              if (session.hasUploadedImage)
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: FloatingActionButton.small(
                    heroTag: 'compare_btn',
                    backgroundColor: _isComparing
                        ? AppColors.matteGold
                        : Colors.black54,
                    child: Icon(
                      Icons.compare,
                      color: _isComparing
                          ? Colors.black
                          : AppColors.softPlatinum,
                    ),
                    onPressed: () =>
                        setState(() => _isComparing = !_isComparing),
                  ),
                ),

              // Motion / Video Generation
              FloatingActionButton.small(
                heroTag: 'motion_btn',
                backgroundColor: Colors.black54,
                child: Icon(Icons.videocam, color: AppColors.softPlatinum),
                onPressed: () => _generateCinematicVideo(session, result),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper: build a color filter matrix from inputs
  ColorFilter _buildRetouchFilter(
    double brightness,
    double contrast,
    double saturation,
    double temp, // -1.0 to 1.0 (Blue <-> Orange)
    double tint, // -1.0 to 1.0 (Green <-> Magenta)
  ) {
    // 1. Brightness / Contrast / Saturation (Standard)
    final double b = brightness / 100.0;
    final double c = contrast / 100.0;
    final double s = saturation / 100.0;

    final double bOffset = (b - 1.0) * 255;
    final double cOffset = (1.0 - c) * 128;

    // Saturation coefficients
    final double lumR = 0.2126;
    final double lumG = 0.7152;
    final double lumB = 0.0722;

    final double sr = (1.0 - s) * lumR;
    final double sg = (1.0 - s) * lumG;
    final double sb = (1.0 - s) * lumB;

    // BCS Matrix
    // [R, G, B, A, Offset]
    final List<double> matrixBCS = [
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
    ];

    // 2. Temperature & Tint Matrix
    // Temp > 0 => Warmer (More R, Less B)
    // Temp < 0 => Cooler (Less R, More B)
    // Tint > 0 => Magenta (More R/B, Less G)
    // Tint < 0 => Green (Less R/B, More G)

    double rScale = 1.0;
    double gScale = 1.0;
    double bScale = 1.0;

    // Temp Logic
    if (temp > 0) {
      rScale += temp * 0.2; // Warmer
      bScale -= temp * 0.2;
    } else {
      rScale += temp * 0.2; // Cooler (temp is negative)
      bScale -= temp * 0.2;
    }

    // Tint Logic
    if (tint > 0) {
      gScale -= tint * 0.2; // Magenta (Less Green)
    } else {
      gScale -= tint * 0.2; // Green (More green, tint negative)
    }

    // Combined scaling matrix (simplified multiplication)
    return ColorFilter.matrix([
      matrixBCS[0] * rScale,
      matrixBCS[1] * rScale,
      matrixBCS[2] * rScale,
      0,
      matrixBCS[4] * rScale,
      matrixBCS[5] * gScale,
      matrixBCS[6] * gScale,
      matrixBCS[7] * gScale,
      0,
      matrixBCS[9] * gScale,
      matrixBCS[10] * bScale,
      matrixBCS[11] * bScale,
      matrixBCS[12] * bScale,
      0,
      matrixBCS[14] * bScale,
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
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _brightness,
              _contrast,
              _saturation,
              _temperature,
              _tint,
              _vignette,
            ]),
            builder: (context, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: _buildRetouchFilter(
                      _brightness.value,
                      _contrast.value,
                      _saturation.value,
                      _temperature.value,
                      _tint.value,
                    ),
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
                  // Vignette Overlay
                  if (_vignette.value > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius:
                                  1.2, // Slightly larger than screen to soften edges
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(
                                  alpha: _vignette.value * 0.9,
                                ), // Max 90% opacity
                              ],
                              stops: const [
                                0.3,
                                1.0,
                              ], // Start darkening at 30% out
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreditBadge(IconData icon, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softPlatinum.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softPlatinum.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.matteGold),
          SizedBox(width: 4),
          Text('$count', style: AppTypography.microBold()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            child: Icon(
              Icons.arrow_back_ios,
              color: AppColors.coolGray,
              size: 20,
            ),
          ),
          Text(
            'STUDIO',
            style: AppTypography.microBold(
              color: AppColors.softPlatinum,
            ).copyWith(letterSpacing: 4),
          ),
          Consumer<SessionProvider>(
            builder: (context, session, _) {
              final p = session.userProfile?.photoGenerations ?? 0;
              final v = session.userProfile?.videoGenerations ?? 0;
              return Row(
                children: [
                  _buildCreditBadge(Icons.camera_alt, p),
                  SizedBox(width: 8),
                  _buildCreditBadge(Icons.videocam, v),
                ],
              );
            },
          ),
          SizedBox(width: 8),
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

  Widget _buildControlCenter(bool isEnterprise) {
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
        return _buildDrawerWithHeader(
          isEnterprise ? 'BRAND MATCHING' : 'STYLE STUDIO',
          _buildStyleDrawer(),
        );
      case 'stitch':
        return _buildDrawerWithHeader(
          isEnterprise ? 'CORPORATE TEAM GENERATOR™' : 'STITCH STUDIO',
          _buildStitchDrawer(),
        );
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

  Widget _buildSelectionStack(SessionProvider session) {
    // Collect active choices
    final items = <Widget>[];

    // 1. Gender
    items.add(
      _buildStackChip(
        Icons.person,
        _gender.toUpperCase(),
        onTap: () {
          // Toggle gender on tap
          setState(() {
            if (_gender == 'female') {
              _gender = 'male';
            } else if (_gender == 'male') {
              _gender = 'unspecified';
            } else {
              _gender = 'female';
            }
            session.setSoloGender(_gender);
          });
        },
        isActive: true,
      ),
    );

    // 2. Camera Rig
    if (session.selectedRig != null) {
      items.add(
        _buildStackChip(
          Icons.camera,
          session.selectedRig!.name.split('|').first.trim(),
          onTap: () => setState(() => _activeControl = 'camera'),
          isActive: true,
        ),
      );
    }

    // 3. Backdrop
    if (_selectedBackdrop != null) {
      items.add(
        _buildStackChip(
          Icons.wallpaper,
          _selectedBackdrop!.name,
          onTap: () => setState(() => _activeControl = 'backdrop'),
          isActive: true,
        ),
      );
    } else if (_customBgPrompt.isNotEmpty) {
      items.add(
        _buildStackChip(
          Icons.wallpaper,
          'Custom BG',
          onTap: () => setState(() => _activeControl = 'backdrop'),
          isActive: true,
        ),
      );
    }

    // 4. Style
    if (session.selectedStyle != null) {
      items.add(
        _buildStackChip(
          Icons.palette,
          session.selectedStyle!.name,
          onTap: () => setState(() => _activeControl = 'style'),
          isActive: true,
        ),
      );
    } else if (session.hasClothingReference) {
      items.add(
        _buildStackChip(
          Icons.checkroom,
          'Custom Outfit',
          onTap: () => setState(() => _activeControl = 'style'),
          isActive: true,
        ),
      );
    }

    // 5. Prompt
    if (_customPrompt.isNotEmpty) {
      items.add(
        _buildStackChip(
          Icons.edit_note,
          'Custom Prompt',
          onTap: () => setState(() => _activeControl = 'prompt'),
          isActive: true,
        ),
      );
    }

    // 6. Retouch (Active Indicator)
    final isRetouched =
        _brightness.value != 100 ||
        _contrast.value != 100 ||
        _saturation.value != 100 ||
        _temperature.value != 0 ||
        _tint.value != 0 ||
        _vignette.value != 0 ||
        _selectedSkinTexture.id != 'soft'; // Assuming 'soft' is default

    if (isRetouched) {
      items.add(
        _buildStackChip(
          Icons.auto_fix_high,
          'Retouched',
          onTap: () => setState(() => _activeControl = 'retouch'),
          isActive: true,
          highlightColor: AppColors.matteGold,
        ),
      );
    }

    if (items.isEmpty) return SizedBox.shrink();

    return Container(
      height: 44,
      margin: EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }

  Widget _buildStackChip(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool isActive = false,
    Color? highlightColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.softPlatinum.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                highlightColor ??
                (isActive
                    ? AppColors.matteGold.withValues(alpha: 0.5)
                    : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: highlightColor ?? AppColors.matteGold),
            SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.microBold(
                color: highlightColor ?? AppColors.softPlatinum,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyTypeSelector(SessionProvider session, bool isEnterprise) {
    // Body Types Map - Simple & Tasteful Icons (Verified clean)
    final List<Map<String, dynamic>> bodyTypes = [
      {'label': 'Skinny', 'icon': Icons.person_outline},
      {'label': 'Toned', 'icon': Icons.accessibility_new},
      {'label': 'Fit', 'icon': Icons.person},
      {'label': 'Athletic', 'icon': Icons.directions_run},
      {
        'label': 'Built',
        'icon': Icons.person_add_alt_1,
      }, // Broad shouldered silhouette
      {'label': 'Strong Fat', 'icon': Icons.person_search}, // Solid silhouette
      {'label': 'Chubby', 'icon': Icons.person_3}, // Soft silhouette
    ];

    return Container(
      height: 95,
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "BODY TYPE",
              style: AppTypography.microBold(color: AppColors.coolGray),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: bodyTypes.length,
              separatorBuilder: (_, __) => SizedBox(width: 16),
              itemBuilder: (context, index) {
                final type = bodyTypes[index];
                final isSelected = session.selectedBodyType == type['label'];
                return GestureDetector(
                  onTap: () => session.setSelectedBodyType(type['label']),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.matteGold
                              : AppColors.softPlatinum.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.matteGold
                                : Colors.transparent,
                          ),
                        ),
                        child: Icon(
                          type['icon'],
                          size: 16,
                          color: isSelected
                              ? Colors.black
                              : AppColors.softPlatinum,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        type['label'],
                        style: AppTypography.micro(
                          color: isSelected
                              ? AppColors.matteGold
                              : AppColors.mutedGray,
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToolbar() {
    final session = context.watch<SessionProvider>();
    final isEnterprise = session.isEnterpriseMode;
    return Column(
      children: [
        SizedBox(height: 12),
        _buildSelectionStack(session),

        // Control Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              _buildControlButton(
                icon: Icons.edit_note_outlined,
                label: _customPrompt.isEmpty ? 'STYLE CLOSET' : 'STYLED',
                onTap: () => setState(() => _activeControl = 'prompt'),
              ),
              _buildDivider(),
              _buildControlButton(
                icon: _gender == 'female'
                    ? Icons.female
                    : (_gender == 'male' ? Icons.male : Icons.person_outline),
                label: _gender.toUpperCase(),
                onTap: () {
                  final session = context.read<SessionProvider>();
                  setState(() {
                    if (_gender == 'female')
                      _gender = 'male';
                    else if (_gender == 'male')
                      _gender = 'unspecified';
                    else
                      _gender = 'female';
                    session.setSoloGender(_gender);
                  });
                },
              ),
              SizedBox(width: 8),
              _buildGenerateButton(session),
            ],
          ),
        ),

        // Body Type Selector (New Feature)
        _buildBodyTypeSelector(session, isEnterprise),

        // Post-Generation Tools Row
        if (session.results.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.softPlatinum.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isEnterprise) ...[
                  _buildToolIcon(Icons.groups_3_outlined, 'Team Gen', 'stitch'),
                  _buildToolIcon(
                    Icons.palette_outlined,
                    'Brand Match',
                    'style',
                  ),
                  _buildToolIcon(Icons.layers_outlined, 'Batch', 'batch'),
                  _buildToolIcon(Icons.auto_fix_high, 'Retouch', 'retouch'),
                  _buildToolIcon(Icons.download_outlined, 'Export', 'download'),
                  _buildToolIcon(Icons.share_outlined, 'Share', 'share'),
                ] else ...[
                  _buildToolIcon(Icons.style_outlined, 'Style', 'style'),
                  _buildToolIcon(Icons.auto_fix_high, 'Retouch', 'retouch'),
                  _buildToolIcon(Icons.merge_type, 'Stitch', 'stitch'),
                  _buildToolIcon(Icons.print_outlined, 'Print', 'print'),
                  _buildToolIcon(Icons.download_outlined, 'Save', 'download'),
                  _buildToolIcon(Icons.share_outlined, 'Share', 'share'),
                ],
              ],
            ),
          ),
        Divider(
          color: AppColors.softPlatinum.withValues(alpha: 0.12),
          height: 1,
        ),
        // Recent results thumbnail strip
        if (session.results.isNotEmpty)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.all(12),
              itemCount: session.results.length,
              itemBuilder: (context, index) {
                final result = session.results[index];
                final isSelected = _focusedResult?.id == result.id;
                // STAGGERED ENTRY
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 50)),
                  curve: AppMotion.cinematic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedResult = result;
                      });
                      _decodeFocusedImage();
                    },
                    child: Container(
                      width: 80,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(color: AppColors.matteGold, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: result.imageUrl.startsWith('data:')
                            ? Image.memory(
                                base64Decode(result.imageUrl.split(',')[1]),
                                fit: BoxFit
                                    .contain, // Changed from cover to contain
                                gaplessPlayback: true,
                              )
                            : Image.network(
                                result.imageUrl,
                                fit: BoxFit.contain,
                              ), // Changed from cover to contain
                      ),
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

        if (!session.canAccessFeature(controlKey)) {
          _showUpgradeDialog(label);
          return;
        }

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
          Icon(icon, color: AppColors.coolGray, size: 20),
          SizedBox(height: 4),
          Text(label, style: AppTypography.micro(color: AppColors.mutedGray)),
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
                        color: AppColors.matteGold.withValues(alpha: 0.3),
                      ),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.matteGold.withValues(alpha: 0.05),
                        AppColors.matteGold.withValues(alpha: 0.12),
                        AppColors.matteGold.withValues(alpha: 0.05),
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
                  session.setSelectedRig(cameraRigs[index]);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: cameraRigs.length,
                  builder: (context, index) {
                    final rig = cameraRigs[index];
                    final isSelected = session.selectedRig?.id == rig.id;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Camera icon
                          Text(
                            rig.icon,
                            style: TextStyle(fontSize: isSelected ? 22 : 16),
                          ),
                          SizedBox(width: 14),
                          // Name + specs subtitle
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rig.name,
                                  style: AppTypography.bodyMedium(
                                    color: isSelected
                                        ? AppColors.matteGold
                                        : AppColors.coolGray,
                                  ),
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${rig.specs.lens}  •  ${rig.specs.sensor}',
                                      style: AppTypography.micro(
                                        color: AppColors.softPlatinum
                                            .withValues(alpha: 0.35),
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
                              decoration: BoxDecoration(
                                color: AppColors.matteGold,
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
    final session = context.watch<SessionProvider>();
    return Column(
      children: [
        _buildPickerHeader(
          'BACKDROP',
          () => setState(() => _activeControl = 'main'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CUSTOM BACKDROP UPLOAD
                Text(
                  'CUSTOM BACKDROP',
                  style: TextStyle(
                    color: AppColors.softPlatinum.withValues(alpha: 0.24),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickBackgroundReference,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.softPlatinum.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.softPlatinum.withValues(alpha: 0.1),
                      ),
                    ),
                    child: session.hasBackgroundReference
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  session.backgroundReferenceBytes!,
                                  width: double.infinity,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    session.clearBackgroundReference();
                                    setState(() {
                                      _customBgPrompt = '';
                                      _bgPromptController.text = '';
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.softPlatinum,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    session.backgroundReferenceName!,
                                    style: AppTypography.micro(
                                      color: AppColors.softPlatinum,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.matteGold,
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'UPLOAD CUSTOM BACKDROP',
                                style: AppTypography.microBold(
                                  color: AppColors.matteGold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 20),

                // ENVIRONMENT TIPS (Moved from Prompt tab)
                Text(
                  'ENVIRONMENT & LOCATIONS',
                  style: TextStyle(
                    color: AppColors.softPlatinum.withValues(alpha: 0.24),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                ...environmentPromptTips.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: AppTypography.microBold(
                            color: AppColors.softPlatinum.withValues(
                              alpha: 0.3,
                            ),
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
                                    null; // Clear preset selection
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Color(0xFFD4AF37).withValues(alpha: 0.15)
                                    : AppColors.softPlatinum.withValues(
                                        alpha: 0.05,
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.matteGold
                                      : AppColors.softPlatinum.withValues(
                                          alpha: 0.12,
                                        ),
                                ),
                              ),
                              child: Text(
                                tip,
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.matteGold
                                      : AppColors.coolGray,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                }),

                // EDITORIAL BACKDROPS (Converted from Wheel)
                Text(
                  'EDITORIAL BACKDROPS',
                  style: TextStyle(
                    color: AppColors.softPlatinum.withValues(alpha: 0.24),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                ...backgroundPresets.map((cat) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          cat.category.toUpperCase(),
                          style: AppTypography.microBold(
                            color: AppColors.softPlatinum.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cat.items.map((preset) {
                          final isActive = _selectedBackdrop?.id == preset.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBackdrop = preset;
                                _customBgPrompt = preset.name;
                                _bgPromptController.text = preset.name;
                              });
                            },
                            child: Container(
                              width:
                                  (MediaQuery.of(context).size.width - 48) /
                                  2, // 2 column grid
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.matteGold.withValues(alpha: 0.1)
                                    : AppColors.softPlatinum.withValues(
                                        alpha: 0.03,
                                      ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.matteGold
                                      : AppColors.softPlatinum.withValues(
                                          alpha: 0.1,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      preset.url,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      preset.name,
                                      style: AppTypography.micro(
                                        color: isActive
                                            ? AppColors.matteGold
                                            : AppColors.softPlatinum,
                                      ).copyWith(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                }),
                SizedBox(height: 100), // Bottom safety
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptToInline() {
    final session = context.watch<SessionProvider>();
    return Column(
      children: [
        _buildPickerHeader(
          'STYLE CLOSET',
          () => setState(() => _activeControl = 'main'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CUSTOM OUTFIT UPLOAD
                Text(
                  'CUSTOM OUTFIT',
                  style: TextStyle(
                    color: AppColors.softPlatinum.withValues(alpha: 0.24),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickClothingReference,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.softPlatinum.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.softPlatinum.withValues(alpha: 0.1),
                      ),
                    ),
                    child: session.hasClothingReference
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  session.clothingReferenceBytes!,
                                  width: double.infinity,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => session.clearClothingReference(),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.softPlatinum,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.matteGold,
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'UPLOAD CLOTHING REFERENCE',
                                style: AppTypography.microBold(
                                  color: AppColors.matteGold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 16),
                _buildCampusStudio(session),
                // Text input
                // Text input
                TextField(
                  controller: _promptController,
                  style: AppTypography.bodyRegular(),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Describe your vision...',
                    hintStyle: TextStyle(
                      color: AppColors.softPlatinum.withValues(alpha: 0.24),
                    ),
                    filled: true,
                    fillColor: AppColors.softPlatinum.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.softPlatinum.withValues(alpha: 0.12),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.softPlatinum.withValues(alpha: 0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.matteGold),
                    ),
                    contentPadding: EdgeInsets.all(14),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mic (Functional STT)
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? AppColors.matteGold
                                : AppColors.mutedGray,
                            size: 20,
                          ),
                          onPressed: _listen,
                        ),
                        // Enhance (Live — calls GeminiService.enhancePrompt)
                        IconButton(
                          icon: Icon(
                            Icons.auto_fix_high,
                            color: AppColors.matteGold,
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
                                    backgroundColor: AppColors.matteGold,
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
                            icon: Icon(
                              Icons.close,
                              color: AppColors.mutedGray,
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
                SizedBox(height: 14),
                // Framing mode chips
                Text(
                  'FRAMING',
                  style: TextStyle(
                    color: AppColors.softPlatinum.withValues(alpha: 0.24),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.matteGold
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.matteGold
                                    : AppColors.softPlatinum.withValues(
                                        alpha: 0.24,
                                      ),
                              ),
                            ),
                            child: Text(
                              item['label']!,
                              style: AppTypography.smallSemiBold(
                                color: isActive
                                    ? Colors.black
                                    : AppColors.coolGray,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                SizedBox(height: 14),
                // AI Prompt Presets (from promptCategories)
                ...promptCategories.entries.map((entry) {
                  final dynamic value = entry.value;

                  if (value is Map<String, List<String>>) {
                    // NESTED STRUCTURE (e.g., Styling & Vibe, Your School)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: AppTypography.microBold(
                            color: AppColors.softPlatinum.withValues(
                              alpha: 0.24,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        ...value.entries.map((subEntry) {
                          return Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Text(
                                subEntry.key,
                                style: AppTypography.smallSemiBold(
                                  color: AppColors.matteGold,
                                ),
                              ),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.only(bottom: 12),
                              iconColor: AppColors.matteGold,
                              collapsedIconColor: AppColors.mutedGray,
                              children: [
                                if (entry.key == 'Your School') ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    child: TextField(
                                      onChanged: (val) => setState(
                                        () => _selectedSchoolQuery = val,
                                      ),
                                      style: AppTypography.small(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search University...',
                                        hintStyle: TextStyle(
                                          color: Colors.white24,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color: AppColors.matteGold,
                                          size: 18,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children:
                                      (entry.key == 'Your School'
                                              ? universities
                                                    .where(
                                                      (u) => u
                                                          .toLowerCase()
                                                          .contains(
                                                            _selectedSchoolQuery
                                                                .toLowerCase(),
                                                          ),
                                                    )
                                                    .take(8)
                                                    .map((u) => '$u Jacket')
                                                    .toList()
                                              : subEntry.value)
                                          .map((preset) {
                                            final isActive =
                                                _customPrompt == preset;
                                            return GestureDetector(
                                              onTap: () {
                                                _promptController.text = preset;
                                                setState(
                                                  () => _customPrompt = preset,
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? Color(
                                                          0xFFD4AF37,
                                                        ).withValues(
                                                          alpha: 0.15,
                                                        )
                                                      : AppColors.softPlatinum
                                                            .withValues(
                                                              alpha: 0.05,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: isActive
                                                        ? AppColors.matteGold
                                                        : AppColors.softPlatinum
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                  ),
                                                ),
                                                child: Text(
                                                  preset,
                                                  style: TextStyle(
                                                    color: isActive
                                                        ? AppColors.matteGold
                                                        : AppColors.coolGray,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(height: 12),
                      ],
                    );
                  } else if (value is List<String>) {
                    // FLAT STRUCTURE
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: AppTypography.microBold(
                            color: AppColors.softPlatinum.withValues(
                              alpha: 0.24,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: value.map((preset) {
                            final isActive = _customPrompt == preset;
                            return GestureDetector(
                              onTap: () {
                                _promptController.text = preset;
                                setState(() => _customPrompt = preset);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Color(
                                          0xFFD4AF37,
                                        ).withValues(alpha: 0.15)
                                      : AppColors.softPlatinum.withValues(
                                          alpha: 0.05,
                                        ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.matteGold
                                        : AppColors.softPlatinum.withValues(
                                            alpha: 0.12,
                                          ),
                                  ),
                                ),
                                child: Text(
                                  preset,
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.matteGold
                                        : AppColors.coolGray,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                SizedBox(height: 6),
                SizedBox(height: 14),
                // Skin texture selector
                Text(
                  'SKIN ARCHITECTURE',
                  style: TextStyle(
                    color: AppColors.softPlatinum.withValues(alpha: 0.24),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
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
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.matteGold.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.matteGold
                                  : AppColors.softPlatinum.withValues(
                                      alpha: 0.24,
                                    ),
                            ),
                          ),
                          child: Text(
                            tex.label,
                            style: AppTypography.smallSemiBold(
                              color: isActive
                                  ? AppColors.matteGold
                                  : AppColors.coolGray,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 100), // Bottom safety padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerHeader(String title, VoidCallback onClose) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.softPlatinum.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.smallSemiBold(
                  color: AppColors.matteGold,
                ).copyWith(letterSpacing: 2),
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, color: AppColors.softPlatinum),
              ),
            ],
          ),
        ),
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
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.matteGold, size: 22),
              SizedBox(height: 4),
              Text(
                label.length > 10 ? '${label.substring(0, 10)}...' : label,
                style: AppTypography.micro(color: AppColors.coolGray),
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
      color: AppColors.softPlatinum.withValues(alpha: 0.1),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: session.isGenerating
              ? null
              : LinearGradient(
                  colors: [AppColors.matteGold, Color(0xFFB8860B)],
                ),
          color: session.isGenerating
              ? AppColors.softPlatinum.withValues(alpha: 0.12)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: session.isGenerating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.matteGold,
                ),
              )
            : Icon(Icons.auto_awesome, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Thin luxury loader
          Container(
            width: 200,
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.matteGold),
            ),
          ),
          SizedBox(height: 30),
          Text(
            'INITIATING OPTIC PROTOCOL...',
            style: AppTypography.microBold(color: AppColors.softPlatinum),
          ),
          SizedBox(height: 10),
          Text(
            'Developing high-fidelity asset...',
            style: AppTypography.small(
              color: AppColors.softPlatinum.withValues(alpha: 0.3),
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

      return Stack(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.softPlatinum.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ValueListenableBuilder<double>(
                  valueListenable: _brightness,
                  builder: (context, bVal, _) => ValueListenableBuilder<double>(
                    valueListenable: _contrast,
                    builder: (context, cVal, _) =>
                        ValueListenableBuilder<double>(
                          valueListenable: _saturation,
                          builder: (context, sVal, _) {
                            // Recalculate matrices within builder for reactivity
                            double b = (bVal - 100) * 1.5;
                            final bMat = <double>[
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

                            double c = cVal / 100.0;
                            double t = 128 * (1 - c);
                            final cMat = <double>[
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

                            double s = sVal / 100.0;
                            double lumR = 0.2126;
                            double lumG = 0.7152;
                            double lumB = 0.0722;
                            double oneMinusS = 1 - s;
                            final sMat = <double>[
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

                            return ColorFiltered(
                              colorFilter: ColorFilter.matrix(bMat),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.matrix(cMat),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(sMat),
                                  child: Image.memory(
                                    session.uploadedImageBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
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
            color: AppColors.softPlatinum.withValues(alpha: 0.1),
          ),
          SizedBox(height: 20),
          Text(
            'No assets yet',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Configure your scene and tap generate',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.12),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ADJUSTMENTS OVERLAY (Pre-generation)
  // ═══════════════════════════════════════════════════════════

  Widget _buildAdjustmentsOverlay() {
    final session = context.read<SessionProvider>();
    final tags = <String>[];
    if (_brightness.value != 100)
      tags.add('Brightness ${_brightness.value.toInt()}%');
    if (_contrast.value != 100)
      tags.add('Contrast ${_contrast.value.toInt()}%');
    if (_saturation.value != 100)
      tags.add('Saturation ${_saturation.value.toInt()}%');
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

    if (session.hasBackgroundReference) tags.add('Custom BG Active');
    if (session.hasClothingReference) tags.add('Custom Wardrobe Active');

    // Stitch specific tags
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.matteGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: AppColors.coolGray,
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

    // Wardrobe Logic
    final genderKey = _gender == 'male' ? 'Male' : 'Female';
    final wardrobeMap = wardrobePresets[genderKey] ?? {};
    final wardrobeCategories = wardrobeMap.keys.toList()..sort();

    // Ensure selected category is valid
    if (!wardrobeMap.containsKey(_selectedWardrobeCategory) &&
        wardrobeCategories.isNotEmpty) {
      if (_selectedWardrobeCategory.isNotEmpty &&
          wardrobeCategories.contains('Classic')) {
        _selectedWardrobeCategory = 'Classic';
      } else if (wardrobeCategories.isNotEmpty) {
        _selectedWardrobeCategory = wardrobeCategories.first;
      }
    }

    final wardrobeItems = wardrobeMap[_selectedWardrobeCategory] ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. IDENTITY PROTOCOL
          Text(
            'IDENTITY PROTOCOL',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.softPlatinum.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.softPlatinum.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRESERVE AGE & BODY',
                      style: AppTypography.microBold(
                        color: AppColors.matteGold,
                      ),
                    ),
                    Text(
                      'Locks age and body type',
                      style: AppTypography.micro(color: AppColors.mutedGray),
                    ),
                  ],
                ),
                Switch(
                  value: session.preserveAgeAndBody,
                  onChanged: (val) => session.setPreserveAgeAndBody(val),
                  activeColor: AppColors.matteGold,
                  activeTrackColor: AppColors.matteGold.withValues(alpha: 0.3),
                  inactiveThumbColor: AppColors.softPlatinum.withValues(
                    alpha: 0.24,
                  ),
                  inactiveTrackColor: AppColors.softPlatinum.withValues(
                    alpha: 0.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // 1. GENDER
          Text(
            'TARGET GENDER',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['female', 'male', 'unspecified'].map((g) {
              final isActive = _gender == g;
              return GestureDetector(
                onTap: () {
                  setState(() => _gender = g);
                  session.setSoloGender(g);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.matteGold.withValues(alpha: 0.15)
                        : AppColors.softPlatinum.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? AppColors.matteGold
                          : AppColors.softPlatinum.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    g.toUpperCase(),
                    style: AppTypography.microBold(
                      color: isActive
                          ? AppColors.matteGold
                          : AppColors.coolGray,
                    ).copyWith(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24),

          // WARDROBE COLLECTIONS
          Text(
            'WARDROBE COLLECTIONS',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: wardrobeCategories.map((cat) {
                final isActive = _selectedWardrobeCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: AppTypography.small(
                        color: isActive ? Colors.black : AppColors.coolGray,
                      ).copyWith(fontSize: 11),
                    ),
                    selected: isActive,
                    selectedColor: AppColors.matteGold,
                    backgroundColor: AppColors.softPlatinum.withValues(
                      alpha: 0.1,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedWardrobeCategory = cat;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Search for "Your School" if selected
          if (_selectedWardrobeCategory == 'Your School') ...[
            TextField(
              onChanged: (val) => setState(() => _selectedSchoolQuery = val),
              style: AppTypography.small(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search University...',
                hintStyle: TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.search, color: AppColors.matteGold),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Wardrobe Items
          if (wardrobeItems.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: wardrobeItems
                  .where((item) {
                    if (_selectedWardrobeCategory == 'Your School') {
                      final query = _selectedSchoolQuery.toLowerCase();
                      return item.toLowerCase().contains(query);
                    }
                    return true;
                  })
                  .take(_selectedWardrobeCategory == 'Your School' ? 12 : 100)
                  .map((item) {
                    final isActive = _selectedClothingStyle == item;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedClothingStyle = isActive ? '' : item;
                      }),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 48) / 2,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.matteGold.withValues(alpha: 0.15)
                              : AppColors.softPlatinum.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? AppColors.matteGold
                                : AppColors.softPlatinum.withValues(
                                    alpha: 0.12,
                                  ),
                          ),
                        ),
                        child: Text(
                          item
                              .split(' vintage')
                              .first, // Shorter display for school
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.micro(
                            color: isActive
                                ? AppColors.matteGold
                                : AppColors.coolGray,
                          ).copyWith(fontSize: 10),
                        ),
                      ),
                    );
                  })
                  .toList(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No items found',
                  style: AppTypography.small(color: Colors.white24),
                ),
              ),
            ),

          SizedBox(height: 24),

          // 2. CLOTHING STYLE (Generals)
          Text(
            'GENERAL VIBES',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (clothingOptions is Map<String, List<String>>)
            ...clothingOptions.entries.map((entry) {
              return Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    entry.key,
                    style: AppTypography.smallSemiBold(
                      color: AppColors.matteGold,
                    ),
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.only(bottom: 12),
                  iconColor: AppColors.matteGold,
                  collapsedIconColor: AppColors.mutedGray,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((style) {
                        final isActive = _selectedClothingStyle == style;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedClothingStyle = isActive ? '' : style;
                          }),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.matteGold.withValues(alpha: 0.15)
                                  : AppColors.softPlatinum.withValues(
                                      alpha: 0.05,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.matteGold
                                    : AppColors.softPlatinum.withValues(
                                        alpha: 0.12,
                                      ),
                              ),
                            ),
                            child: Text(
                              style,
                              style: AppTypography.microBold(
                                color: isActive
                                    ? AppColors.matteGold
                                    : AppColors.coolGray,
                              ).copyWith(fontSize: 10),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList()
          else if (clothingOptions is List<String>)
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
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.matteGold.withValues(alpha: 0.15)
                          : AppColors.softPlatinum.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppColors.matteGold
                            : AppColors.softPlatinum.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      style,
                      style: AppTypography.microBold(
                        color: isActive
                            ? AppColors.matteGold
                            : AppColors.coolGray,
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 20),

          // 3. COLOR GRADING
          Text(
            'COLOR GRADING',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['neutral', 'warm', 'cool'].map((s) {
              final isActive = _styleTemperature == s;
              return GestureDetector(
                onTap: () => setState(() => _styleTemperature = s),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.matteGold.withValues(alpha: 0.15)
                        : AppColors.softPlatinum.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? AppColors.matteGold
                          : AppColors.softPlatinum.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    s.toUpperCase(),
                    style: AppTypography.microBold(
                      color: isActive
                          ? AppColors.matteGold
                          : AppColors.coolGray,
                    ).copyWith(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24),

          // 4. CUSTOM WARDROBE soul
          Text(
            'CUSTOM WARDROBE',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softPlatinum.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.softPlatinum.withValues(alpha: 0.1),
              ),
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
                        icon: Icon(Icons.cancel, color: AppColors.softPlatinum),
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
                          color: AppColors.matteGold,
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.matteGold,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "ADD CLOTHING PHOTO",
                            style: AppTypography.microBold(
                              color: AppColors.matteGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 8),
                Text(
                  "Upload a photo of a garment to apply it to your generation.",
                  textAlign: TextAlign.center,
                  style: AppTypography.micro(
                    color: AppColors.mutedGray,
                  ).copyWith(fontSize: 9),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // APPLY STYLE — triggers regeneration
          Consumer<SessionProvider>(
            builder: (context, session, child) {
              return SizedBox(
                width: double.infinity,
                child: PremiumButton(
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
                  isLoading: session.isGenerating,
                  child: Text('APPLY STYLE'),
                ),
              );
            },
          ),
          SizedBox(height: 120), // Bottom safety padding
        ],
      ),
    );
  }

  Widget _buildRetouchDrawer() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SKIN TEXTURE (Synced with constants)
          Text(
            'SKIN ARCHITECTURE',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skinTextures.map((tex) {
              final isActive = _selectedSkinTexture.id == tex.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedSkinTexture = tex),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.matteGold.withValues(alpha: 0.15)
                        : AppColors.softPlatinum.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? AppColors.matteGold
                          : AppColors.softPlatinum.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    tex.label,
                    style: AppTypography.microBold(
                      color: isActive
                          ? AppColors.matteGold
                          : AppColors.coolGray,
                    ).copyWith(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),

          // FILTERS
          Text(
            'FILTERS',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: retouchPresets.map((preset) {
              final isMatch =
                  _brightness.value == preset.brightness &&
                  _contrast.value == preset.contrast &&
                  _saturation.value == preset.saturation &&
                  _temperature.value == preset.temperature &&
                  _tint.value == preset.tint &&
                  _vignette.value == preset.vignette;

              return GestureDetector(
                onTap: () {
                  _brightness.value = preset.brightness;
                  _contrast.value = preset.contrast;
                  _saturation.value = preset.saturation;
                  _temperature.value = preset.temperature;
                  _tint.value = preset.tint;
                  _vignette.value = preset.vignette;
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMatch
                        ? AppColors.matteGold.withValues(alpha: 0.15)
                        : AppColors.softPlatinum.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMatch
                          ? AppColors.matteGold
                          : AppColors.softPlatinum.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    preset.label,
                    style: AppTypography.microBold(
                      color: isMatch ? AppColors.matteGold : AppColors.coolGray,
                    ).copyWith(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),

          // SLIDERS SECTIONS
          _buildDivider(),

          // COLOR BALANCE
          Text(
            'COLOR BALANCE',
            style: AppTypography.microBold(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
            ),
          ),
          SizedBox(height: 12),
          _buildSlider(
            'TEMPERATURE',
            _temperature,
            min: -1.0,
            max: 1.0,
            isPercentage: false,
          ),
          _buildSlider('TINT', _tint, min: -1.0, max: 1.0, isPercentage: false),

          SizedBox(height: 12),

          // EFFECTS
          Text(
            'EFFECTS',
            style: AppTypography.microBold(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
            ),
          ),
          SizedBox(height: 12),
          _buildSlider(
            'VIGNETTE',
            _vignette,
            min: 0.0,
            max: 1.0,
            isPercentage: true,
          ),

          SizedBox(height: 12),

          // FINE TUNE
          Text(
            'FINE TUNE',
            style: AppTypography.microBold(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
            ),
          ),
          SizedBox(height: 12),
          _buildSlider('BRIGHTNESS', _brightness, min: 0, max: 200),
          _buildSlider('CONTRAST', _contrast, min: 0, max: 200),
          _buildSlider('SATURATION', _saturation, min: 0, max: 200),

          SizedBox(height: 24),

          // APPLY RETOUCH
          Consumer<SessionProvider>(
            builder: (context, session, child) {
              return SizedBox(
                width: double.infinity,
                child: PremiumButton(
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
                  isLoading: session.isGenerating,
                  child: Text('APPLY RETOUCH'),
                ),
              );
            },
          ),
          SizedBox(height: 120), // Bottom safety padding
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    ValueNotifier<double> notifier, {
    double min = 0,
    double max = 200,
    bool isPercentage = true,
  }) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (context, value, _) {
        String valueText;
        if (isPercentage) {
          valueText = '${(value * (max == 1.0 ? 100 : 1)).toInt()}%';
        } else {
          valueText = value.toStringAsFixed(1);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(color: AppColors.coolGray, fontSize: 10),
                ),
                Text(
                  valueText,
                  style: AppTypography.micro(color: AppColors.matteGold),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.matteGold,
                inactiveTrackColor: AppColors.softPlatinum.withValues(
                  alpha: 0.1,
                ),
                thumbColor: AppColors.matteGold,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: (v) => notifier.value = v,
              ),
            ),
            SizedBox(height: 8),
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
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        120,
      ), // Increased bottom padding to clear footer
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. GROUP TYPE ──
          Text(
            'GROUP TYPE',
            style: TextStyle(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
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
                padding: EdgeInsets.symmetric(horizontal: 4),
                separatorBuilder: (_, __) => SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final type = groupTypes[index];
                  final isActive = _selectedGroupType == type;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedGroupType = isActive ? '' : type;
                      _selectedGroupStyle = '';
                    }),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.matteGold
                            : AppColors.softPlatinum.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: isActive
                              ? AppColors.matteGold
                              : AppColors.softPlatinum.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? Colors.black : AppColors.coolGray,
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
            SizedBox(height: 14),
            Text(
              '${_selectedGroupType.toUpperCase()} STYLES',
              style: TextStyle(
                color: AppColors.softPlatinum.withValues(alpha: 0.24),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
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
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.matteGold.withValues(alpha: 0.15)
                          : AppColors.softPlatinum.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? AppColors.matteGold
                            : AppColors.softPlatinum.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      style.split(',').first.toUpperCase(),
                      style: TextStyle(
                        color: isActive
                            ? AppColors.matteGold
                            : AppColors.mutedGray,
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

          SizedBox(height: 16),
          Divider(
            color: AppColors.softPlatinum.withValues(alpha: 0.1),
            height: 1,
          ),
          SizedBox(height: 12),

          // ── 3. STITCH PROMPT ──
          Text(
            'GROUP PROMPT',
            style: AppTypography.microBold(
              color: AppColors.softPlatinum.withValues(alpha: 0.24),
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.softPlatinum.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.softPlatinum.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stitchPromptController,
                    style: AppTypography.micro(color: AppColors.softPlatinum),
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Add scene details, mood, location...',
                      hintStyle: TextStyle(
                        color: AppColors.softPlatinum.withValues(alpha: 0.24),
                        fontSize: 11,
                      ),
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
                  icon: Icon(
                    Icons.auto_fix_high,
                    color: AppColors.matteGold,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
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
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.softPlatinum.withValues(alpha: 0.24),
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () =>
                        setState(() => _stitchPromptController.clear()),
                  ),
              ],
            ),
          ),

          SizedBox(height: 16),
          Divider(
            color: AppColors.softPlatinum.withValues(alpha: 0.1),
            height: 1,
          ),
          SizedBox(height: 12),

          // ── 4. SQUAD SELECTOR ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STITCH SQUAD (${session.stitchImages.length}/5)',
                style: AppTypography.microBold(
                  color: AppColors.softPlatinum.withValues(alpha: 0.24),
                ),
              ),
              if (session.stitchImages.isNotEmpty)
                Text(
                  'TAP TO REMOVE',
                  style: AppTypography.micro(
                    color: AppColors.softPlatinum.withValues(alpha: 0.12),
                  ).copyWith(fontSize: 8),
                ),
            ],
          ),
          SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
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
                padding: EdgeInsets.symmetric(horizontal: 4),
                children: [
                  if (session.stitchImages.length < 5) ...[
                    // 1. ADD FROM LOCAL GALLERY
                    GestureDetector(
                      onTap: () => _pickStitchImage(session),
                      child: Container(
                        width: 60,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.matteGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.matteGold),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Color(0xFFD4AF37), size: 20),
                            SizedBox(height: 2),
                            Text(
                              'ADD',
                              style: AppTypography.microBold(
                                color: Color(0xFFD4AF37),
                              ).copyWith(fontSize: 7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 2. ADD FROM IN-APP GENERATIONS
                    GestureDetector(
                      onTap: () => _showResultsPicker(session),
                      child: Container(
                        width: 60,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.softPlatinum.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.softPlatinum.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.softPlatinum,
                              size: 18,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'GALLERY',
                              style: AppTypography.microBold(
                                color: AppColors.softPlatinum,
                              ).copyWith(fontSize: 7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 3. ADD FROM SELFIES (IDENTITY LOCK)
                    if (session.identityImages.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: AppColors.softCharcoal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'SELECT SELFIE',
                                      style: AppTypography.microBold(
                                        color: AppColors.matteGold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 120,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: session.identityImages.length,
                                      itemBuilder: (context, idx) {
                                        return GestureDetector(
                                          onTap: () {
                                            session.addStitchImage(
                                              session.identityImages[idx],
                                            );
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            width: 100,
                                            margin: EdgeInsets.only(right: 12),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.softPlatinum
                                                    .withValues(alpha: 0.1),
                                              ),
                                              image: DecorationImage(
                                                image: MemoryImage(
                                                  session.identityImages[idx],
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 60,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.softPlatinum.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.softPlatinum.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_pin_outlined,
                                color: AppColors.softPlatinum,
                                size: 18,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'SELFIES',
                                style: AppTypography.microBold(
                                  color: AppColors.softPlatinum,
                                ).copyWith(fontSize: 7),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  ...session.stitchImages.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 60,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: MemoryImage(entry.value.bytes),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(
                              color: AppColors.softPlatinum.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => session.removeStitchImage(entry.key),
                            child: Container(
                              padding: EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 10,
                                color: AppColors.softPlatinum,
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
            SizedBox(height: 12),
            Text(
              'PER-PERSON STYLE',
              style: AppTypography.microBold(
                color: AppColors.softPlatinum.withValues(alpha: 0.24),
              ),
            ),
            SizedBox(height: 6),
            ...session.stitchImages.asMap().entries.map((entry) {
              final idx = entry.key;
              final subject = entry.value;
              final currentStyle = _stitchPersonStyles[idx] ?? '';
              final styleMap =
                  promptCategories['Styling & Vibe'] as Map<String, dynamic>;
              final List<String> allStyles = [];
              styleMap.values.forEach((val) {
                if (val is List) allStyles.addAll(val.cast<String>());
              });

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softPlatinum.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.softPlatinum.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            subject.bytes,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'P${idx + 1}',
                          style: AppTypography.microBold(
                            color: AppColors.softPlatinum,
                          ),
                        ),
                        const Spacer(),
                        // Gender Toggle
                        Row(
                          children: ['female', 'male'].map((g) {
                            final isGActive = subject.gender == g;
                            return GestureDetector(
                              onTap: () => session.updateStitchGender(idx, g),
                              child: Container(
                                margin: EdgeInsets.only(left: 6),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isGActive
                                      ? AppColors.matteGold
                                      : AppColors.softPlatinum.withValues(
                                          alpha: 0.08,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isGActive
                                        ? AppColors.matteGold
                                        : AppColors.softPlatinum.withValues(
                                            alpha: 0.1,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      g == 'female' ? Icons.female : Icons.male,
                                      size: 10,
                                      color: isGActive
                                          ? Colors.black
                                          : AppColors.coolGray,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      g.toUpperCase(),
                                      style: AppTypography.microBold(
                                        color: isGActive
                                            ? Colors.black
                                            : AppColors.coolGray,
                                      ).copyWith(fontSize: 8),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
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
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                children: allStyles.map((style) {
                                  final isActive = currentStyle == style;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _stitchPersonStyles[idx] = isActive
                                          ? ''
                                          : style;
                                    }),
                                    child: Container(
                                      margin: EdgeInsets.only(right: 4),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Color(
                                                0xFFD4AF37,
                                              ).withValues(alpha: 0.1)
                                            : AppColors.softPlatinum.withValues(
                                                alpha: 0.05,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isActive
                                              ? AppColors.matteGold
                                              : AppColors.softPlatinum
                                                    .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Text(
                                        style.toUpperCase(),
                                        style: AppTypography.microBold(
                                          color: isActive
                                              ? AppColors.matteGold
                                              : AppColors.mutedGray,
                                        ).copyWith(fontSize: 8),
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
                  ],
                ),
              );
            }),
          ],

          SizedBox(height: 12),

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
              SizedBox(width: 8),
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

          SizedBox(height: 16),

          // ── 7. GENERATE ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: session.isGenerating
                  ? null
                  : () => _generateStitch(session),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.matteGold,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: session.isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text('GENERATE GROUP PHOTO', style: AppTypography.button()),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultsPicker(SessionProvider session) {
    if (session.results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No generated images yet! Try creating some first.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.softCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'PICK SUBJECT FROM RESULTS',
                style: AppTypography.microBold(color: AppColors.matteGold),
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: session.results.length,
                itemBuilder: (context, idx) {
                  final result = session.results[idx];
                  if (result.mediaType != 'image')
                    return const SizedBox.shrink();

                  return GestureDetector(
                    onTap: () {
                      if (result.imageUrl.startsWith('data:')) {
                        try {
                          final base64String = result.imageUrl.split(',')[1];
                          final bytes = base64Decode(base64String);
                          session.addStitchImage(bytes);
                          Navigator.pop(context);
                        } catch (e) {
                          debugPrint("Error adding result to stitch: $e");
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Only local/cached results can be added currently.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.softPlatinum.withValues(alpha: 0.1),
                        ),
                        image: DecorationImage(
                          image: result.imageUrl.startsWith('data:')
                              ? MemoryImage(
                                  base64Decode(result.imageUrl.split(',')[1]),
                                )
                              : NetworkImage(result.imageUrl) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeChip(String label, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.matteGold.withValues(alpha: 0.15)
            : AppColors.softPlatinum.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppColors.matteGold
              : AppColors.softPlatinum.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.microBold(
          color: isActive ? AppColors.matteGold : AppColors.coolGray,
        ).copyWith(fontSize: 10),
      ),
    );
  }

  Widget _buildPrintDrawer() {
    return ListView.builder(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 120),
      itemCount: printProducts.length,
      itemBuilder: (context, index) {
        final product = printProducts[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          dense: true,
          title: Text(
            product.name,
            style: AppTypography.smallSemiBold(
              color: AppColors.softPlatinum,
            ).copyWith(fontSize: 13),
          ),
          subtitle: Text(
            '${product.material} • FROM \$${product.price.toInt()}',
            style: AppTypography.micro(color: AppColors.coolGray),
          ),
          trailing: Icon(
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download, color: Color(0xFFD4AF37), size: 36),
            SizedBox(height: 12),
            Text(
              'Save to your device',
              style: AppTypography.small(
                color: AppColors.coolGray,
              ).copyWith(fontSize: 11),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDownloadOption('HIGH RES', 'PNG • 4K', _saveToGallery),
                SizedBox(width: 12),
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.matteGold.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.microBold(color: Color(0xFFD4AF37)),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.micro(
                color: AppColors.mutedGray,
              ).copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareDrawer() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, color: Color(0xFFD4AF37), size: 36),
            SizedBox(height: 12),
            Text(
              'Share your creation',
              style: AppTypography.small(
                color: AppColors.coolGray,
              ).copyWith(fontSize: 11),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShareOption(Icons.link, 'COPY LINK', _shareImage),
                SizedBox(width: 16),
                _buildShareOption(Icons.camera_alt, 'INSTAGRAM', _shareImage),
                SizedBox(width: 16),
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
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.softPlatinum.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(icon, color: AppColors.matteGold, size: 22),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.micro(
              color: AppColors.mutedGray,
            ).copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.midnightNavy,
        border: Border(
          top: BorderSide(
            color: AppColors.softPlatinum.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.grid_view_rounded, 'GALLERY', true, () {}),
          _buildNavIcon(Icons.diamond_outlined, 'BRAND', false, () {
            Navigator.pushNamed(context, '/brand_studio');
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
            color: isActive
                ? AppColors.matteGold
                : AppColors.mutedGray.withValues(alpha: 0.5),
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.microBold(
              color: isActive
                  ? AppColors.matteGold
                  : AppColors.softPlatinum.withValues(alpha: 0.24),
            ).copyWith(fontSize: 9),
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

  Future<void> _pickBackgroundReference() async {
    final session = context.read<SessionProvider>();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      session.uploadBackgroundReference(bytes, image.name);
      setState(() {
        _customBgPrompt = "Custom Backdrop: ${image.name}";
        _bgPromptController.text = _customBgPrompt;
      });
    }
  }

  // === CAMPUS STUDIO METHODS ===

  Future<void> _searchSchools(String zip) async {
    if (zip.length < 5) return;
    setState(() => _isSearchingCampus = true);
    try {
      final result = await Process.run('python', [
        'execution/fetch_school_data.py',
        'list',
        zip,
      ]);
      if (result.exitCode == 0) {
        setState(() {
          _campusResults = jsonDecode(result.stdout);
          _isSearchingCampus = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isSearchingCampus = false);
    }
  }

  Future<void> _identifySchool(String schoolName) async {
    final session = context.read<SessionProvider>();
    setState(() => _isIdentifyingCampus = true);
    try {
      final result = await Process.run('python', [
        'execution/fetch_school_data.py',
        'identity',
        schoolName,
      ]);
      if (result.exitCode == 0) {
        final data = jsonDecode(result.stdout);
        session.setCampus(
          SchoolCampus(
            name: data['name'],
            colors: List<String>.from(data['colors']),
            logoUrl: data['logo_url'],
          ),
        );

        // Fetch logo bytes if URL exists
        if (data['logo_url'] != null) {
          try {
            final logoResponse = await http.get(Uri.parse(data['logo_url']));
            if (logoResponse.statusCode == 200) {
              session.uploadCampusLogo(logoResponse.bodyBytes);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Identity error: $e');
    } finally {
      setState(() => _isIdentifyingCampus = false);
    }
  }

  Future<void> _pickManualCampusLogo() async {
    final session = context.read<SessionProvider>();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      session.uploadCampusLogo(bytes);
    }
  }

  Widget _buildCampusStudio(SessionProvider session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAMPUS STUDIO™',
          style: AppTypography.microBold(color: AppColors.matteGold),
        ),
        SizedBox(height: 12),
        // Zip Entry
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.softPlatinum.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.softPlatinum.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.mutedGray,
                  size: 18,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _zipController,
                  style: AppTypography.bodyRegular(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter Zip Code',
                    hintStyle: AppTypography.bodyRegular(
                      color: AppColors.mutedGray,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    if (val.length == 5) _searchSchools(val);
                  },
                ),
              ),
              if (_isSearchingCampus)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.matteGold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_campusResults.isNotEmpty) ...[
          SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _campusResults.length,
              itemBuilder: (context, idx) {
                final school = _campusResults[idx];
                final isSelected =
                    session.selectedCampus?.name == school['name'];
                return GestureDetector(
                  onTap: () => _identifySchool(school['name']),
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.matteGold
                          : AppColors.softPlatinum.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.matteGold
                            : AppColors.softPlatinum.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      school['name'].toString().toUpperCase(),
                      style: AppTypography.microBold(
                        color: isSelected ? Colors.black : Colors.white,
                      ).copyWith(fontSize: 9),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (session.selectedCampus != null) ...[
          SizedBox(height: 16),
          _buildIdentityStatusCard(session),
        ],
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIdentityStatusCard(SessionProvider session) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softPlatinum.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softPlatinum.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              image: session.campusReferenceBytes != null
                  ? DecorationImage(
                      image: MemoryImage(session.campusReferenceBytes!),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: session.campusReferenceBytes == null
                ? Icon(Icons.school_outlined, color: AppColors.mutedGray)
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.selectedCampus!.name,
                  style: AppTypography.microBold(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: session.selectedCampus!.colors
                      .map(
                        (c) => Container(
                          width: 12,
                          height: 12,
                          margin: EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(c.replaceFirst('#', '0xFF')),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          if (_isIdentifyingCampus)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.matteGold,
              ),
            )
          else
            TextButton(
              onPressed: _pickManualCampusLogo,
              child: Text(
                'REFINE',
                style: AppTypography.microBold(
                  color: AppColors.matteGold,
                ).copyWith(fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generateCinematicVideo(
    SessionProvider session,
    GenerationResult sourceResult,
  ) async {
    if (session.isGenerating) return;

    if (!session.canAccessFeature('video')) {
      _showUpgradeDialog('Cinematic Video');
      return;
    }

    session.setGenerating(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Cinematic Video... (This may take 10-20s)'),
      ),
    );

    try {
      final service = GeminiService();
      String rawImage = sourceResult.imageUrl;

      // Ensure we have data key for API
      if (!rawImage.startsWith('data:')) {
        // If network image, we might need bytes.
        // For now assuming result has data URI or we use _decodedImageBytes if focused.
        if (_decodedImageBytes != null) {
          rawImage =
              'data:image/jpeg;base64,${base64Encode(_decodedImageBytes!)}';
        }
      }

      final prompt = "Cinematic slow motion portrait. $_customPrompt";
      final optic = session.selectedRig?.opticProtocol ?? "Cinematic";

      final videoUri = await service.generateCinematicVideo(
        rawImage,
        prompt,
        optic,
      );

      if (!videoUri.startsWith('Error')) {
        if (await canLaunchUrl(Uri.parse(videoUri))) {
          await launchUrl(Uri.parse(videoUri));
        } else {
          debugPrint("Video URI: $videoUri");
          // Attempt to launch anyway or show dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: Text("Video Generated"),
                content: SelectableText(videoUri),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        throw Exception(videoUri);
      }

      // Decrement credits
      session.decrementCredit('video');
    } catch (e) {
      debugPrint("Video generation error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Video failed: $e')));
      }
    } finally {
      session.setGenerating(false);
    }
  }

  Future<void> _handleQuickUpgrade() async {
    final session = context.read<SessionProvider>();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upgrade')),
      );
      return;
    }

    try {
      // Show loading indicator in dialog or via state
      final success = await StripeService.handlePayment(
        'creatorPack',
        user.email!,
      );

      if (success) {
        await session.fetchUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upgrade successful! Feature unlocked.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Quick Upgrade Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upgrade failed. Please try again.')),
        );
      }
    }
  }

  void _showUpgradeDialog(String feature) {
    final session = context.read<SessionProvider>();
    final tier = session.userProfile?.subscriptionTier?.toLowerCase() ?? '';

    // Calculate differential price
    String upgradePrice = "\$29";
    bool isSocialQuick = tier.contains('socialquick');

    if (isSocialQuick) {
      upgradePrice = "\$24"; // $29 - $5
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.softCharcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.lock_open, color: AppColors.matteGold, size: 40),
            SizedBox(height: 12),
            Text(
              'Unlock $feature',
              style: AppTypography.h3Display(color: AppColors.matteGold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upgrade to the Creator Pack to unlock Stitch, Cinematic Video, and 30 high-res photos.',
              style: AppTypography.bodyRegular(),
              textAlign: TextAlign.center,
            ),
            if (isSocialQuick) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.matteGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.matteGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: AppColors.matteGold,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Loyalty Credit Applied: Pay only the difference!',
                        style: AppTypography.microBold(
                          color: AppColors.matteGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'NOT NOW',
                    style: TextStyle(
                      color: AppColors.coolGray,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: PremiumButton(
                  onPressed: _handleQuickUpgrade,
                  backgroundColor: AppColors.matteGold,
                  foregroundColor: Colors.black,
                  borderRadius: 12,
                  child: Text('UNLOCK FOR $upgradePrice'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
