import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/types.dart';

class AppColors {
  // 1. Core Backgrounds
  static const Color midnightNavy = Color(0xFF0E1A2B); // Primary Canvas
  static const Color softCharcoal = Color(0xFF1C1C1E); // Secondary Panels/Cards
  static const Color deepSpace = Color(0xFF111827); // Input Fields / Gradients

  // 2. Luxury Accent (Matte Gold)
  static const Color matteGold = Color(0xFFC6A85C); // Primary CTA
  static const Color goldHover = Color(0xFFD4B76A);
  static const Color goldPressed = Color(0xFFB89542);

  // 3. Text System
  static const Color softPlatinum = Color(0xFFE5E5E5); // Primary Text
  static const Color coolGray = Color(0xFFB8BDC6); // Secondary Text
  static const Color mutedGray = Color(0xFF8C9199); // Muted / Helper

  // 4. Borders & UI
  static const Color inputBorder = Color(0xFF2A2F45);
  static const Color platinumWhite = Color(
    0xFFF5F5F7,
  ); // For small UI elements only

  // 5. Trust Signal (Soft Shadows)
  static const Color shadow = Color(0x59000000); // rgba(0,0,0,0.35)

  // 6. Enterprise Variant
  static const Color enterpriseNavy = Color(0xFF0B1623);
  static const Color enterpriseGold = Color(
    0xFFB9A269,
  ); // 15% Desaturated Matte Gold
}

class AppTypography {
  // 1. DISPLAY STYLES (Playfair Display)
  // Luxury, Editorial, Authority

  static TextStyle h1Display({Color color = AppColors.softPlatinum}) =>
      GoogleFonts.playfairDisplay(
        color: color,
        fontSize: 48,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.0,
        height: 1.1,
      );

  static TextStyle h2Display({Color color = AppColors.softPlatinum}) =>
      GoogleFonts.playfairDisplay(
        color: color,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );

  static TextStyle h3Display({Color color = AppColors.softPlatinum}) =>
      GoogleFonts.playfairDisplay(
        color: color,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle priceDisplay({Color color = AppColors.matteGold}) =>
      GoogleFonts.playfairDisplay(
        color: color,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  // 2. BODY STYLES (Inter)
  // Modern, Professional, Clear

  static TextStyle bodyLarge({Color color = AppColors.softPlatinum}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodyRegular({Color color = AppColors.softPlatinum}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodyMedium({Color color = AppColors.softPlatinum}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle small({Color color = AppColors.coolGray}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle smallSemiBold({Color color = AppColors.coolGray}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle micro({Color color = AppColors.mutedGray}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      );

  static TextStyle microBold({Color color = AppColors.mutedGray}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      );

  // 3. SPECIAL STYLES

  static TextStyle button({Color color = Colors.black}) => GoogleFonts.inter(
    color: color,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle labelGold({bool active = true}) => GoogleFonts.inter(
    color: active ? AppColors.matteGold : AppColors.mutedGray,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );
}

class AppMotion {
  // 1. TIMING SYSTEM
  static const Duration micro = Duration(milliseconds: 250);
  static const Duration standard = Duration(milliseconds: 400);
  static const Duration major = Duration(milliseconds: 600);

  // 2. EASING CURVES
  // Cubic-bezier(0.4, 0.0, 0.2, 1) - Decelerates gently
  static const Curve cinematic = Cubic(0.4, 0.0, 0.2, 1.0);

  // 3. COMMON TRANSLATIONS
  static const double modalRise = 6.0;
  static const double pageRise = 8.0;
  static const double lift = 5.0; // For small hovers
}

/// Standardized cinematic transition for page changes
class CinematicPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  CinematicPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: AppMotion.standard,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 8 * (1 - animation.value)),
                  child: child,
                );
              },
              child: child,
            ),
          );
        },
      );
}

