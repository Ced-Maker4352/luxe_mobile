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

  /// Generic helper for IMAGE generation
  /// Returns a data URL (data:image/png;base64,...) or an error string
  Future<String> _generateImageContent(
    String model,
    List<Map<String, dynamic>> contents,
  ) async {
    debugPrint(
      'GeminiService key check: ${_apiKey.isEmpty ? "EMPTY" : "PRESENT (${_apiKey.substring(0, 4)}...)"}',
    );

    if (_apiKey.isEmpty) {
      debugPrint('GeminiService: API Key is empty!');
      return 'Error: API Key is missing.';
    }

    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');
    final body = {
      'contents': contents,
      'generationConfig': {
        'response_mime_type': 'image/png',
        'response_modalities': ['IMAGE'],
      },
    };

    try {
      debugPrint('GeminiService: Calling $model for image generation...');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('GeminiService Response Status: ${response.statusCode}');
      debugPrint('GeminiService Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Log safety ratings if present
        if (data is Map && data.containsKey('promptFeedback')) {
          debugPrint('Gemini Prompt Feedback: ${data['promptFeedback']}');
        }

        if (data is Map && data.containsKey('candidates')) {
          final candidates = data['candidates'] as List;
          if (candidates.isNotEmpty) {
            final candidate = candidates[0];

            // Log finish reason
            if (candidate is Map && candidate.containsKey('finishReason')) {
              debugPrint('Gemini Finish Reason: ${candidate['finishReason']}');
            }

            if (candidate is Map && candidate.containsKey('content')) {
              final content = candidate['content'];
              if (content is Map && content.containsKey('parts')) {
                final parts = content['parts'] as List;
                for (var part in parts) {
                  if (part is Map && part.containsKey('inlineData')) {
                    final inlineData = part['inlineData'];
                    if (inlineData is Map && inlineData.containsKey('data')) {
                      final mimeType = inlineData['mimeType'] ?? 'image/png';
                      final base64Data = inlineData['data'];
                      debugPrint('GeminiService: Image received successfully!');
                      return 'data:$mimeType;base64,$base64Data';
                    }
                  }
                  // If model returns text instead (e.g. refusal), log it
                  if (part is Map && part.containsKey('text')) {
                    final text = part['text'] as String;
                    if (text.isNotEmpty) {
                      debugPrint(
                        'GeminiService: Model returned text instead of image: ${text.substring(0, text.length > 200 ? 200 : text.length)}...',
                      );
                    }
                  }
                }
              }
            }
          }
        }
        debugPrint('GeminiService: No image found in response from $model');
        return 'Error: No image in response. Safety filter or modality issue?';
      } else {
        debugPrint(
          'Gemini Image API Error: ${response.statusCode} - ${response.body}',
        );
        return 'Error: Gemini API returned ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Gemini Network Error: $e');
      return 'Error: Network request failed - $e';
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
    final skinInstruction = skinTexturePrompt != null
        ? 'SKIN TEXTURE PRIORITY: $skinTexturePrompt'
        : 'SKIN TEXTURE: Balanced realism. Natural pores visible but not exaggerated. Healthy, hydrated look.';

    final finalPrompt =
        """$basePrompt

$skinInstruction

OPTIC PROTOCOL (CORE REQUIREMENT):
$opticProtocol

${backgroundImageBase64 != null ? 'INSTRUCTION: Composite the subject from the first image into the environment/background of the second image seamlessly. Match lighting and perspective.' : ''}

Final Output: RAW, unedited, professional photographic master file. 4K resolution. Zero AI artifacts.""";

    final parts = <Map<String, dynamic>>[];
    parts.add(_getDataPart(referenceImageBase64));

    if (backgroundImageBase64 != null) {
      parts.add(_getDataPart(backgroundImageBase64));
    }
    parts.add({'text': finalPrompt});

    final contents = [
      {'parts': parts},
    ];

    // Try primary model: gemini-2.0-flash
    debugPrint('GeminiService: Attempting primary model gemini-2.0-flash...');
    var result = await _generateImageContent('gemini-2.0-flash', contents);
    if (result.isNotEmpty && result.startsWith('data:image')) {
      debugPrint('GeminiService: Primary model success!');
      return result;
    }

    // Both failed
    return result; // Return the error message from the last attempt
  }

  Future<String> generateStylingChange({
    required String currentImageBase64,
    required String stylingPrompt,
    required String framingMode,
    String? clothingReferenceBase64,
  }) async {
    final image = _getDataPart(currentImageBase64);

    final framingInstructions = {
      'portrait':
          'Maintain the current portrait framing (shoulders and above).',
      'full-body':
          'Generate a 3/4 body shot from head to approximately knee level. Show most of the outfit.',
      'head-to-toe':
          'Generate a COMPLETE head-to-toe full body shot. The entire person must be visible from the top of their head to their feet standing on the ground. Ensure shoes/feet are clearly visible at the bottom of the frame.',
    };

    final prompt =
        """Change the person's clothing. ${clothingReferenceBase64 != null ? 'Use the garment shown in the second image as the primary reference.' : ''} 
    ${stylingPrompt.isNotEmpty ? 'Specific style details: $stylingPrompt.' : ''}
    CRITICAL INSTRUCTION: Ensure the clothing fits the subject's specific body size and proportions exactly. Do not alter the person's body shape, weight, height, or physique. Preserve their natural figure.
    FRAMING: ${framingInstructions[framingMode] ?? framingInstructions['portrait']}
    IDENTITY LOCK: Keep the facial features, skin tone, hair, and overall identity exactly the same. Do not alter age, ethnicity, or distinguishing features.
    If the clothing request refers to a specific brand or institution, create a generic artistic version with similar colors and style.
    Output a photorealistic image.""";

    final parts = <Map<String, dynamic>>[image];
    if (clothingReferenceBase64 != null) {
      parts.add(_getDataPart(clothingReferenceBase64));
    }
    parts.add({'text': prompt});

    final contents = [
      {'parts': parts},
    ];

    // Try gemini-2.0-flash
    var result = await _generateImageContent('gemini-2.0-flash', contents);
    if (result.isNotEmpty && result.startsWith('data:image')) {
      return result;
    }
    return result;
  }

  Future<String> applySkinTexture(
    String currentImageBase64,
    String skinTexturePrompt,
  ) async {
    final image = _getDataPart(currentImageBase64);

    final prompt =
        """Re-generate this exact image with the following skin texture applied:
    $skinTexturePrompt
    CRITICAL: Keep EVERYTHING else exactly the same - same pose, same clothing, same background, same lighting, same composition.
    IDENTITY LOCK: Preserve all facial features, hair, body proportions, and distinguishing features exactly.
    Only modify the skin texture as instructed. Output a photorealistic image.""";

    final contents = [
      {
        'parts': [
          image,
          {'text': prompt},
        ],
      },
    ];

    var result = await _generateImageContent('gemini-2.0-flash', contents);
    if (result.isNotEmpty && result.startsWith('data:image')) {
      return result;
    }
    return result;
  }

  Future<String> upscaleTo4K(String currentImageBase64) async {
    final image = _getDataPart(currentImageBase64);

    final prompt =
        "Perform a high-fidelity UHD enhancement. Upscale to 4K resolution (3840x5120). Reconstruct fine skin pores, hair strands, and fabric weaves. Maintain the exact facial identity. Enhance the lens-specific micro-contrast and sharpen eye reflections to liquid clarity.";

    final contents = [
      {
        'parts': [
          image,
          {'text': prompt},
        ],
      },
    ];

    // Use gemini-2.0-flash for upscaling
    var result = await _generateImageContent('gemini-2.0-flash', contents);
    if (result.isNotEmpty && result.startsWith('data:image')) {
      return result;
    }
    return result;
  }

  Future<String> removeBackground(String currentImageBase64) async {
    final image = _getDataPart(currentImageBase64);

    final prompt =
        "Isolate the subject from the background. Replace background with solid #FFFFFF. Maintain 1:1 facial identity and edge clarity on hair and clothing for professional compositing.";

    final contents = [
      {
        'parts': [
          image,
          {'text': prompt},
        ],
      },
    ];

    var result = await _generateImageContent('gemini-2.0-flash', contents);
    if (result.isNotEmpty && result.startsWith('data:image')) {
      return result;
    }
    return result;
  }
}
