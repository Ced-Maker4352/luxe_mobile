import '../models/types.dart';

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

// === FILTER PRESETS (From Web AssetEditor) ===
class FilterPreset {
  final String id;
  final String name;
  final double brightness;
  final double contrast;
  final double saturation;
  final double grayscale;
  final double sepia;

  const FilterPreset({
    required this.id,
    required this.name,
    this.brightness = 100,
    this.contrast = 100,
    this.saturation = 100,
    this.grayscale = 0,
    this.sepia = 0,
  });
}

const List<FilterPreset> filterPresets = [
  FilterPreset(id: 'none', name: 'Studio'),
  FilterPreset(
    id: 'noir',
    name: 'Noir',
    grayscale: 100,
    contrast: 120,
    brightness: 110,
  ),
  FilterPreset(id: 'vivid', name: 'Vivid', saturation: 140, contrast: 110),
  FilterPreset(
    id: 'warm',
    name: 'Warm',
    sepia: 30,
    brightness: 105,
    saturation: 110,
  ),
  FilterPreset(id: 'cool', name: 'Cool', brightness: 105, contrast: 105),
  FilterPreset(
    id: 'matte',
    name: 'Matte',
    contrast: 90,
    brightness: 110,
    saturation: 90,
  ),
  FilterPreset(
    id: 'drama',
    name: 'Drama',
    contrast: 130,
    saturation: 80,
    brightness: 90,
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
    name: "Hahnemühle Photo Rag",
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
    icon: "📸",
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
    icon: "💎",
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
    icon: "🎥",
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
    icon: "🎞️",
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
    id: PortraitPackage.INDEPENDENT_ARTIST,
    name: "Independent Artist",
    price: "\$79",
    payAsYouGoPrice: "\$5.00",
    category: 'premium',
    assetCount: 5,
    description:
        "Raw, authentic aesthetic for musicians, painters, and creators.",
    features: [
      "5 Portfolio Assets",
      "Natural Light Simulation",
      "Social Media Crops",
    ],
    exampleImage: "assets/images/independent_artist.jpg",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: Candid, artistic portrait.",
    styles: [
      StyleOption(
        id: "artist_studio",
        name: "The Loft Studio",
        description: "Natural north-facing window light.",
        icon: "🎨",
        image:
            "https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Blurred paint canvases. LIGHTING: Soft, diffused daylight.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.STUDIO_PRO,
    name: "Studio Pro",
    price: "\$149",
    payAsYouGoPrice: "\$7.00",
    category: 'premium',
    assetCount: 10,
    description: "Polished, high-fidelity studio portraits for professionals.",
    features: ["10 Studio Assets", "Advanced Lighting", "Commercial Usage"],
    exampleImage:
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: Professional studio portrait.",
    styles: [
      StyleOption(
        id: "studio_clean",
        name: "Clean Studio",
        description: "Crisp, white background professional look.",
        icon: "📸",
        image:
            "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Pure white cyclorama. LIGHTING: Butterfly lighting.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.VISIONARY_CREATOR,
    name: "Visionary Creator",
    price: "\$199",
    payAsYouGoPrice: "\$9.00",
    category: 'premium',
    assetCount: 12,
    description: "Avant-garde styles for boundary-pushing personal brands.",
    features: [
      "12 Creative Assets",
      "Cinematic Color Grading",
      "Artistic Direction",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: Artistic, moody portrait.",
    styles: [
      StyleOption(
        id: "vis_neon",
        name: "Neon Noir",
        description: "Blade Runner style colors.",
        icon: "🌃",
        image:
            "https://images.unsplash.com/photo-1581337204873-ef36aa186caa?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "LIGHTING: Cyan and Magenta gels. BACKGROUND: Dark rainy street.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.MASTER_PACKAGE,
    name: "Master Package",
    price: "\$299",
    payAsYouGoPrice: "\$12.00",
    category: 'premium',
    assetCount: 20,
    description: "The complete collection. Every style, maximum resolution.",
    features: ["20 Premium Assets", "All Style Access", "Priority Processing"],
    exampleImage:
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: High-end editorial.",
    styles: [
      StyleOption(
        id: "master_editorial",
        name: "Vogue Cover",
        description: "High-fashion magazine aesthetic.",
        icon: "📰",
        image:
            "https://images.unsplash.com/photo-1534030347209-7147fd69a3f2?auto=format&fit=crop&q=80&w=400",
        promptAddition: "LIGHTING: Large softbox. BACKGROUND: Painted canvas.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.DIGITAL_NOMAD,
    name: "Digital Nomad",
    price: "\$129",
    payAsYouGoPrice: "\$5.00",
    category: 'premium',
    assetCount: 8,
    description: "Lifestyle photography set in iconic global destinations.",
    features: ["8 Lifestyle Assets", "Global Locations", "Natural Lighting"],
    exampleImage:
        "https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: Environmental portrait.",
    styles: [
      StyleOption(
        id: "nomad_bali",
        name: "Bali Villa",
        description: "Tropical workspace vibe.",
        icon: "🌴",
        image:
            "https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Lush tropical plants, open air villa. LIGHTING: Natural diffusing sunlight.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.CREATIVE_DIRECTOR,
    name: "Creative Director",
    price: "\$249",
    payAsYouGoPrice: "\$15.00",
    category: 'premium',
    assetCount: 15,
    description: "Sophisticated, high-concept imagery for industry leaders.",
    features: ["15 Executive Assets", "Minimalist Aesthetics", "Brand-Aligned"],
    exampleImage:
        "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial identity. COMPOSITION: Modern architecture backdrop.",
    styles: [
      StyleOption(
        id: "cd_minimal",
        name: "Architectural",
        description: "Clean lines and modern spaces.",
        icon: "building",
        image:
            "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Concrete and glass architecture. LIGHTING: Sharp shadows, high contrast.",
      ),
    ],
  ),
];

class BudgetTier {
  final int amount;
  final int shots;
  final int videos;
  final String label;
  final String description;
  final bool bestValue;

  BudgetTier({
    required this.amount,
    required this.shots,
    required this.videos,
    required this.label,
    required this.description,
    this.bestValue = false,
  });
}

final List<BudgetTier> budgetTiers = [
  BudgetTier(
    amount: 3,
    shots: 3,
    videos: 1,
    label: '\$3 Starter',
    description: '3 Snapshots + 1 Video',
  ),
  BudgetTier(
    amount: 5,
    shots: 6,
    videos: 2,
    label: '\$5 Basic',
    description: '6 Snapshots + 2 Videos',
  ),
  BudgetTier(
    amount: 10,
    shots: 13,
    videos: 5,
    label: '\$10 Pro',
    description: '13 Snapshots + 5 Videos',
  ),
  BudgetTier(
    amount: 15,
    shots: 20,
    videos: 10,
    label: '\$15 Studio',
    description: '20 Snapshots + 10 Videos',
  ),
  BudgetTier(
    amount: 20,
    shots: 30,
    videos: 15,
    label: '\$20 Elite',
    description: '30 Snapshots + 15 Videos',
    bestValue: true,
  ),
];