/// A premium, cinematic button with scale and glow interactions
class PremiumButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final double verticalPadding;
  final double borderRadius;
  final bool isLoading;
  final bool isEnterprise;

  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = AppColors.matteGold,
    this.foregroundColor = Colors.black,
    this.verticalPadding = 16,
    this.borderRadius = 12,
    this.isLoading = false,
    this.isEnterprise = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.isEnterprise ? 250 : 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.isEnterprise ? 0.99 : 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onPressed != null ? _controller.forward() : null,
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? widget.backgroundColor.withValues(alpha: 0.5)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              if (widget.onPressed != null)
                BoxShadow(
                  color: widget.backgroundColor.withValues(
                    alpha: widget.isEnterprise ? 0.1 : 0.2,
                  ),
                  blurRadius: widget.isEnterprise ? 8 : 12,
                  spreadRadius: widget.isEnterprise ? 1 : 2,
                ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor,
                    ),
                  ),
                )
              : DefaultTextStyle(
                  style: AppTypography.button(color: widget.foregroundColor),
                  child: widget.child,
                ),
        ),
      ),
    );
  }
}

class BackgroundPreset {
  final String id;
  final String name;
  final String url;

  BackgroundPreset({required this.id, required this.name, required this.url});
}

class BackgroundCategory {
  final String category;
  final List<BackgroundPreset> items;

  BackgroundCategory({required this.category, required this.items});
}

// === SKIN TEXTURES (From Web App.tsx) ===
class SkinTexture {
  final String id;
  final String label;
  final String description;
  final String prompt;

  const SkinTexture({
    required this.id,
    required this.label,
    required this.description,
    required this.prompt,
  });
}

const List<SkinTexture> skinTextures = [
  SkinTexture(
    id: 'glass',
    label: 'Glass',
    description: 'Porcelain, poreless finish.',
    prompt:
        'SKIN TEXTURE: Surreal perfection. Glass skin finish. Completely smooth, dewy, and poreless. Airbrushed magazine aesthetic. Zero facial hair enhancement.',
  ),
  SkinTexture(
    id: 'soft',
    label: 'Soft',
    description: 'Commercial retouch, delicate.',
    prompt:
        'SKIN TEXTURE: Subtle beauty retouch. Minor blemishes softened while retaining natural contours. Luminous but believable. Slight glow in highlights.',
  ),
  SkinTexture(
    id: 'natural',
    label: 'Natural',
    description: 'Balanced, healthy realism.',
    prompt:
        'SKIN TEXTURE: True-to-life realism. All pores, minor freckles, and natural variations visible. Healthy, balanced exposure. No AI smoothing whatsoever.',
  ),
  SkinTexture(
    id: 'textured',
    label: 'Textured',
    description: 'High-def raw detail.',
    prompt:
        'SKIN TEXTURE: Hyper-detailed. Every pore, wrinkle, and skin imperfection emphasized. Raw, unfiltered, high-fidelity. Phase One 150MP sensor clarity.',
  ),
  SkinTexture(
    id: 'gritty',
    label: 'Gritty',
    description: 'Hyper-real character study.',
    prompt:
        'SKIN TEXTURE: Character study. Gritty, textured, emphasizing life experience. Deep shadows in wrinkles. High contrast micro-detail. Editorial National Geographic aesthetic.',
  ),
];

// === RETOUCH PRESETS ===
class RetouchPreset {
  final String id;
  final String label;
  final double brightness;
  final double contrast;
  final double saturation;
  final double temperature;
  final double tint;
  final double vignette;

  const RetouchPreset({
    required this.id,
    required this.label,
    this.brightness = 100,
    this.contrast = 100,
    this.saturation = 100,
    this.temperature = 0,
    this.tint = 0,
    this.vignette = 0,
  });
}

const List<RetouchPreset> retouchPresets = [
  RetouchPreset(id: 'natural', label: 'Natural'),
  RetouchPreset(
    id: 'editorial',
    label: 'Editorial',
    contrast: 115,
    saturation: 90,
    temperature: -0.1,
  ),
  RetouchPreset(
    id: 'noir',
    label: 'Noir',
    saturation: 0,
    contrast: 130,
    vignette: 0.4,
  ),
  RetouchPreset(
    id: 'golden',
    label: 'Golden Hour',
    temperature: 0.3,
    tint: 0.05,
    vignette: 0.2,
  ),
  RetouchPreset(id: 'vivid', label: 'Vivid', saturation: 125, contrast: 110),
  RetouchPreset(
    id: 'muted',
    label: 'Muted',
    saturation: 80,
    contrast: 90,
    temperature: -0.05,
  ),
];

