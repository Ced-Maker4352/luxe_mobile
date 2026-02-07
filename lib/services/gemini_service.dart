import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String _apiKey = dotenv.env['VITE_GEMINI_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Generic helper to make the HTTP request to Gemini API
  Future<String> _generateContent(
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
        // Parse the response structure manually
        // Response format: { candidates: [ { content: { parts: [ { text: "..." } ] } } ] }
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
        return ''; // Return empty if structure doesn't match expected text response
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

    // Direct use of base64 string for JSON payload
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
                'You are a world-class photography director. Transform this raw user idea into a professional image generation prompt. Add specific details about lighting (e.g., volumetric, rim, chiaroscuro), camera angle, lens type (e.g., 85mm), and texture. Keep it concise but elite. \n\nUser Idea: "$draftPrompt"\n\nProfessional Prompt:',
          },
        ],
      },
    ];
    return _generateContent('gemini-2.5-flash', contents);
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

    return _generateContent('gemini-2.5-flash', contents);
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

    return _generateContent('gemini-2.5-flash', contents);
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

    return _generateContent('gemini-2.5-flash', contents);
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

    return _generateContent('gemini-2.5-pro', contents);
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

    return _generateContent('gemini-2.5-flash', contents);
  }
}
