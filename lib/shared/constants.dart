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
    name: "The Independent Artist",
    price: "\$79",
    category: 'premium',
    assetCount: 5,
    description:
        "Raw, authentic aesthetic for musicians, painters, and creators building their personal brand.",
    features: [
      "5 Portfolio Assets",
      "Natural Light Simulation",
      "Social Media Crops",
      "Organic Texture",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt: """IDENTITY INTEGRITY: 1:1 facial identity.
COMPOSITION: Candid, artistic portrait in a sun-lit loft studio.
WARDROBE: Casual chic, denim, linen, or thrifted vintage layers.
LIGHTING: Window light, soft shadows, natural fall-off.
TEXTURE: Slight film grain, 35mm film aesthetic, organic skin texture.""",
    styles: [
      StyleOption(
        id: "artist_studio",
        name: "The Loft Studio",
        description:
            "Natural north-facing window light in a Brooklyn-style creative loft.",
        icon: "🎨",
        image:
            "https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Blurred paint canvases, easels, brick walls painted white. LIGHTING: Soft, diffused overcast daylight coming from the left. MOOD: Contemplative, creative focus.",
      ),
      StyleOption(
        id: "artist_street",
        name: "Urban Texture",
        description: "Gritty, textured street style with concrete and depth.",
        icon: "🏙️",
        image:
            "https://images.unsplash.com/photo-1444723121867-229166398e69?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Out of focus city street, concrete textures, distant bokeh traffic lights. LIGHTING: Overcast day, flat flattering light. MOOD: Authentic, street-smart, modern.",
      ),
      StyleOption(
        id: "artist_golden",
        name: "Golden Hour Warmth",
        description: "Sun-drenched, flared, organic warmth.",
        icon: "☀️",
        image:
            "https://images.unsplash.com/photo-1472120435266-53107fd0c44a?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "LIGHTING: Direct sun flare entering the lens (halation). Warm orange and yellow tones. BACKGROUND: Nature or park, extremely shallow depth of field (f/1.4). MOOD: Dreamy, hopeful, inspired.",
      ),
      StyleOption(
        id: "artist_bw",
        name: "Tri-X Mono",
        description: "High contrast black and white film grain.",
        icon: "⚫",
        image:
            "https://images.unsplash.com/photo-1535571545695-16dbdf6e80b4?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COLOR GRADING: Black and white, high contrast (push process). FILM STOCK: Kodak Tri-X 400. TEXTURE: Noticeable film grain. LIGHTING: Harder shadows, dramatic side lighting.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.EXECUTIVE,
    name: "The Global CEO",
    price: "\$129",
    category: 'premium',
    assetCount: 5,
    description:
        "Forbes-grade professional headshots. Absolute identity precision for elite corporate and board use.",
    features: [
      "5 Studio Assets",
      "UHD 4K Native",
      "Architectural Backdrop",
      "Identity Guard Protocol",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt:
        """IDENTITY INTEGRITY: Maintain exact 1:1 facial geometry, eye color, and natural skin imperfections of the reference.
WARDROBE: Bespoke charcoal wool suit with visible weave, crisp white 200-thread-count cotton shirt.
TEXTURE: Hyper-realistic rendering of skin pores, facial hair, and fabric fibers. Zero AI smoothing.""",
    styles: [
      StyleOption(
        id: "ceo_boardroom",
        name: "The Boardroom",
        description: "Commanding authority at the head of the table.",
        icon: "💼",
        image:
            "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COMPOSITION: Medium shot, standing confident. BACKGROUND: High-end mahogany boardroom, blurred glass partitions. LIGHTING: Cinematic overhead grid lighting plus a rim light for separation.",
      ),
      StyleOption(
        id: "ceo_glass_office",
        name: "The Skyscraper",
        description: "Modern, airy glass office with city skyline.",
        icon: "🏢",
        image:
            "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COMPOSITION: Headshot. BACKGROUND: Floor-to-ceiling glass windows, out-of-focus city skyline (New York or London) in daylight. LIGHTING: Bright, high-key lighting, clean white tones.",
      ),
      StyleOption(
        id: "ceo_keynote",
        name: "The Keynote",
        description: "On stage, speaking to the industry.",
        icon: "🎤",
        image:
            "https://images.unsplash.com/photo-1475721027785-f74eccf877e2?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COMPOSITION: Action shot, mid-speech or looking out. BACKGROUND: Dark stage depth, distant bokeh stage lights. LIGHTING: Spotlight effect on subject, rim lighting on shoulders. MOOD: Visionary leader.",
      ),
      StyleOption(
        id: "ceo_jet",
        name: "Private Aviation",
        description: "The ultimate status symbol.",
        icon: "✈️",
        image:
            "https://images.unsplash.com/photo-1540962351574-72997f971b55?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COMPOSITION: Seated comfortably. BACKGROUND: Cream leather interior of a Gulfstream jet, oval window. LIGHTING: Soft warm interior cabin lighting mixed with daylight from window.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.BIRTHDAY_LUXE,
    name: "The Anniversary Suite",
    price: "\$149",
    category: 'premium',
    assetCount: 5,
    description:
        "Luxury celebratory photos featuring high-end international locations and vibrant styling.",
    features: [
      "5 Celebration Sets",
      "Dubai/Paris Locations",
      "Gold/Silk Styling",
      "Instant Delivery",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt: """IDENTITY INTEGRITY: 1:1 facial identity preservation.
WARDROBE: High-fashion luxury evening wear.
TEXTURE: Shimmering reflections, silk sheen, vibrant colors, radiant healthy skin glow.""",
    styles: [
      StyleOption(
        id: "luxe_paris",
        name: "Parisian Balcony",
        description: "Eiffel Tower view at sunset.",
        icon: "🗼",
        image:
            "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Haussmann style balcony, out-of-focus Eiffel Tower in distance. LIGHTING: Soft pink/purple sunset sky. WARDROBE: Haute couture evening gown or tuxedo.",
      ),
      StyleOption(
        id: "luxe_yacht",
        name: "Monaco Yacht",
        description: "Sunset on the deck of a super-yacht.",
        icon: "🛥️",
        image:
            "https://images.unsplash.com/photo-1569263979104-865ab7dd8d3d?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Teak deck, chrome railings, deep blue ocean water. LIGHTING: Golden hour sun hitting the face directly. WARDROBE: White linen or silk.",
      ),
      StyleOption(
        id: "luxe_gala",
        name: "Met Gala Entrance",
        description: "Red carpet flash photography event.",
        icon: "📸",
        image:
            "https://images.unsplash.com/photo-1566737236500-c8ac43014a67?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Red carpet, blurred photographers in background. LIGHTING: Direct flash simulation, high contrast, popping colors. MOOD: Celebrity status.",
      ),
      StyleOption(
        id: "luxe_dinner",
        name: "Michelin Dining",
        description: "Intimate candlelit dinner setting.",
        icon: "🍴",
        image:
            "https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Dark luxury restaurant, crystal glassware, candlelight bokeh. LIGHTING: Warm candlelight glow on face (Rembrandt style). MOOD: Intimate, romantic, expensive.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.CINEMATIC_NOIR,
    name: "The Cinematic Noir Elite",
    price: "\$199",
    category: 'premium',
    assetCount: 4,
    description:
        "Moody, high-art portraits using master Chiaroscuro techniques for dramatic visual impact.",
    features: [
      "8 Fine Art Prints",
      "Low-Key Lighting",
      "Shadow Sculpting",
      "Monochrome Option",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt: """IDENTITY INTEGRITY: 1:1 facial identity preservation.
COMPOSITION: Moody art-gallery portrait. Deep shadows sculpting the contours of the face.
TEXTURE: Extreme focus on the illuminated eye and iris. Velvety deep blacks with zero digital noise. Micro-pores visible in highlights.""",
    styles: [
      StyleOption(
        id: "noir_split",
        name: "Split Lighting",
        description: "Dramatic side lighting, half face in shadow.",
        icon: "🌗",
        image:
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "LIGHTING: Split lighting pattern. Key light at 90 degrees. One side of face fully illuminated, other in deep shadow. BACKGROUND: Pure black.",
      ),
      StyleOption(
        id: "noir_rembrandt",
        name: "Classic Rembrandt",
        description: "The triangle of light.",
        icon: "🎨",
        image:
            "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "LIGHTING: Key light at 45 degrees high. Distinct triangle of light on the shadowed cheek. BACKGROUND: Dark textured canvas.",
      ),
      StyleOption(
        id: "noir_silhouette",
        name: "Rim Silhouette",
        description: "Outline of the profile.",
        icon: "👤",
        image:
            "https://images.unsplash.com/photo-1496345875659-11f7dd282d1d?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "LIGHTING: Backlight only (Rim light). Subject is mostly silhouetted with only the edge of the profile glowing. BACKGROUND: Dark grey fog.",
      ),
      StyleOption(
        id: "noir_neon",
        name: "Neon Noir",
        description: "Blade Runner style colors.",
        icon: "🌃",
        image:
            "https://images.unsplash.com/photo-1581337204873-ef36aa186caa?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "LIGHTING: Cyan and Magenta gels. One side blue, one side pink. BACKGROUND: Wet rainy window or dark street reflection.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.ENTERTAINER,
    name: "The Entertainer",
    price: "\$299",
    category: 'premium',
    assetCount: 5,
    description:
        "Celebrity-standard publicity photos for artists, actors, and public speakers.",
    features: [
      "10 Portfolio Assets",
      "Stage Lighting Sets",
      "Charismatic Styling",
      "Commercial License",
    ],
    exampleImage:
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt: """IDENTITY INTEGRITY: Absolute 1:1 facial accuracy.
TEXTURE: Highly detailed skin texture, realistic stubble, subtle moisture on skin, cinematic haze catching light rays.""",
    styles: [
      StyleOption(
        id: "ent_headshot",
        name: "The Casting Call",
        description: "Clean, neutral theatrical headshot.",
        icon: "🎭",
        image:
            "https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COMPOSITION: Tight headshot. BACKGROUND: Neutral grey seamless paper. LIGHTING: Butterfly lighting (Paramount), very flattering, fills in shadows.",
      ),
      StyleOption(
        id: "ent_stage",
        name: "Spotlight",
        description: "Dramatic performance lighting.",
        icon: "🔦",
        image:
            "https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COMPOSITION: Dynamic pose. BACKGROUND: Black stage. LIGHTING: Hard spotlight from above, atmospheric haze/smoke visible in the light beam.",
      ),
      StyleOption(
        id: "ent_editorial",
        name: "Magazine Cover",
        description: "Vanity Fair style editorial.",
        icon: "📰",
        image:
            "https://images.unsplash.com/photo-1534030347209-7147fd69a3f2?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COMPOSITION: Leaning forward, intense gaze. BACKGROUND: Hand-painted canvas backdrop (Annie Leibovitz style). LIGHTING: Large umbrella source, soft but directional.",
      ),
      StyleOption(
        id: "ent_paparazzi",
        name: "Street Candid",
        description: "Walking down the street, looking amazing.",
        icon: "🚶",
        image:
            "https://images.unsplash.com/photo-1485230405346-71acb9518d9c?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "COMPOSITION: Full body walking towards camera. BACKGROUND: Blurred city street day. LIGHTING: Natural sun with fill flash. MOOD: Busy, important, famous.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.SNAPSHOT_DAILY,
    name: "Express Daily Snapshot",
    price: "\$0.99",
    category: 'snapshot',
    assetCount: 1,
    description:
        "One high-fidelity AI portrait. Fast, simple, and perfect for a daily refresh.",
    features: ["1 Master Shot", "Standard Rig", "Auto-Style Protocol"],
    exampleImage:
        "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial accuracy. COMPOSITION: Professional headshot. LIGHTING: Soft studio light. TEXTURE: Realistic skin details.",
    styles: [
      StyleOption(
        id: "daily_clean",
        name: "Clean Studio",
        description: "Pure, neutral studio look.",
        icon: "⚪",
        image:
            "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Minimalist grey studio. LIGHTING: Bright, even butterfly lighting.",
      ),
    ],
  ),
  PackageDetails(
    id: PortraitPackage.SNAPSHOT_STYLE,
    name: "Style Refresh Mini",
    price: "\$1.99",
    category: 'snapshot',
    assetCount: 1,
    description:
        "One premium stylized generation. Cinematic quality for an entry-level price.",
    features: ["1 Stylized Shot", "Cinematic Rig", "Custom Style Target"],
    exampleImage:
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=800&h=1000",
    basePrompt:
        "IDENTITY INTEGRITY: 1:1 facial accuracy. COMPOSITION: Cinematic portrait. TEXTURE: Film-grade grain and depth.",
    styles: [
      StyleOption(
        id: "style_film",
        name: "35mm Film",
        description: "Classic analog aesthetic.",
        icon: "🎞️",
        image:
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=400",
        promptAddition:
            "BACKGROUND: Out of focus urban lights. LIGHTING: Natural light with subtle halation. MOOD: Moody, organic.",
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