// === PROMPT CATEGORIES (From Web) ===
const Map<String, List<String>> promptCategories = {
  'Lighting & Atmosphere': [
    'Golden hour sunlight with lens flares',
    'Dramatic side lighting (Chiaroscuro)',
    'Soft diffused overcast light',
    'Ring light beauty lighting',
    'Neon-lit cyberpunk atmosphere',
    'Candlelit warm intimate glow',
    'High-key studio brightness',
    'Moody low-key shadows',
    'Backlit halo rim lighting',
  ],
  'Camera & Lens': [
    'Shallow depth of field (f/1.2)',
    'Medium format film grain',
    'Anamorphic lens distortion',
    'Macro detail close-up',
    '35mm vintage film aesthetic',
    'Tilt-shift miniature effect',
    'Hasselblad medium format',
    'Cinematic 2.39:1 crop',
  ],
  'Environment': [
    'Luxury penthouse interior with city view',
    'Minimalist white studio',
    'Urban street with neon signs',
    'Natural forest with dappled light',
    'Modern art gallery space',
    'Rooftop at sunset',
    'Beach golden hour',
    'Industrial warehouse loft',
  ],
  'Styling & Vibe': [
    'High fashion editorial',
    'Casual streetwear cool',
    'Corporate executive power',
    'Bohemian artistic freedom',
    'Glamorous red carpet',
    'Minimalist Scandinavian',
    'Vintage retro 70s',
    'Futuristic tech aesthetic',
  ],
};

// === STITCH GROUP PRESETS ===
const Map<String, List<String>> stitchGroupPresets = {
  'Friends': [
    'Casual brunch squad, relaxed and laughing',
    'Night out crew, club-ready glam',
    'Beach vacation vibes, sun-kissed',
    'Road trip energy, windswept and carefree',
    'Game day crew, team colors and spirit',
    'Rooftop party, city lights backdrop',
    'Cozy cabin weekend, warm layers',
    'Festival friends, boho and bold',
    'Coffee shop hangout, effortless cool',
  ],
  'Family': [
    'Elegant holiday portrait, coordinated neutrals',
    'Casual outdoor family, golden hour park',
    'Formal studio portrait, classic and timeless',
    'Beach family session, whites and creams',
    'Cozy living room gathering, warm tones',
    'Spring garden family, floral and fresh',
    'Winter wonderland family, layered and warm',
    'Modern minimalist family, clean backdrop',
    'Heritage portrait, regal and dignified',
  ],
  'Rap Group': [
    'Album cover shoot, dark and moody',
    'Trap house aesthetic, chains and attitude',
    'Old school 90s hip-hop, baggy fits',
    'Luxury lifestyle, designer drip',
    'Street corner cypher, raw and gritty',
    'Music video still, cinematic lighting',
    'Ice and diamonds, bling era',
    'Underground basement session, lo-fi vibes',
    'Stadium tour poster, epic scale',
    'Drill scene, dark urban energy',
  ],
  'Female R&B': [
    'Satin and velvet, sultry studio',
    'Y2K nostalgia, glossy and playful',
    'Destiny\'s Child era, coordinated power',
    'Ethereal goddess, flowing fabrics',
    'Motown revival, retro elegance',
    '90s R&B video still, hoop earrings and attitude',
    'Luxury penthouse, evening glamour',
    'Afrofuturism, bold and regal',
    'Acoustic session, intimate and raw',
  ],
  'Male R&B': [
    'Smooth operator, suits and silk',
    'New Edition era, coordinated cool',
    'Jodeci vibes, leather and edge',
    'Modern crooners, minimalist luxury',
    'Rooftop serenade, city skyline',
    'Studio session, late night recording',
    'Black tie gala, tuxedos and class',
    'Streetwear meets soul, casual luxury',
    'Vintage soul revival, 70s warmth',
  ],
  'K-Pop': [
    'Concept photo, pastel dreamscape',
    'Dark concept, edgy and theatrical',
    'School uniform concept, youthful energy',
    'Retro concept, 80s synthwave',
    'Nature concept, ethereal forest',
    'Streetwear concept, urban Seoul',
    'Royal concept, regal and ornate',
    'Futuristic concept, holographic and chrome',
    'Cute concept, bright colors and aegyo',
    'Girl crush / boy crush, fierce and confident',
  ],
  'Pop Group': [
    'Spice Girls energy, bold individual styles',
    'Clean pop aesthetic, matching whites',
    'Summer anthem vibes, bright and beachy',
    'Award show red carpet, glamorous',
    'Music video set, dance formation',
    'Retro disco, sparkle and shine',
    'Pastel paradise, dreamy and soft',
    'Power pop, leather and attitude',
    'Holiday special, festive and fun',
  ],
  'Rock Band': [
    'Garage band raw, amps and attitude',
    'Arena rock, dramatic stage lighting',
    'Punk aesthetic, leather and studs',
    'Classic rock, 70s denim and shag',
    'Indie band, thrift store cool',
    'Grunge revival, flannel and angst',
    'Glam metal, hair and spandex',
    'Modern alternative, moody and artistic',
    'Festival headliner, epic crowd backdrop',
    'Album cover shoot, iconic poses',
  ],
};

