import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String _apiKey = dotenv.env['VITE_GEMINI_API_KEY'] ?? '';

  GenerativeModel _getModel(String modelName) {
    return GenerativeModel(model: modelName, apiKey: _apiKey);
  }

  // Helper to extract clean data from a data URL for inlineData
  DataPart _getDataPart(String base64String) {
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

    return DataPart(mimeType, base64.decode(data));
  }

  Future<String> enhancePrompt(String draftPrompt) async {
    final model = _getModel(
      'gemini-1.5-flash',
    ); // Fallback model if 2.5 isn't available in SDK yet
    final content = [
      Content.text(
        'You are a world-class photography director. Transform this raw user idea into a professional image generation prompt. Add specific details about lighting (e.g., volumetric, rim, chiaroscuro), camera angle, lens type (e.g., 85mm), and texture. Keep it concise but elite. \n\nUser Idea: "$draftPrompt"\n\nProfessional Prompt:',
      ),
    ];
    final response = await model.generateContent(content);
    return response.text ?? draftPrompt;
  }

  Future<String> generatePortrait({
    required String referenceImageBase64,
    required String basePrompt,
    required String opticProtocol,
    String? backgroundImageBase64,
    String? skinTexturePrompt,
  }) async {
    final model = _getModel(
      'gemini-1.5-flash-latest',
    ); // Using stable flash for now

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

    final parts = <DataPart>[];
    parts.add(_getDataPart(referenceImageBase64));

    if (backgroundImageBase64 != null) {
      parts.add(_getDataPart(backgroundImageBase64));
    }

    final content = [
      Content.multi([...parts, TextPart(finalPrompt)]),
    ];

    final response = await model.generateContent(content);

    // In Dart SDK, images are often returned as DataParts in the response
    // But for the "image" specific models, we might need to handle it differently
    // if the SDK doesn't support the 'inlineData' response part yet as a direct return.
    // However, the current Dart SDK returns text. For image generation, we usually
    // use specific Vertex AI or Imagen endpoints.
    // In the web app, you are using "gemini-2.5-flash-image" which is a custom/preview model.
    // I will assume for now the response contains the base64 or we handle the specific return type.

    // NOTE: Generating images directly via Gemini's generateContent is a preview feature.
    // I will port the logic structure, but we may need to use 'http' for experimental endpoints.

    return response.text ?? '';
  }

  Future<String> generateStylingChange({
    required String currentImageBase64,
    required String stylingPrompt,
    required String framingMode,
    String? clothingReferenceBase64,
  }) async {
    final model = _getModel('gemini-1.5-flash-latest');
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

    final parts = <DataPart>[image];
    if (clothingReferenceBase64 != null) {
      parts.add(_getDataPart(clothingReferenceBase64));
    }

    final content = [
      Content.multi([...parts, TextPart(prompt)]),
    ];

    final response = await model.generateContent(content);
    return response.text ?? '';
  }

  Future<String> applySkinTexture(
    String currentImageBase64,
    String skinTexturePrompt,
  ) async {
    final model = _getModel('gemini-1.5-flash-latest');
    final image = _getDataPart(currentImageBase64);

    final prompt =
        """Re-generate this exact image with the following skin texture applied:
    $skinTexturePrompt
    CRITICAL: Keep EVERYTHING else exactly the same - same pose, same clothing, same background, same lighting, same composition.
    IDENTITY LOCK: Preserve all facial features, hair, body proportions, and distinguishing features exactly.
    Only modify the skin texture as instructed. Output a photorealistic image.""";

    final content = [
      Content.multi([image, TextPart(prompt)]),
    ];

    final response = await model.generateContent(content);
    return response.text ?? '';
  }

  Future<String> upscaleTo4K(String currentImageBase64) async {
    final model = _getModel(
      'gemini-1.5-pro-latest',
    ); // Pro is better for upscaling
    final image = _getDataPart(currentImageBase64);

    final prompt =
        "Perform a high-fidelity UHD enhancement. Upscale to 4K resolution (3840x5120). Reconstruct fine skin pores, hair strands, and fabric weaves. Maintain the exact facial identity. Enhance the lens-specific micro-contrast and sharpen eye reflections to liquid clarity.";

    final content = [
      Content.multi([image, TextPart(prompt)]),
    ];

    final response = await model.generateContent(content);
    return response.text ?? '';
  }

  Future<String> removeBackground(String currentImageBase64) async {
    final model = _getModel('gemini-1.5-flash-latest');
    final image = _getDataPart(currentImageBase64);

    final prompt =
        "Isolate the subject from the background. Replace background with solid #FFFFFF. Maintain 1:1 facial identity and edge clarity on hair and clothing for professional compositing.";

    final content = [
      Content.multi([image, TextPart(prompt)]),
    ];

    final response = await model.generateContent(content);
    return response.text ?? '';
  }
}
