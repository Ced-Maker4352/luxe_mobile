enum PortraitPackage {
  EXECUTIVE,
  ENTERTAINER,
  CINEMATIC_NOIR,
  BIRTHDAY_LUXE,
  MOTION,
  INDEPENDENT_ARTIST,
  SNAPSHOT_DAILY,
  SNAPSHOT_STYLE,
  STUDIO_PRO,
  VISIONARY_CREATOR,
  MASTER_PACKAGE,
  DIGITAL_NOMAD,
  CREATIVE_DIRECTOR,
  branding,
}

class CameraRig {
  final String id;
  final String name;
  final String description;
  final String opticProtocol;
  final String icon;
  final CameraRigSpecs specs;

  CameraRig({
    required this.id,
    required this.name,
    required this.description,
    required this.opticProtocol,
    required this.icon,
    required this.specs,
  });
}

class CameraRigSpecs {
  final String sensor;
  final String lens;
  final String processing;

  CameraRigSpecs({
    required this.sensor,
    required this.lens,
    required this.processing,
  });
}

class GenerationResult {
  final String id;
  final String imageUrl;
  final String? videoUrl;
  final String mediaType; // 'image' | 'video'
  final PortraitPackage packageType;
  final String? styleName;
  final int timestamp;
  final bool? isUHD;
  final bool? redoUsed;

  GenerationResult({
    required this.id,
    required this.imageUrl,
    this.videoUrl,
    required this.mediaType,
    required this.packageType,
    this.styleName,
    required this.timestamp,
    this.isUHD,
    this.redoUsed,
  });
}

class BrandKit {
  final String logoUrl;
  final List<String> colors;
  final BrandFonts fonts;
  final String slogan;

  BrandKit({
    required this.logoUrl,
    required this.colors,
    required this.fonts,
    required this.slogan,
  });
}

class BrandFonts {
  final String primary;
  final String secondary;

  BrandFonts({required this.primary, required this.secondary});
}

class StyleOption {
  final String id;
  final String name;
  final String description;
  final String promptAddition;
  final String icon;
  final String image;

  StyleOption({
    required this.id,
    required this.name,
    required this.description,
    required this.promptAddition,
    required this.icon,
    required this.image,
  });
}

class PackageDetails {
  final PortraitPackage id;
  final String name;
  final String price;
  final String category; // 'premium' | 'snapshot'
  final int assetCount;
  final String description;
  final List<String> features;
  final String basePrompt;
  final String exampleImage;
  final List<StyleOption> styles;

  PackageDetails({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.assetCount,
    required this.description,
    required this.features,
    required this.basePrompt,
    required this.exampleImage,
    required this.styles,
  });
}

class PrintProduct {
  final String id;
  final String name;
  final String material;
  final double price;
  final String description;
  final String? imageOverlay;
  final String? partnerUrl;
  final String? partnerName;

  PrintProduct({
    required this.id,
    required this.name,
    required this.material,
    required this.price,
    required this.description,
    this.imageOverlay,
    this.partnerUrl,
    this.partnerName,
  });
}

class BrandData {
  final BrandStrategy? strategy;
  final String? logoUrl;

  BrandData({this.strategy, this.logoUrl});
}

class BrandStrategy {
  final List<String> colors;
  final BrandFonts fonts;
  final String slogan;
  final String aesthetic;

  BrandStrategy({
    required this.colors,
    required this.fonts,
    required this.slogan,
    required this.aesthetic,
  });
}