// === CURATED LOCATION PRESETS (From Web) ===
const Map<String, List<String>> environmentPromptTips = {
  'Luxury': [
    'Modern penthouse with floor-to-ceiling windows overlooking NYC',
    'Private yacht deck at sunset in Monaco',
    'Marble-floored mansion with crystal chandelier',
    'First-class private jet cabin interior',
  ],
  'Nature': [
    'Misty forest clearing at dawn',
    'Desert dunes under golden hour light',
    'Tropical waterfall with lush greenery',
    'Snow-covered mountain peak vista',
  ],
  'Urban': [
    'Tokyo neon-lit street at night',
    'Brooklyn bridge at sunset',
    'London phone booth in rain',
    'Paris cafe terrace scene',
  ],
  'Studio': [
    'Pure white infinity cyclorama',
    'Dark grey textured backdrop',
    'Hand-painted canvas backdrop',
    'Black void with rim lighting',
  ],
};

final List<BackgroundCategory> backgroundPresets = [
  BackgroundCategory(
    category: "Studio Masters",
    items: [
      BackgroundPreset(
        id: 'bg-pure-white',
        name: 'Infinity White',
        url:
            'https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-fashion-grey',
        name: 'Fashion Grey',
        url:
            'https://images.unsplash.com/photo-1554188248-986adbb73be4?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-void-black',
        name: 'Void Black',
        url:
            'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-textured-canvas',
        name: 'Hand-Painted Canvas',
        url:
            'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&q=80&w=1000',
      ),
    ],
  ),
  BackgroundCategory(
    category: "Editorial Colors",
    items: [
      BackgroundPreset(
        id: 'bg-deep-navy',
        name: 'Midnight Navy',
        url:
            'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-cream-beige',
        name: 'Organic Cream',
        url:
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-olive-green',
        name: 'Muted Olive',
        url:
            'https://images.unsplash.com/photo-1541185933-ef5d8ed016c2?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-terracotta',
        name: 'Warm Terracotta',
        url:
            'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?auto=format&fit=crop&q=80&w=1000',
      ),
    ],
  ),
  BackgroundCategory(
    category: "Executive Environments",
    items: [
      BackgroundPreset(
        id: 'bg-corner-office',
        name: 'Corner Office',
        url:
            'https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-modern-lobby',
        name: 'Modern Lobby',
        url:
            'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-bookshelf',
        name: 'Academic Library',
        url:
            'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-penthouse-view',
        name: 'Skyline Penthouse',
        url:
            'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80&w=1000',
      ),
    ],
  ),
  BackgroundCategory(
    category: "Lifestyle & Texture",
    items: [
      BackgroundPreset(
        id: 'bg-concrete',
        name: 'Urban Concrete',
        url:
            'https://images.unsplash.com/photo-1534353436294-0dbd4bdac845?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-nature-blur',
        name: 'Garden Bokeh',
        url:
            'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-marble',
        name: 'Carrara Marble',
        url:
            'https://images.unsplash.com/photo-1533154683836-84ea7a0bc310?auto=format&fit=crop&q=80&w=1000',
      ),
      BackgroundPreset(
        id: 'bg-abstract-gold',
        name: 'Gold Leaf',
        url:
            'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?auto=format&fit=crop&q=80&w=1000',
      ),
    ],
  ),
];

