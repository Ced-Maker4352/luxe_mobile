import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String _apiKey = dotenv.env['VITE_GEMINI_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Generic helper for TEXT generation (for prompts, etc.)
  Future<String> _generateTextContent(
    String model,
    List<Map<String, dynamic>> contents,
  ) async {
    if (_apiKey.isEmpty) {
      debugPrint('GeminiService: API Key is empty!');
      return 'Error: API Key is missing.';
    }

    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': contents}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('candidates')) {
          final candidates = data['candidates'] as List;
          if (candidates.isNotEmpty) {
            final candidate = candidates[0];
            if (candidate is Map && candidate.containsKey('content')) {
              final content = candidate['content'];
              if (content is Map && content.containsKey('parts')) {
                final parts = content['parts'] as List;
                if (parts.isNotEmpty) {
                  final part = parts[0];
                  if (part is Map && part.containsKey('text')) {
                    return part['text'] as String;
                  }
                }
              }
            }
          }
        }
        return '';
      } else {
        debugPrint(
          'Gemini API Error: ${response.statusCode} - ${response.body}',
        );
        return 'Error: Gemini API returned ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Gemini Network Error: $e');
      return 'Error: Network request failed';
    }
  }

  /// Helper for IMAGEN generation (predict endpoint)
  Future<String> _generateImageWithImagen(
    String model,
    String prompt, {
    String? referenceImageBase64,
  }) async {
    debugPrint(
      'GeminiService key check: ${_apiKey.isEmpty ? "EMPTY" : "PRESENT (${_apiKey.substring(0, 4)}...)"}',
    );

    if (_apiKey.isEmpty) {
      debugPrint('GeminiService: API Key is empty!');
      return 'Error: API Key is missing.';
    }

    final url = Uri.parse('$_baseUrl/$model:predict?key=$_apiKey');

    final instance = <String, dynamic>{'prompt': prompt};
    if (referenceImageBase64 != null) {
      // Extract raw base64 data without header
      String base64Data = referenceImageBase64;
      if (referenceImageBase64.contains(',')) {
        base64Data = referenceImageBase64.split(',').last;
      }
      // Imagen often takes 'image': {'bytesBase64Encoded': ...}
      instance['image'] = {'bytesBase64Encoded': base64Data};
    }

    final body = {
      'instances': [instance],
      'parameters': {'sampleCount': 1, 'aspectRatio': '3:4'},
    };

    try {
      debugPrint('GeminiService: Calling $model for image generation...');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('GeminiService Response Status: ${response.statusCode}');
      if (response.body.length < 1000) {
        debugPrint('GeminiService Response Body (SHORT): ${response.body}');
      } else {
        debugPrint(
          'GeminiService Response Body Length: ${response.body.length}',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('predictions')) {
          final predictions = data['predictions'] as List;
          if (predictions.isNotEmpty) {
            final prediction = predictions[0];
            if (prediction is Map &&
                prediction.containsKey('bytesBase64Encoded')) {
              final base64Data = prediction['bytesBase64Encoded'];
              final mimeType = prediction['mimeType'] ?? 'image/png';
              debugPrint('GeminiService: Imagen image received successfully!');
              return 'data:$mimeType;base64,$base64Data';
            }
          }
        }
        debugPrint('GeminiService: No image found in Imagen response');
        return 'Error: No image in response.';
      } else {
        debugPrint(
          'Gemini Imagen API Error: ${response.statusCode} - ${response.body}',
        );
        return 'Error: Imagen API returned ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Gemini Network Error: $e');
      return 'Error: Network request failed - $e';
    }
  }

  Future<String> _callGeminiWithFallback(
    List<String> models,
    List<Map<String, dynamic>> parts,
  ) async {
    for (final model in models) {
      final url = Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');

      final body = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'temperature': 0.4},
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE',
          },
        ],
      };

      try {
        debugPrint('GeminiService: Attempting $model...');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        debugPrint('GeminiService $model Response: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('candidates')) {
            final candidates = data['candidates'] as List;
            if (candidates.isNotEmpty) {
              final candidate = candidates[0];
              if (candidate is Map && candidate.containsKey('content')) {
                final content = candidate['content'];
                if (content is Map && content.containsKey('parts')) {
                  final parts = content['parts'] as List;
                  for (final part in parts) {
                    if (part is Map && part.containsKey('inlineData')) {
                      final inlineData = part['inlineData'];
                      debugPrint('GeminiService: Success with $model!');
                      final mimeType = inlineData['mimeType'];
                      final base64Data = inlineData['data'];
                      return 'data:$mimeType;base64,$base64Data';
                    }
                  }
                }
              }
            }
          }
          debugPrint('GeminiService: $model returned no image data.');
        } else {
          debugPrint(
            'GeminiService: $model failed (${response.statusCode}): ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('GeminiService: Error with $model: $e');
      }
    }
    return '';
  }

  // Helper to extract clean data from a data URL for inlineData
  Map<String, dynamic> _getDataPart(String base64String) {
    String data = base64String;
    String mimeType = 'image/jpeg';

    if (base64String.startsWith('data:')) {
      final match = RegExp(
        r'^data:([a-zA-Z0-9]+\/[a-zA-Z0-9-.+]+);base64,(.+)$',
      ).firstMatch(base64String);
      if (match != null) {
        mimeType = match.group(1)!;
        data = match.group(2)!;
      }
    } else if (base64String.contains(',')) {
      final parts = base64String.split(',');
      data = parts[1];
      final header = parts[0];
      final mimeMatch = RegExp(
        r':([a-zA-Z0-9]+\/[a-zA-Z0-9-.+]+);',
      ).firstMatch(header);
      if (mimeMatch != null) {
        mimeType = mimeMatch.group(1)!;
      }
    }

    return {
      'inlineData': {'mimeType': mimeType, 'data': data},
    };
  }

  Future<String> enhancePrompt(String draftPrompt) async {
    final contents = [
      {
        'parts': [
          {
            'text':
                '''You are a master of visual descriptive language for elite portrait photography. 
Transform the user's brief idea into a rich, expansive technical prompt for an AI image generator.
DO NOT use generic phrases like "cinematic lighting" or "84k detail" without accompanying specifics.

ENHANCEMENT RULES:
1. ATMOSPHERE: Define the mood (e.g., ethereal, brooding, vibrant, clinical).
2. LIGHTING: Be precise (e.g., "warm golden hour backlight hitting the hair rim," "moody Rembrandt lighting with high-contrast shadows," "soft diffused studio light from a large octabank").
3. CAMERA/OPTICS: Specify lens and aperture (e.g., "85mm f/1.4 lens," "shallow depth of field with creamy bokeh," "tactile sharp focus on eyes").
4. TEXTURE: Describe specific textures (e.g., "fine skin pores and micro-vellus hair visible," "the rough weave of heavy linen clothing," "tangible dew drops on skin").
5. COMPOSITION: Describe the framing and angle.

Output ONLY the enhanced prompt. No introductions. No quotes.

User Idea: "$draftPrompt"''',
          },
        ],
      },
    ];
    return _generateTextContent('gemini-3-pro-preview', contents);
  }

  Future<String> generatePortrait({
    required List<String> referenceImagesBase64, // CHANGED: List of images
    required String basePrompt,
    required String opticProtocol,
    String? backgroundImageBase64,
    String? clothingReferenceBase64,
    String? campusLogoBase64,
    String? skinTexturePrompt,
    bool preserveAgeAndBody = true,
  }) async {
    final StringBuffer promptBuffer = StringBuffer();
    promptBuffer.writeln("=== STRICT FACIAL CONSISTENCY MODE: ENABLED ===");
    promptBuffer.writeln("");
    promptBuffer.writeln(
      "TASK: Generate a high-fidelity professional studio portrait of the SPECIFIC PERSON using ${referenceImagesBase64.length} Identity Anchors.",
    );

    if (clothingReferenceBase64 != null) {
      promptBuffer.writeln(
        "VIRTUAL TRY-ON: Match the garment shown in the clothing reference image exactly.",
      );
    }

    if (campusLogoBase64 != null) {
      promptBuffer.writeln(
        "CAMPUS IDENTITY: Strictly use the official colors and logo/crest from the provided school reference image. Apply the branding accurately to the wardrobe (varsity jacket, hood, cap, or gown).",
      );
    }

    promptBuffer.writeln("");
    promptBuffer.writeln(
      "IDENTITY PRIORITY HIERARCHY (follow this order strictly):",
    );
    promptBuffer.writeln(
      "  1. FACE (highest priority): The face MUST match the Identity Anchors exactly.",
    );
    promptBuffer.writeln(
      "     - Lock: exact facial bone structure, eye shape/color/spacing, nose bridge/tip profile,",
    );
    promptBuffer.writeln(
      "       lip shape/fullness, jawline contour, chin shape, cheekbone prominence,",
    );
    promptBuffer.writeln(
      "       forehead shape, skin tone/texture, facial hair if present.",
    );
    promptBuffer.writeln(
      "     - Synthesize a consistent 3D representation from the provided angles.",
    );
    promptBuffer.writeln(
      "     - Do NOT drift toward generic, idealized, or averaged features.",
    );

    promptBuffer.writeln(
      "  2. ${preserveAgeAndBody ? 'AGE & BODY (STRICT)' : 'BODY'} (second priority): ${preserveAgeAndBody ? "Maintain the subject's apparent age. Respect the 'Body Type' specified below if it differs from the reference images, but keep the overall anatomic structure consistent." : "Strictly preserve the subject's natural body weight, shape, and proportions. Do NOT slim or alter the body type to fit fashion standards."}",
    );
    promptBuffer.writeln(
      "  3. HAIR: Maintain exact hair color, texture, length, and style from the references.",
    );
    promptBuffer.writeln(
      "  4. FASHION & STYLING (lowest priority): Apply styling only AFTER identity is locked.",
    );
    promptBuffer.writeln(
      "     This is a RE-STYLING task, not a new person generation.",
    );

    promptBuffer.writeln("");
    promptBuffer.writeln("SCENE & STYLE CONTEXT:");
    promptBuffer.writeln(basePrompt);

    promptBuffer.writeln("");
    promptBuffer.writeln("TECHNICAL DETAILS:");
    promptBuffer.writeln(
      "- Skin: ${skinTexturePrompt ?? 'Natural, realistic texture with visible pores (avoid plastic smoothing)'}.",
    );
    promptBuffer.writeln("- Camera: $opticProtocol");
    promptBuffer.writeln(
      "- Lighting: Professional studio lighting matching the requested mood.",
    );

    if (backgroundImageBase64 != null) {
      promptBuffer.writeln(
        "SETTING: Place the subject in the provided background environment naturally.",
      );
    }

    if (clothingReferenceBase64 != null) {
      promptBuffer.writeln(
        "GARMENT REFERENCE: The subject MUST be wearing the exact clothing/outfit shown in the Garment Reference Image. Match the color, fabric, and style accurately.",
      );
    }

    promptBuffer.writeln("");
    promptBuffer.writeln(
      "FINAL CHECK: Before outputting, verify the face matches the Identity Anchors. If any facial feature has drifted, correct it before finalizing.",
    );
    promptBuffer.writeln("");
    promptBuffer.writeln("Output: Photorealistic 4K photograph.");

    final parts = <Map<String, dynamic>>[];

    // Add Identity Anchors
    for (int i = 0; i < referenceImagesBase64.length; i++) {
      parts.add(_getDataPart(referenceImagesBase64[i]));
      parts.add({'text': 'IDENTITY ANCHOR ${i + 1}'});
    }

    if (backgroundImageBase64 != null) {
      parts.add(_getDataPart(backgroundImageBase64));
      parts.add({'text': 'BACKGROUND REFERENCE'});
    }

    if (clothingReferenceBase64 != null) {
      parts.add(_getDataPart(clothingReferenceBase64));
      parts.add({'text': 'GARMENT REFERENCE'});
    }

    if (campusLogoBase64 != null) {
      parts.add(_getDataPart(campusLogoBase64));
      parts.add({
        'text': 'SCHOOL LOGO & BRANDING REFERENCE — Copy this logo accurately.',
      });
    }

    parts.add({'text': promptBuffer.toString()});

    // Updated to match user's available models
    final models = ['gemini-3-pro-image-preview', 'gemini-2.5-flash-image'];

    final result = await _callGeminiWithFallback(models, parts);

    if (result.isNotEmpty) return result;

    // Last resort fallback to Imagen (using known stable model name)
    // Imagen typically supports single reference image
    return _generateImageWithImagen(
      'imagen-4.0-generate-001',
      promptBuffer.toString(),
      referenceImageBase64: referenceImagesBase64.isNotEmpty
          ? referenceImagesBase64.first
          : null,
    );
  }

  Future<String> generateStylingChange({
    required String currentImageBase64,
    required String identityImageBase64, // NEW: Requiring original photo
    required String stylingPrompt,
    required String framingMode,
    String? clothingReferenceBase64,
  }) async {
    final framingInstructions = {
      'portrait':
          'Maintain the current portrait framing (shoulders and above).',
      'full-body':
          'Generate a 3/4 body shot from head to approximately knee level. Show most of the outfit.',
      'head-to-toe':
          'Generate a COMPLETE head-to-toe full body shot. The entire person must be visible from the top of their head to their feet standing on the ground. Ensure shoes/feet are clearly visible at the bottom of the frame.',
    };

    final prompt =
        """TASK: Update the clothing of the SPECIFIC PERSON using TWO source images.
IMAGE 1: Context Image (Use for Pose, Lighting, Composition).
IMAGE 2: Identity Image (Use STRICTLY for Facial Features and Body Structure).

SUBJECT IDENTITY & STRUCTURE (FROM IMAGE 2):
- The face must match IMAGE 2 exactly.
- BODY STRUCTURE: Strictly preserve the subject's natural body weight, shape, and proportions from IMAGE 2. Do NOT alter the body type to fit "fashion standards".
- Copy facial structure, key features, and likeness from IMAGE 2.

CLOTHING INSTRUCTION (APPLY TO IMAGE 1):
${clothingReferenceBase64 != null ? 'Match the garment shown in the clothing reference image.' : ''} 
Style: ${stylingPrompt.isNotEmpty ? stylingPrompt : 'Fashionable and fitted'}
Ensure the clothing fits the subject's natural body type naturally.

FRAMING:
${framingInstructions[framingMode] ?? framingInstructions['portrait']}

Output: Photorealistic image combining Image 1's style with Image 2's face and body structure.""";

    final parts = <Map<String, dynamic>>[];
    parts.add(_getDataPart(currentImageBase64));
    parts.add(_getDataPart(identityImageBase64));

    if (clothingReferenceBase64 != null) {
      parts.add(_getDataPart(clothingReferenceBase64));
    }

    parts.add({'text': prompt});

    final models = ['gemini-3-pro-image-preview', 'gemini-2.5-flash-image'];

    final result = await _callGeminiWithFallback(models, parts);
    if (result.isNotEmpty) return result;

    throw Exception('Styling change failed.');
  }

  Future<String> applySkinTexture(
    String currentImageBase64,
    String identityImageBase64, // NEW
    String skinTexturePrompt,
  ) async {
    final prompt =
        """TASK: Apply the following skin texture to the SPECIFIC PERSON using TWO source images.
IMAGE 1: Context Image.
IMAGE 2: Identity Source.

SUBJECT IDENTITY & STRUCTURE (FROM IMAGE 2):
- The face must match IMAGE 2 exactly.
- BODY STRUCTURE: Strictly preserve the subject's natural body weight and shape.
- Copy facial structure from IMAGE 2.

TEXTURE INSTRUCTION (APPLY TO IMAGE 1):
$skinTexturePrompt

Output: Photorealistic image.""";

    final parts = <Map<String, dynamic>>[];
    parts.add(_getDataPart(currentImageBase64));
    parts.add(_getDataPart(identityImageBase64));
    parts.add({'text': prompt});

    final models = ['gemini-3-pro-image-preview', 'gemini-2.5-flash-image'];

    final result = await _callGeminiWithFallback(models, parts);
    if (result.isNotEmpty) return result;

    throw Exception('Skin texture application failed.');
  }

  Future<String> upscaleTo4K(
    String currentImageBase64,
    String identityImageBase64, // NEW
  ) async {
    final prompt =
        """TASK: Enhance this image to 4K resolution using Identify Reference.
IMAGE 1: Low Res Input.
IMAGE 2: High Res Identity Source.

SUBJECT IDENTITY (FROM IMAGE 2):
- Strictly preserve the subject's facial features and body structure using IMAGE 2 as ground truth.
- Do NOT hallucinate new features or alter body weight.

DETAILS:
- Refine skin texture and details based on Image 2.
- Output: High fidelity photograph.""";

    final parts = <Map<String, dynamic>>[];
    parts.add(_getDataPart(currentImageBase64));
    parts.add(_getDataPart(identityImageBase64));
    parts.add({'text': prompt});

    final models = ['gemini-3-pro-image-preview', 'gemini-2.5-flash-image'];

    return _callGeminiWithFallback(models, parts);
  }

  Future<String> removeBackground(
    String currentImageBase64,
    String identityImageBase64, // NEW
  ) async {
    final prompt =
        """TASK: Isolate the subject on a solid white background (#FFFFFF).
IMAGE 1: Input.
IMAGE 2: Identity Verification.

SUBJECT IDENTITY:
- Strictly preserve the facial features and BODY PROPORTIONS matching IMAGE 2.
- Do NOT alter the face or body weight.

DETAILS:
- Preserve edge details and hair strands.
- Output: High fidelity image with white background.""";

    final parts = <Map<String, dynamic>>[];
    parts.add(_getDataPart(currentImageBase64));
    parts.add(_getDataPart(identityImageBase64));
    parts.add({'text': prompt});

    final models = ['gemini-3-pro-image-preview', 'gemini-2.5-flash-image'];

    return _callGeminiWithFallback(models, parts);
  }

  Future<String> generateGroupStitch({
    required List<String> identityImagesBase64,
    required String prompt,
    String? backgroundImageBase64,
    String? clothingReferenceBase64,
    required String vibe,
    List<String>? perPersonStyles,
    bool preserveAgeAndBody = true,
  }) async {
    final parts = <Map<String, dynamic>>[];
    final int count = identityImagesBase64.length;

    // Virtual Try-On Reference
    if (clothingReferenceBase64 != null && clothingReferenceBase64.isNotEmpty) {
      parts.add(_getDataPart(clothingReferenceBase64));
      parts.add({
        'text': 'CLOTHING REFERENCE IMAGE — Use this garment for the subjects.',
      });
    }

    // ── PHASE 1: IDENTITY ANCHORING ──
    // Each reference image gets a detailed identity lock label.
    // Research shows labeling with explicit facial descriptors improves fidelity.
    for (int i = 0; i < count; i++) {
      parts.add(_getDataPart(identityImagesBase64[i]));
      parts.add({
        'text':
            'IDENTITY ANCHOR ${i + 1} OF $count — Study this face carefully. '
            'Lock the following from this reference: exact facial bone structure, '
            'eye shape and spacing, nose profile, lip shape and fullness, '
            'jawline contour, skin tone and texture, hairline shape, '
            'ear placement, and overall face proportions. '
            'This person MUST be recognizable as the same individual in the output.',
      });
    }

    // ── PHASE 2: BACKGROUND (Optional) ──
    if (backgroundImageBase64 != null && backgroundImageBase64.isNotEmpty) {
      parts.add(_getDataPart(backgroundImageBase64));
      parts.add({
        'text': 'REFERENCE BACKGROUND — Use this as the scene backdrop.',
      });
    }

    // ── PHASE 3: STRICT IDENTITY-FIRST PROMPT ──
    final StringBuffer promptBuffer = StringBuffer();

    promptBuffer.writeln('=== STRICT FACIAL CONSISTENCY MODE: ENABLED ===');
    promptBuffer.writeln('');
    promptBuffer.writeln(
      'TASK: Generate a photorealistic GROUP PHOTO of exactly $count people.',
    );
    promptBuffer.writeln('');

    // Identity Priority Hierarchy
    promptBuffer.writeln(
      'IDENTITY PRIORITY HIERARCHY (follow this order strictly):',
    );
    promptBuffer.writeln(
      '  1. FACE (highest priority): Each person\'s facial features MUST match their Identity Anchor exactly.',
    );
    promptBuffer.writeln(
      '     - Preserve: bone structure, eye shape/color/spacing, nose bridge/tip, lip shape/fullness,',
    );
    promptBuffer.writeln(
      '       jawline, chin shape, cheekbone prominence, forehead shape, skin tone/texture, facial hair if present.',
    );
    promptBuffer.writeln(
      '     - Do NOT average, blend, or synthesize faces across identities.',
    );
    promptBuffer.writeln(
      '     - Do NOT drift toward generic or idealized features.',
    );
    promptBuffer.writeln(
      '  2. ${preserveAgeAndBody ? 'AGE & BODY (STRICT)' : 'BODY'} (second priority): ${preserveAgeAndBody ? "Strictly lock each person's apparent age and natural body weight, shape, and proportions matching their reference. Do NOT slimming, 'beautify', or alter age." : "Preserve each person's body type, build, and proportions from their reference."}',
    );
    promptBuffer.writeln(
      '  3. HAIR: Maintain each person\'s hair color, texture, length, and style.',
    );
    promptBuffer.writeln(
      '  4. FASHION (lowest priority): Apply styling only AFTER identity is locked.',
    );
    promptBuffer.writeln('');

    // Per-person mapping
    promptBuffer.writeln('PERSON-TO-IDENTITY MAPPING:');
    for (int i = 0; i < count; i++) {
      promptBuffer.writeln(
        '  - Person ${i + 1} in the output = Identity Anchor ${i + 1}. No exceptions.',
      );
    }
    promptBuffer.writeln('');

    // Per-person clothing styles (if specified)
    if (perPersonStyles != null && perPersonStyles.isNotEmpty) {
      promptBuffer.writeln('PER-PERSON CLOTHING DIRECTIONS:');
      for (final style in perPersonStyles) {
        promptBuffer.writeln('  - $style');
      }
      promptBuffer.writeln(
        '  Apply these clothing styles to the matching persons while preserving facial identity.',
      );
      promptBuffer.writeln('');
    }

    promptBuffer.writeln(
      'STYLING VIBE: ${vibe == 'matching' ? 'COORDINATED — All subjects wear matching or complementary outfits. Keep clothing style harmonized but DO NOT let outfit changes affect facial features.' : 'INDIVIDUAL — Each person expresses their own unique style. Outfit variety is encouraged but DO NOT let styling alter any facial features.'}',
    );
    promptBuffer.writeln('');

    // Scene
    promptBuffer.writeln('SCENE DIRECTION:');
    promptBuffer.writeln(prompt);
    promptBuffer.writeln('');

    // Technical requirements
    promptBuffer.writeln('TECHNICAL REQUIREMENTS:');
    promptBuffer.writeln(
      '  - Photorealistic, 4K resolution, cinematic lighting.',
    );
    promptBuffer.writeln('  - Natural group interaction and body language.');
    promptBuffer.writeln(
      '  - Each face must be clearly visible and unobstructed.',
    );
    promptBuffer.writeln('  - Consistent lighting across all subjects.');
    promptBuffer.writeln(
      '  - If a face cannot be preserved with high fidelity, slightly adjust the pose to show the face more clearly rather than compromising identity.',
    );
    promptBuffer.writeln('');
    promptBuffer.writeln(
      'FINAL CHECK: Before outputting, verify each person\'s face matches their Identity Anchor. If any face has drifted, regenerate that face to match the reference.',
    );

    parts.add({'text': promptBuffer.toString()});

    final models = ['gemini-3-pro-image-preview', 'gemini-2.5-flash-image'];

    return _callGeminiWithFallback(models, parts);
  }
  // ═══════════════════════════════════════════════════════════
  // VIDEO GENERATION (Veo Protocol)
  // ═══════════════════════════════════════════════════════════

  Future<String> generateCinematicVideo(
    String imageBase64,
    String prompt,
    String opticProtocol,
  ) async {
    if (_apiKey.isEmpty) return 'Error: API Key missing';

    // Added gemini-2.0-flash-exp as it is a known consistent model for video
    final models = [
      'veo-2.0-generate-001',
      'gemini-2.0-flash-exp',
      'gemini-2.5-flash',
    ];

    for (final model in models) {
      // Use v1alpha for experimental/new models like Veo and Gemini 2.0
      String version = 'v1beta';
      if (model.contains('veo') || model.contains('2.0')) {
        version = 'v1alpha';
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/$version/models/$model:generateContent?key=$_apiKey',
      );

      debugPrint(
        'GeminiService: Requesting Cinematic Video from $model ($version)...',
      );

      final finalVideoPrompt =
          "$prompt. Maintain the look of: $opticProtocol. Motion: subtle, elegant cinematic dolly-in. Ultra-realistic skin rendering, 1080p.";

      final parts = <Map<String, dynamic>>[];
      parts.add(_getDataPart(imageBase64));
      parts.add({'text': finalVideoPrompt});

      final body = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'temperature': 0.4},
      };

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        debugPrint(
          'GeminiService Video Response ($model): ${response.statusCode}',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('candidates')) {
            final candidates = data['candidates'];
            if (candidates is List && candidates.isNotEmpty) {
              final candidate = candidates[0];
              if (candidate is Map && candidate.containsKey('content')) {
                final content = candidate['content'];
                if (content is Map && content.containsKey('parts')) {
                  final parts = content['parts'];
                  if (parts is List) {
                    for (final part in parts) {
                      if (part.containsKey('fileData')) {
                        return part['fileData']['fileUri'];
                      }
                      if (part.containsKey('inlineData')) {
                        return 'data:${part['inlineData']['mimeType']};base64,${part['inlineData']['data']}';
                      }
                      if (part.containsKey('videoMetadata')) {
                        return part['videoMetadata']['videoUri'] ?? '';
                      }
                    }
                  }
                }
              }
            }
          }
          debugPrint(
            'GeminiService: Unexpected Video Response format: ${response.body}',
          );
          // Don't return error immediately, separate model failures
        } else {
          debugPrint('Gemini API Error (Video) for $model: ${response.body}');
        }
      } catch (e) {
        debugPrint('Gemini Video Error with $model: $e');
      }
    }
    return 'Error: Video generation failed across all candidates.';
  }

  // ═══════════════════════════════════════════════════════════
  // BRANDING STATION (Restoration)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> generateBrandStrategy(String imageBase64) async {
    if (_apiKey.isEmpty) return {};

    final prompt =
        "Analyze this portrait. Extract a luxury 5-color palette (hex codes) that complements the subject's skin tone and wardrobe. "
        "Suggest 2 luxury fonts (Primary Display, Secondary Body). "
        "Create a 3-word high-end personal branding slogan. "
        "Identify the visual aesthetic (e.g., 'Minimalist Noir', 'Vibrant Opulence'). "
        "Return ONLY raw JSON in this format: { \"colors\": [\"#hex\", ...], \"fonts\": {\"primary\": \"name\", \"secondary\": \"name\"}, \"slogan\": \"text\", \"aesthetic\": \"description\" }";

    final parts = <Map<String, dynamic>>[];
    parts.add(_getDataPart(imageBase64));
    parts.add({'text': prompt});

    final models = ['gemini-2.5-flash', 'gemini-3-pro-preview'];

    for (final model in models) {
      final txt = await _generateTextContent(model, [
        {'parts': parts},
      ]);
      if (txt.isNotEmpty && !txt.startsWith('Error')) {
        try {
          final jsonStr = txt
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          return jsonDecode(jsonStr);
        } catch (e) {
          debugPrint('JSON Parse Error: $e');
        }
      }
    }

    // Fallback if parsing fails or all models fail
    return {
      "colors": ["#000000", "#FFFFFF", "#D4AF37", "#333333", "#808080"],
      "fonts": {"primary": "Playfair Display", "secondary": "Inter"},
      "slogan": "Defined By Excellence",
      "aesthetic": "Timeless Luxury",
    };
  }

  Future<String> generateBrandLogo(String stylePrompt, String brandName) async {
    final nameInstruction = brandName.isNotEmpty
        ? 'Incorporate the brand name "$brandName" elegantly into the design as a monogram, wordmark, or stylized letterform.'
        : '';
    final logoPrompt =
        'Design a high-end, minimalist luxury vector logo mark. $stylePrompt. $nameInstruction '
        'The design should feature a sleek black base refined with subtle iridescent accents (holographic silver, pearl, or faint prism gradients) that suggest a light-shifting metallic finish. '
        'Pure white background. Sharp, geometric, scalable vector aesthetics. Corporate identity style.';

    final parts = [
      {'text': logoPrompt},
    ];
    final models = ['gemini-1.5-pro', 'gemini-1.5-flash'];

    return _callGeminiWithFallback(models, parts);
  }

  Future<String> removeBackgroundForLogo(String imageBase64) async {
    final prompt =
        "Isolate the logo mark on a TRANSPARENT background. "
        "Keep the logo colors valid. Remove only the white/solid background. "
        "Output: PNG image with alpha channel.";

    final parts = <Map<String, dynamic>>[];
    parts.add(_getDataPart(imageBase64));
    parts.add({'text': prompt});

    final models = ['gemini-1.5-pro', 'gemini-1.5-flash'];
    return _callGeminiWithFallback(models, parts);
  }
}
