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

  /// Helper for GEMINI generation (generateContent endpoint with inlineData)
  Future<String> _generateImageWithGemini(
    String model,
    String prompt,
    String contextImageBase64, {
    String? identityImageBase64, // NEW: The original photo for ID lock
    String? backgroundImageBase64,
  }) async {
    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');

    final parts = <Map<String, dynamic>>[];

    // 1. Context Image (The image being edited)
    if (contextImageBase64.isNotEmpty) {
      parts.add(_getDataPart(contextImageBase64));
    }

    // 2. Identity Image (The original photo - Source of Truth)
    if (identityImageBase64 != null && identityImageBase64.isNotEmpty) {
      parts.add(_getDataPart(identityImageBase64));
    }

    // 3. Background Image (Optional)
    if (backgroundImageBase64 != null && backgroundImageBase64.isNotEmpty) {
      parts.add(_getDataPart(backgroundImageBase64));
    }

    // Add prompt
    parts.add({'text': prompt});

    final body = {
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {
        // 'response_modalities': ['IMAGE'], // Do not send for gemini-2.5
        'temperature': 0.4,
      },
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

    // ... (rest of method same as before) ...
    try {
      debugPrint(
        'GeminiService: Calling $model (Gemini) with Identity Anchor...',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('GeminiService Response Status: ${response.statusCode}');

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
                    debugPrint(
                      'GeminiService: Gemini image received successfully!',
                    );
                    final mimeType = inlineData['mimeType'];
                    final base64Data = inlineData['data'];
                    return 'data:$mimeType;base64,$base64Data';
                  }
                }
              }
            }
          }
        }
        debugPrint('GeminiService: No image found. content: ${response.body}');
        return 'Error: No image in response.';
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
    return _generateTextContent('gemini-2.0-flash', contents);
  }

  Future<String> generatePortrait({
    required String referenceImageBase64,
    required String basePrompt,
    required String opticProtocol,
    String? backgroundImageBase64,
    String? skinTexturePrompt,
  }) async {
    // ... (prompt logic remains same) ...
    final finalPrompt =
        """TASK: Generate a high-fidelity professional studio portrait of the SPECIFIC PERSON provided in the reference image.

SUBJECT IDENTITY:
- The face must match the reference image exactly. 
- Maintain facial structure, key features, and likeness with high fidelity.
- Do NOT alter the person's identity or create a generic face. 
- This is a RE-STYLING task, not a new person generation.

SCENE & STYLE CONTEXT:
$basePrompt

TECHNICAL DETAILS:
- Skin: Natural, realistic texture with visible pores (avoid plastic smoothing).
- Camera: $opticProtocol
- Lighting: Professional studio lighting matching the requested mood.

${backgroundImageBase64 != null ? 'SETTING: Place the subject in the provided background environment naturally.' : ''}

Output: Photorealistic 4K photograph.""";

    // Try primary model: imagen-4.0-fast-generate-001 (for new generation)
    String modelName = 'imagen-4.0-fast-generate-001';
    if (referenceImageBase64.isNotEmpty) {
      modelName = 'gemini-2.5-flash-image';
    }

    debugPrint('GeminiService: Attempting primary model $modelName...');

    if (modelName.contains('gemini')) {
      // Use _generateContent with image payload
      return _generateImageWithGemini(
        modelName,
        finalPrompt,
        referenceImageBase64, // context
        identityImageBase64:
            null, // Initial generation has only 1 image (reference)
        backgroundImageBase64: backgroundImageBase64,
      );
    }

    // ... (Imagen fallback remains same) ...
    var result = await _generateImageWithImagen(
      modelName,
      finalPrompt,
      referenceImageBase64: referenceImageBase64,
    );
    if (result.isNotEmpty && result.startsWith('data:image')) {
      debugPrint('GeminiService: Primary model success!');
      return result;
    }
    return result;
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
IMAGE 2: Identity Image (Use STRICTLY for Facial Features).

SUBJECT IDENTITY (FROM IMAGE 2):
- The face must match IMAGE 2 exactly.
- Copy facial structure, key features, and likeness from IMAGE 2.
- Do NOT alter the person's identity.

CLOTHING INSTRUCTION (APPLY TO IMAGE 1):
${clothingReferenceBase64 != null ? 'Match the garment shown in the clothing reference image.' : ''} 
Style: ${stylingPrompt.isNotEmpty ? stylingPrompt : 'Fashionable and fitted'}
Ensure the clothing fits naturally.

FRAMING:
${framingInstructions[framingMode] ?? framingInstructions['portrait']}

Output: Photorealistic image combining Image 1's style with Image 2's face.""";

    // Use gemini-2.5-flash-image for styling change
    return _generateImageWithGemini(
      'gemini-2.5-flash-image',
      prompt,
      currentImageBase64,
      identityImageBase64: identityImageBase64,
      backgroundImageBase64:
          clothingReferenceBase64, // Reuse for clothing ref if needed
    );
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

SUBJECT IDENTITY (FROM IMAGE 2):
- The face must match IMAGE 2 exactly.
- Copy facial structure from IMAGE 2.

TEXTURE INSTRUCTION (APPLY TO IMAGE 1):
$skinTexturePrompt

Output: Photorealistic image.""";

    // Use gemini-2.5-flash-image for skin texture
    return _generateImageWithGemini(
      'gemini-2.5-flash-image',
      prompt,
      currentImageBase64,
      identityImageBase64: identityImageBase64,
    );
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
- Strictly preserve the facial features using IMAGE 2 as ground truth.
- Do NOT hallucinate new features.

DETAILS:
- Refine skin texture and details based on Image 2.
- Output: High fidelity photograph.""";

    // Use gemini-2.5-flash-image for upscaling
    return _generateImageWithGemini(
      'gemini-2.5-flash-image',
      prompt,
      currentImageBase64,
      identityImageBase64: identityImageBase64,
    );
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
- Strictly preserve the facial features matching IMAGE 2.
- Do NOT alter the face.

DETAILS:
- Preserve edge details and hair strands.
- Output: High fidelity image with white background.""";

    // Use gemini-2.5-flash-image for background removal
    return _generateImageWithGemini(
      'gemini-2.5-flash-image',
      prompt,
      currentImageBase64,
      identityImageBase64: identityImageBase64,
    );
  }
}