final List<String> universities = [
  "Harvard University",
  "MIT",
  "Stanford University",
  "Yale University",
  "Princeton University",
  "Columbia University",
  "Caltech",
  "University of Pennsylvania",
  "Johns Hopkins University",
  "Duke University",
  "Northwestern University",
  "Dartmouth College",
  "Brown University",
  "Vanderbilt University",
  "Rice University",
  "Washington University in St. Louis",
  "Cornell University",
  "University of Notre Dame",
  "UCLA",
  "UC Berkeley",
  "Emory University",
  "Georgetown University",
  "University of Michigan",
  "Carnegie Mellon University",
  "University of Virginia",
  "USC",
  "NYU",
  "Tufts University",
  "UC Santa Barbara",
  "University of Florida",
  "UNC Chapel Hill",
  "Wake Forest University",
  "UC San Diego",
  "University of Rochester",
  "Boston College",
  "Georgia Tech",
  "UC Irvine",
  "William & Mary",
  "UC Davis",
  "Tulane University",
  "Boston University",
  "Brandeis University",
  "Case Western Reserve",
  "UW Madison",
  "UIUC",
  "University of Georgia",
  "Lehigh University",
  "Northeastern University",
  "Purdue University",
  "Ohio State University",
  "Villanova University",
  "Florida State University",
  "Syracuse University",
  "University of Maryland",
  "University of Pittsburgh",
  "Penn State",
  "University of Washington",
  "Rutgers University",
  "Texas A&M",
  "UConn",
  "UMass Amherst",
  "WPI",
  "Clemson University",
  "George Washington University",
  "University of Minnesota",
  "Virginia Tech",
  "UT Austin",
  "BYU",
  "University of Miami",
  "Michigan State",
  "NC State",
  "Indiana University",
  "SMU",
  "Baylor University",
  "Fordham University",
  "American University",
  "University of Delaware",
  "University of Iowa",
  "TCU",
  "Drexel University",
  "Auburn University",
  "University of Vermont",
  "Howard University",
  "University of Utah",
  "Arizona State University",
  "University of Alabama",
  "LSU",
  "University of Tennessee",
  "University of Kentucky",
  "University of Oregon",
  "University of Colorado Boulder",
  "University of Oklahoma",
  "University of Kansas",
  "University of Nebraska",
  "Iowa State",
  "Oxford University",
  "Cambridge University",
]..sort();

final Map<String, Map<String, List<String>>> wardrobePresets = {
  'Female': {
    'Bohemian': [
      "Flowing linen maxi dress in earth tones with layered necklaces",
      "Embroidered silk kimono with floral patterns and a loose fit",
      "Crochet lace top with wide-leg terracotta trousers",
      "Vintage suede fringe jacket over a white cotton sundress",
      "Paisley print wrap dress with bell sleeves",
    ],
    'Classic': [
      "Tailored black tuxedo blazer with satin lapels",
      "Crisp white silk blouse with high-waisted cigarette trousers",
      "Little black dress (Chanel style) with pearl accents",
      "Camel cashmere trench coat over a turtleneck",
      "Navy blue structured power suit",
    ],
    'Streetwear': [
      "Oversized graphic hoodie with distressed denim jacket",
      "Cropped leather moto jacket with high-waisted cargo pants",
      "Vintage varsity bomber jacket with athletic details",
      "Neon windbreaker with tech-wear aesthetics",
      "Black turtleneck with silver chain accessories and denim",
    ],
    'Your School': universities
        .map(
          (u) =>
              "$u vintage varsity bomber jacket with classic emblem, tailored to perfectly fit the subject's body shape",
        )
        .toList(),
  },
  'Male': {
    'Bohemian': [
      "Unbuttoned linen shirt in sage green with rolled sleeves",
      "Textured knit cardigan over a loose cotton tee",
      "Vintage patterned silk shirt with brown corduroy trousers",
      "Suede vest with a henley shirt and leather accessories",
      "Relaxed fit poncho sweater in neutral wool tones",
    ],
    'Classic': [
      "Bespoke charcoal three-piece wool suit",
      "Crisp white oxford shirt with a black bow tie",
      "Navy blue double-breasted blazer with gold buttons",
      "Black cashmere turtleneck with a grey wool overcoat",
      "Classic beige trench coat over a suit",
    ],
    'Streetwear': [
      "Heavyweight oversized hoodie in matte black",
      "Distressed denim jacket with sherpa lining",
      "Leather biker jacket with a plain white tee",
      "Tech-wear utility vest with multiple pockets",
      "Vintage 90s windbreaker with bold color blocking",
    ],
    'Your School': universities
        .map(
          (u) =>
              "$u heavyweight vintage varsity bomber jacket with chenille patches, tailored to perfectly fit the subject's body shape",
        )
        .toList(),
  },
};

final List<PrintProduct> printProducts = [
  PrintProduct(
    id: 'gallery-canvas',
    name: "Museum Grade Canvas",
    material: "400gsm Cotton Blend",
    price: 149.0,
    description:
        "Hand-stretched over kiln-dried pine bars. Archival inks guaranteed for 100 years.",
    partnerName: "WhiteWall",
    partnerUrl: "https://www.whitewall.com/us/canvas-prints",
  ),
  PrintProduct(
    id: 'aluminum-metal',
    name: "ChromaLuxe Metal",
    material: "High-Gloss Aluminum",
    price: 229.0,
    description:
        "Dye-sublimation infusion into specialized aluminum. Unmatched vibrancy and depth.",
    partnerName: "Mpix",
    partnerUrl: "https://www.mpix.com/products/homedecor/metal-prints",
  ),
  PrintProduct(
    id: 'fine-art-print',
    name: "HahnemÃ¼hle Photo Rag",
    material: "308gsm Matte Cotton",
    price: 89.0,
    description:
        "The industry standard for fine art photography. Soft, deep blacks and rich detail.",
    partnerName: "The Print Space",
    partnerUrl:
        "https://www.theprintspace.com/professional-printing-services/giclee-fine-art-printing",
  ),
];

final List<CameraRig> cameraRigs = [
  CameraRig(
    id: 'sony-a7rv',
    name: "Sony A7R V | G-Master Protocol",
    description:
        "Ultra-high 61MP resolution with surgical eye-autofocus. Perfect for crisp, clinical executive clarity.",
    icon: "ðŸ“¸",
    opticProtocol:
        "SENSOR: 61.0MP Full-frame Exmor R BSI CMOS. LENS: Sony FE 85mm f/1.2 G-Master. OPTICS: Nano AR Coating II to eliminate flare. FOCUS: AI-driven real-time eye-tracking locked to the iris. RENDERING: Ultra-high micro-contrast, 10-bit 4:2:2 color depth, smooth G-Master bokeh fall-off, sharp texture reconstruction of skin pores and fabric weave.",
    specs: CameraRigSpecs(
      sensor: "61MP Full-Frame Exmor R",
      lens: "Sony FE 85mm f/1.2 GM",
      processing: "Clinical Sharpness / Neutral",
    ),
  ),
  CameraRig(
    id: 'phase-one-xf',
    name: "Phase One XF | Medium Format Titan",
    description:
        "The peak of commercial photography. 150MP back for unparalleled depth and billboard-scale detail.",
    icon: "ðŸ’Ž",
    opticProtocol:
        "SENSOR: IQ4 150MP Trichromatic Medium Format. LENS: Schneider Kreuznach 80mm f/2.8 Blue Ring. OPTICS: Leaf shutter synchronization for perfect strobe control. RENDERING: 16-bit linear color for perfect skin gradations, massive dynamic range, zero digital noise, organic highlight roll-off, physically accurate depth-of-field.",
    specs: CameraRigSpecs(
      sensor: "150MP IQ4 Trichromatic",
      lens: "Schneider Kreuznach 80mm LS",
      processing: "16-bit Color / Archival Depth",
    ),
  ),
  CameraRig(
    id: 'red-komodo',
    name: "RED Komodo-X | Cinematic Narrative",
    description:
        "Hollywood motion-picture grade aesthetics. Portraits that feel like a high-budget film frame.",
    icon: "ðŸŽ¥",
    opticProtocol:
        "SENSOR: 6K S35 Global Shutter. LENS: Cooke Panchro/i Classic Prime (i Technology). OPTICS: Anamorphic-style oval bokeh, subtle highlight bloom. RENDERING: Cinematic film-stock grain, IPP2 color pipeline, soft and naturalistic skin-tone science, Hollywood 'glow' in the highlights, dramatic cinematic contrast.",
    specs: CameraRigSpecs(
      sensor: "6K S35 Global Shutter",
      lens: "Cooke Panchro/i Classic",
      processing: "IPP2 / Cinematic Halo",
    ),
  ),
  CameraRig(
    id: 'fujifilm-gfx',
    name: "Fujifilm GFX 100II | Analog Heritage",
    description:
        "Large format sensor depth meets legendary film simulations. The choice for a soulful, organic look.",
    icon: "ðŸŽžï¸",
    opticProtocol:
        "SENSOR: 102MP High-Speed Large Format. LENS: Fujinon GF 110mm f/2 R LM WR. OPTICS: High-precision weather-sealed glass. RENDERING: Provia/Standard film simulation base, incredible 3D subject separation, buttery smooth tonal transitions, rich deep shadows, textured organic feel without artificial sharpening.",
    specs: CameraRigSpecs(
      sensor: "102MP Medium Format CMOS",
      lens: "Fujinon GF 110mm f/2",
      processing: "Classic Chrome / Film Sim",
    ),
  ),
];

final List<PackageDetails> packages = [
  PackageDetails(
    id: PortraitPackage.creatorPack,
    name: "The Creator Pack",
    price: "\$29",
    payAsYouGoPrice: "\$29.00",
    category: 'premium',
    assetCount: 30,
    description: "Ideal for influencers and personal brands needing variety.",
    features: [
      "30 High-Res Photos",
      "Commercial Rights",
      "3 Locations",
      "Social Media Optimization",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=800&h=1000",
    thumbnail:
        "https://images.unsplash.com/photo-1620932900342-60bd06374092?auto=format&fit=crop&q=80&w=400",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: Professional studio portrait.",
    buttonLabel: "UPGRADE YOUR LOOK",
    styles: [
      StyleOption(
        id: "creator_studio",
        name: "Modern Studio",
        description: "Polished and professional.",
        icon: "📸",
        image:
            "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&q=80&w=400",
        promptAddition: "LIGHTING: Studio strobe. BACKGROUND: Grey seamless.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.professionalShoot,
    name: "Professional Shoot",
    price: "\$99",
    payAsYouGoPrice: "\$99.00",
    category: 'business',
    assetCount: 80,
    description:
        "Replacing traditional photography. The complete studio experience.",
    features: [
      "80 Pro-Grade Photos",
      "4K Export Quality",
      "Studio Lighting (Cinematic)",
      "Priority Processing",
      "Commercial License Included",
      "Value: \$800+",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=800&h=1000",
    thumbnail:
        "https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?auto=format&fit=crop&q=80&w=400",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: High-end editorial.",
    buttonLabel: "GET PROFESSIONAL RESULTS",
    styles: [
      StyleOption(
        id: "pro_executive",
        name: "Executive",
        description: "Leadership presence.",
        icon: "💼",
        image:
            "https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400",
        promptAddition: "LIGHTING: Window light. BACKGROUND: Modern office.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.agencyMaster,
    name: "Agency / Master",
    price: "\$299",
    payAsYouGoPrice: "\$299.00",
    category: 'elite',
    assetCount: 200,
    description: "For teams, agencies, and high-volume professionals.",
    features: [
      "200 Master Assets",
      "Identity Lock™ (Consistency)",
      "Group Mode (Multi-Person)",
      "Corporate Team Generator",
      "White-Label Resale Rights",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=800&h=1000",
    thumbnail:
        "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&q=80&w=400",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: Masterpiece quality portrait.",
    buttonLabel: "SCALE YOUR BRAND",
    styles: [
      StyleOption(
        id: "master_luxury",
        name: "Luxury Lifestyle",
        description: "Peak aspiration.",
        icon: "💎",
        image:
            "https://images.unsplash.com/photo-1566492031773-4f4e44671857?auto=format&fit=crop&q=80&w=400",
        promptAddition: "LIGHTING: Golden hour. BACKGROUND: Private estate.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.socialQuick,
    name: "Social Quick",
    price: "\$5",
    payAsYouGoPrice: "\$5.00",
    category: 'standard',
    assetCount: 5,
    description: "Perfect for profile updates and fast content refreshes.",
    features: [
      "5 HD images",
      "1 style category",
      "2 lighting variations",
      "1 aspect ratio",
      "24-hour storage",
      "No watermark",
    ],
    exampleImage: "assets/images/independent_artist.jpg",
    thumbnail:
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80&w=400",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: Candid, clear social media portrait.",
    buttonLabel: "TRY IT OUT",
    styles: [
      StyleOption(
        id: "social_clean",
        name: "Clean Profile",
        description: "Crisp and engaging.",
        icon: "✨",
        image:
            "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "LIGHTING: Natural soft light. BACKGROUND: Blurred city cafe.",
      ),
    ],
  ),
];
