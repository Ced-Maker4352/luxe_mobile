import 'package:flutter/foundation.dart';

class CampusService {
  static final CampusService _instance = CampusService._internal();
  factory CampusService() => _instance;
  CampusService._internal();

  // Real school database organized by zip code prefixes (first 3 digits)
  static final Map<String, List<Map<String, dynamic>>> _schoolDatabase = {
    // Georgia - Atlanta Metro Area (300xx, 301xx, 302xx, 303xx)
    '300': [
      {
        'name': 'Georgia State University',
        'city': 'Atlanta',
        'state': 'GA',
        'type': 'University',
        'colors': ['#0039A6', '#FFFFFF'],
        'mascot': 'Panthers',
      },
      {
        'name': 'Georgia Tech',
        'city': 'Atlanta',
        'state': 'GA',
        'type': 'University',
        'colors': ['#B3A369', '#003057'],
        'mascot': 'Yellow Jackets',
      },
      {
        'name': 'Emory University',
        'city': 'Atlanta',
        'state': 'GA',
        'type': 'University',
        'colors': ['#012169', '#F2A900'],
        'mascot': 'Eagles',
      },
      {
        'name': 'Spelman College',
        'city': 'Atlanta',
        'state': 'GA',
        'type': 'College',
        'colors': ['#0033A0', '#FFFFFF'],
        'mascot': 'Jaguars',
      },
      {
        'name': 'Morehouse College',
        'city': 'Atlanta',
        'state': 'GA',
        'type': 'College',
        'colors': ['#800000', '#FFFFFF'],
        'mascot': 'Maroon Tigers',
      },
      {
        'name': 'Clark Atlanta University',
        'city': 'Atlanta',
        'state': 'GA',
        'type': 'University',
        'colors': ['#CC0000', '#000000'],
        'mascot': 'Panthers',
      },
      {
        'name': 'Grady High School',
        'city': 'Atlanta',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#808080', '#FFD700'],
        'mascot': 'Knights',
      },
      {
        'name': 'North Atlanta High School',
        'city': 'Atlanta',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Warriors',
      },
    ],
    '301': [
      {
        'name': 'Kennesaw State University',
        'city': 'Kennesaw',
        'state': 'GA',
        'type': 'University',
        'colors': ['#000000', '#FDBB30'],
        'mascot': 'Owls',
      },
      {
        'name': 'Life University',
        'city': 'Marietta',
        'state': 'GA',
        'type': 'University',
        'colors': ['#006341', '#FFFFFF'],
        'mascot': 'Running Eagles',
      },
      {
        'name': 'Chattahoochee High School',
        'city': 'Johns Creek',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#00205B', '#C8102E'],
        'mascot': 'Cougars',
      },
      {
        'name': 'Lassiter High School',
        'city': 'Marietta',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#0033A0', '#FFFFFF'],
        'mascot': 'Trojans',
      },
      {
        'name': 'Walton High School',
        'city': 'Marietta',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#800000', '#FFD700'],
        'mascot': 'Raiders',
      },
    ],
    '302': [
      {
        'name': 'University of West Georgia',
        'city': 'Carrollton',
        'state': 'GA',
        'type': 'University',
        'colors': ['#00205B', '#C8102E'],
        'mascot': 'Wolves',
      },
      {
        'name': 'Carrollton High School',
        'city': 'Carrollton',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Trojans',
      },
    ],
    '303': [
      {
        'name': 'Gwinnett Technical College',
        'city': 'Lawrenceville',
        'state': 'GA',
        'type': 'College',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Tigers',
      },
      {
        'name': 'Georgia Gwinnett College',
        'city': 'Lawrenceville',
        'state': 'GA',
        'type': 'College',
        'colors': ['#003057', '#C8102E'],
        'mascot': 'Grizzlies',
      },
      {
        'name': 'Brookwood High School',
        'city': 'Snellville',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#800000', '#FFFFFF'],
        'mascot': 'Broncos',
      },
      {
        'name': 'Parkview High School',
        'city': 'Lilburn',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Panthers',
      },
      {
        'name': 'Mill Creek High School',
        'city': 'Hoschton',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#000000', '#FFD700'],
        'mascot': 'Hawks',
      },
      {
        'name': 'Collins Hill High School',
        'city': 'Suwanee',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#006341', '#FFD700'],
        'mascot': 'Eagles',
      },
      {
        'name': 'Snellville Middle School',
        'city': 'Snellville',
        'state': 'GA',
        'type': 'Middle School',
        'colors': ['#00205B', '#C8102E'],
        'mascot': 'Panthers',
      },
      {
        'name': 'Shiloh High School',
        'city': 'Snellville',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#0033A0', '#FFD700'],
        'mascot': 'Generals',
      },
      {
        'name': 'South Gwinnett High School',
        'city': 'Snellville',
        'state': 'GA',
        'type': 'High School',
        'colors': ['#006341', '#FFFFFF'],
        'mascot': 'Comets',
      },
    ],
    // California - Los Angeles (900xx - 902xx)
    '900': [
      {
        'name': 'UCLA',
        'city': 'Los Angeles',
        'state': 'CA',
        'type': 'University',
        'colors': ['#2774AE', '#FFD100'],
        'mascot': 'Bruins',
      },
      {
        'name': 'USC',
        'city': 'Los Angeles',
        'state': 'CA',
        'type': 'University',
        'colors': ['#990000', '#FFC72C'],
        'mascot': 'Trojans',
      },
      {
        'name': 'Loyola Marymount University',
        'city': 'Los Angeles',
        'state': 'CA',
        'type': 'University',
        'colors': ['#00205B', '#C8102E'],
        'mascot': 'Lions',
      },
      {
        'name': 'Los Angeles High School',
        'city': 'Los Angeles',
        'state': 'CA',
        'type': 'High School',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Romans',
      },
    ],
    '902': [
      {
        'name': 'El Camino College',
        'city': 'Torrance',
        'state': 'CA',
        'type': 'College',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Warriors',
      },
      {
        'name': 'Torrance High School',
        'city': 'Torrance',
        'state': 'CA',
        'type': 'High School',
        'colors': ['#000000', '#FFD700'],
        'mascot': 'Tartars',
      },
    ],
    // New York (100xx - 104xx)
    '100': [
      {
        'name': 'NYU',
        'city': 'New York',
        'state': 'NY',
        'type': 'University',
        'colors': ['#57068C', '#FFFFFF'],
        'mascot': 'Violets',
      },
      {
        'name': 'Columbia University',
        'city': 'New York',
        'state': 'NY',
        'type': 'University',
        'colors': ['#9BCBEB', '#FFFFFF'],
        'mascot': 'Lions',
      },
      {
        'name': 'Pace University',
        'city': 'New York',
        'state': 'NY',
        'type': 'University',
        'colors': ['#003087', '#FFD700'],
        'mascot': 'Setters',
      },
      {
        'name': 'Stuyvesant High School',
        'city': 'New York',
        'state': 'NY',
        'type': 'High School',
        'colors': ['#00205B', '#FFFFFF'],
        'mascot': 'Peglegs',
      },
    ],
    '104': [
      {
        'name': 'Bronx High School of Science',
        'city': 'Bronx',
        'state': 'NY',
        'type': 'High School',
        'colors': ['#800000', '#FFFFFF'],
        'mascot': 'Wolverines',
      },
      {
        'name': 'Fordham University',
        'city': 'Bronx',
        'state': 'NY',
        'type': 'University',
        'colors': ['#800000', '#FFFFFF'],
        'mascot': 'Rams',
      },
    ],
    // Texas - Houston (770xx - 774xx)
    '770': [
      {
        'name': 'University of Houston',
        'city': 'Houston',
        'state': 'TX',
        'type': 'University',
        'colors': ['#C8102E', '#FFFFFF'],
        'mascot': 'Cougars',
      },
      {
        'name': 'Rice University',
        'city': 'Houston',
        'state': 'TX',
        'type': 'University',
        'colors': ['#00205B', '#D1D5D8'],
        'mascot': 'Owls',
      },
      {
        'name': 'Houston Baptist University',
        'city': 'Houston',
        'state': 'TX',
        'type': 'University',
        'colors': ['#FF6600', '#00205B'],
        'mascot': 'Huskies',
      },
      {
        'name': 'Bellaire High School',
        'city': 'Bellaire',
        'state': 'TX',
        'type': 'High School',
        'colors': ['#C8102E', '#000000'],
        'mascot': 'Cardinals',
      },
    ],
    '750': [
      {
        'name': 'SMU',
        'city': 'Dallas',
        'state': 'TX',
        'type': 'University',
        'colors': ['#C8102E', '#003087'],
        'mascot': 'Mustangs',
      },
      {
        'name': 'University of Texas at Dallas',
        'city': 'Richardson',
        'state': 'TX',
        'type': 'University',
        'colors': ['#C75B12', '#008542'],
        'mascot': 'Comets',
      },
      {
        'name': 'Dallas Baptist University',
        'city': 'Dallas',
        'state': 'TX',
        'type': 'University',
        'colors': ['#00205B', '#C8102E'],
        'mascot': 'Patriots',
      },
      {
        'name': 'Highland Park High School',
        'city': 'Dallas',
        'state': 'TX',
        'type': 'High School',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Scots',
      },
    ],
    // Florida - Miami (331xx - 333xx)
    '331': [
      {
        'name': 'University of Miami',
        'city': 'Coral Gables',
        'state': 'FL',
        'type': 'University',
        'colors': ['#F47321', '#005030'],
        'mascot': 'Hurricanes',
      },
      {
        'name': 'Florida International University',
        'city': 'Miami',
        'state': 'FL',
        'type': 'University',
        'colors': ['#081E3F', '#B6862C'],
        'mascot': 'Panthers',
      },
      {
        'name': 'Miami Dade College',
        'city': 'Miami',
        'state': 'FL',
        'type': 'College',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Sharks',
      },
      {
        'name': 'Coral Gables High School',
        'city': 'Coral Gables',
        'state': 'FL',
        'type': 'High School',
        'colors': ['#C8102E', '#000000'],
        'mascot': 'Cavaliers',
      },
    ],
    // Illinois - Chicago (606xx - 608xx)
    '606': [
      {
        'name': 'University of Chicago',
        'city': 'Chicago',
        'state': 'IL',
        'type': 'University',
        'colors': ['#800000', '#FFFFFF'],
        'mascot': 'Maroons',
      },
      {
        'name': 'DePaul University',
        'city': 'Chicago',
        'state': 'IL',
        'type': 'University',
        'colors': ['#00205B', '#C8102E'],
        'mascot': 'Blue Demons',
      },
      {
        'name': 'Northwestern University',
        'city': 'Evanston',
        'state': 'IL',
        'type': 'University',
        'colors': ['#4E2A84', '#FFFFFF'],
        'mascot': 'Wildcats',
      },
      {
        'name': 'Whitney Young High School',
        'city': 'Chicago',
        'state': 'IL',
        'type': 'High School',
        'colors': ['#800000', '#FFD700'],
        'mascot': 'Dolphins',
      },
      {
        'name': 'Lane Tech High School',
        'city': 'Chicago',
        'state': 'IL',
        'type': 'High School',
        'colors': ['#800000', '#FFFFFF'],
        'mascot': 'Indians',
      },
    ],
    // Arizona - Phoenix (850xx - 853xx)
    '850': [
      {
        'name': 'Arizona State University',
        'city': 'Tempe',
        'state': 'AZ',
        'type': 'University',
        'colors': ['#8C1D40', '#FFC627'],
        'mascot': 'Sun Devils',
      },
      {
        'name': 'Grand Canyon University',
        'city': 'Phoenix',
        'state': 'AZ',
        'type': 'University',
        'colors': ['#522398', '#FFFFFF'],
        'mascot': 'Antelopes',
      },
      {
        'name': 'Phoenix Union High School',
        'city': 'Phoenix',
        'state': 'AZ',
        'type': 'High School',
        'colors': ['#FFC627', '#000000'],
        'mascot': 'Coyotes',
      },
    ],
    // Washington - Seattle (980xx - 981xx)
    '980': [
      {
        'name': 'University of Washington',
        'city': 'Seattle',
        'state': 'WA',
        'type': 'University',
        'colors': ['#4B2E83', '#B7A57A'],
        'mascot': 'Huskies',
      },
      {
        'name': 'Seattle University',
        'city': 'Seattle',
        'state': 'WA',
        'type': 'University',
        'colors': ['#AA0000', '#FFFFFF'],
        'mascot': 'Redhawks',
      },
      {
        'name': 'Garfield High School',
        'city': 'Seattle',
        'state': 'WA',
        'type': 'High School',
        'colors': ['#4B2E83', '#FFD700'],
        'mascot': 'Bulldogs',
      },
    ],
    // Massachusetts - Boston (021xx - 022xx)
    '021': [
      {
        'name': 'Harvard University',
        'city': 'Cambridge',
        'state': 'MA',
        'type': 'University',
        'colors': ['#A51C30', '#FFFFFF'],
        'mascot': 'Crimson',
      },
      {
        'name': 'MIT',
        'city': 'Cambridge',
        'state': 'MA',
        'type': 'University',
        'colors': ['#8A8B8C', '#A31F34'],
        'mascot': 'Engineers',
      },
      {
        'name': 'Boston University',
        'city': 'Boston',
        'state': 'MA',
        'type': 'University',
        'colors': ['#CC0000', '#FFFFFF'],
        'mascot': 'Terriers',
      },
      {
        'name': 'Northeastern University',
        'city': 'Boston',
        'state': 'MA',
        'type': 'University',
        'colors': ['#C8102E', '#000000'],
        'mascot': 'Huskies',
      },
      {
        'name': 'Boston Latin School',
        'city': 'Boston',
        'state': 'MA',
        'type': 'High School',
        'colors': ['#4B2E83', '#FFFFFF'],
        'mascot': 'Wolfpack',
      },
    ],
    // Pennsylvania - Philadelphia (190xx - 191xx)
    '190': [
      {
        'name': 'University of Pennsylvania',
        'city': 'Philadelphia',
        'state': 'PA',
        'type': 'University',
        'colors': ['#011F5B', '#990000'],
        'mascot': 'Quakers',
      },
      {
        'name': 'Temple University',
        'city': 'Philadelphia',
        'state': 'PA',
        'type': 'University',
        'colors': ['#9D2235', '#FFFFFF'],
        'mascot': 'Owls',
      },
      {
        'name': 'Drexel University',
        'city': 'Philadelphia',
        'state': 'PA',
        'type': 'University',
        'colors': ['#07294D', '#FFC600'],
        'mascot': 'Dragons',
      },
      {
        'name': 'Central High School',
        'city': 'Philadelphia',
        'state': 'PA',
        'type': 'High School',
        'colors': ['#800000', '#FFD700'],
        'mascot': 'Lancers',
      },
    ],
    // Ohio - Columbus (430xx - 432xx)
    '432': [
      {
        'name': 'Ohio State University',
        'city': 'Columbus',
        'state': 'OH',
        'type': 'University',
        'colors': ['#BB0000', '#666666'],
        'mascot': 'Buckeyes',
      },
      {
        'name': 'Capital University',
        'city': 'Columbus',
        'state': 'OH',
        'type': 'University',
        'colors': ['#4B2E83', '#FFD700'],
        'mascot': 'Crusaders',
      },
      {
        'name': 'Upper Arlington High School',
        'city': 'Columbus',
        'state': 'OH',
        'type': 'High School',
        'colors': ['#006341', '#FFD700'],
        'mascot': 'Golden Bears',
      },
    ],
    // North Carolina - Charlotte (282xx - 283xx)
    '282': [
      {
        'name': 'UNC Charlotte',
        'city': 'Charlotte',
        'state': 'NC',
        'type': 'University',
        'colors': ['#00703C', '#B3A369'],
        'mascot': '49ers',
      },
      {
        'name': 'Queens University',
        'city': 'Charlotte',
        'state': 'NC',
        'type': 'University',
        'colors': ['#003087', '#FFD700'],
        'mascot': 'Royals',
      },
      {
        'name': 'Myers Park High School',
        'city': 'Charlotte',
        'state': 'NC',
        'type': 'High School',
        'colors': ['#00205B', '#FFD700'],
        'mascot': 'Mustangs',
      },
    ],
    // Colorado - Denver (802xx - 803xx)
    '802': [
      {
        'name': 'University of Denver',
        'city': 'Denver',
        'state': 'CO',
        'type': 'University',
        'colors': ['#8B2332', '#FFFFFF'],
        'mascot': 'Pioneers',
      },
      {
        'name': 'Metropolitan State University',
        'city': 'Denver',
        'state': 'CO',
        'type': 'University',
        'colors': ['#003087', '#FFD700'],
        'mascot': 'Roadrunners',
      },
      {
        'name': 'East High School',
        'city': 'Denver',
        'state': 'CO',
        'type': 'High School',
        'colors': ['#C8102E', '#000000'],
        'mascot': 'Angels',
      },
    ],
  };

  Future<List<Map<String, dynamic>>> searchSchoolsByZip(String zipCode) async {
    List<Map<String, dynamic>> schools = [];
    debugPrint("CampusService: Searching for $zipCode...");

    if (zipCode.length < 3) return schools;

    // Get the prefix (first 3 digits)
    final prefix = zipCode.substring(0, 3);

    // Check for exact prefix match
    if (_schoolDatabase.containsKey(prefix)) {
      schools = _schoolDatabase[prefix]!.map((school) {
        return {...school, 'zip': zipCode};
      }).toList();
    }

    // If no exact match, try nearby prefixes
    if (schools.isEmpty) {
      final prefixNum = int.tryParse(prefix);
      if (prefixNum != null) {
        for (int offset = 1; offset <= 5; offset++) {
          // Check both directions
          final lowerPrefix = (prefixNum - offset).toString().padLeft(3, '0');
          final upperPrefix = (prefixNum + offset).toString().padLeft(3, '0');

          if (_schoolDatabase.containsKey(lowerPrefix)) {
            schools = _schoolDatabase[lowerPrefix]!.map((school) {
              return {...school, 'zip': zipCode};
            }).toList();
            debugPrint(
              "CampusService: Found ${schools.length} schools in nearby area $lowerPrefix",
            );
            break;
          }
          if (_schoolDatabase.containsKey(upperPrefix)) {
            schools = _schoolDatabase[upperPrefix]!.map((school) {
              return {...school, 'zip': zipCode};
            }).toList();
            debugPrint(
              "CampusService: Found ${schools.length} schools in nearby area $upperPrefix",
            );
            break;
          }
        }
      }
    }

    // Generate fallback schools for any zip code not in database
    if (schools.isEmpty) {
      schools = _generateFallbackSchools(zipCode);
    }

    debugPrint("CampusService: Found ${schools.length} schools for $zipCode");
    return schools.take(20).toList();
  }

  List<Map<String, dynamic>> _generateFallbackSchools(String zipCode) {
    // Generate realistic school names based on the zip code region
    final cityNames = [
      'Central',
      'Valley',
      'Hillside',
      'Lakeside',
      'Riverside',
      'Meadow',
      'Oak Grove',
      'Maple Ridge',
      'Pine View',
      'Cedar Heights',
    ];

    final schoolTypes = [
      {'suffix': 'High School', 'type': 'High School'},
      {'suffix': 'Middle School', 'type': 'Middle School'},
      {'suffix': 'Academy', 'type': 'Academy'},
      {'suffix': 'Community College', 'type': 'College'},
      {'suffix': 'Technical Institute', 'type': 'College'},
    ];

    final colorSchemes = [
      ['#00205B', '#FFD700'], // Navy & Gold
      ['#800000', '#FFFFFF'], // Maroon & White
      ['#006341', '#FFD700'], // Forest Green & Gold
      ['#000000', '#FF6600'], // Black & Orange
      ['#4B2E83', '#FFFFFF'], // Purple & White
      ['#C8102E', '#000000'], // Red & Black
      ['#003087', '#C8102E'], // Blue & Red
    ];

    final mascots = [
      'Eagles',
      'Tigers',
      'Panthers',
      'Wildcats',
      'Lions',
      'Bears',
      'Bulldogs',
      'Knights',
      'Warriors',
      'Spartans',
    ];

    List<Map<String, dynamic>> fallbackSchools = [];
    final random = zipCode.hashCode.abs();

    for (int i = 0; i < 5; i++) {
      final cityIndex = (random + i) % cityNames.length;
      final typeIndex = i % schoolTypes.length;
      final colorIndex = (random + i * 3) % colorSchemes.length;
      final mascotIndex = (random + i * 7) % mascots.length;

      fallbackSchools.add({
        'name': '${cityNames[cityIndex]} ${schoolTypes[typeIndex]['suffix']}',
        'city': 'Local Area',
        'state': '',
        'zip': zipCode,
        'type': schoolTypes[typeIndex]['type'],
        'colors': colorSchemes[colorIndex],
        'mascot': mascots[mascotIndex],
      });
    }

    return fallbackSchools;
  }

  Future<Map<String, dynamic>> discoverSchoolIdentity(String schoolName) async {
    debugPrint("CampusService: Discovering identity for $schoolName");

    // First, check if this school is in our database
    for (final schools in _schoolDatabase.values) {
      for (final school in schools) {
        if (school['name'] == schoolName) {
          final colors = school['colors'] as List<dynamic>;
          return {
            'name': schoolName,
            'colors': colors.map((c) => c.toString()).toList(),
            'logo_url': _getLogoUrl(schoolName, school['type'] as String?),
            'mascot': school['mascot'],
            'type': school['type'],
          };
        }
      }
    }

    // Default colors based on name analysis
    String primaryColor = "#00205B";
    String secondaryColor = "#FFD700";

    final lower = schoolName.toLowerCase();

    // Color inference from school name
    if (lower.contains('crimson') || lower.contains('cardinal')) {
      primaryColor = "#A51C30";
    } else if (lower.contains('blue') || lower.contains('navy')) {
      primaryColor = "#00205B";
    } else if (lower.contains('green') || lower.contains('forest')) {
      primaryColor = "#006341";
    } else if (lower.contains('gold') || lower.contains('yellow')) {
      primaryColor = "#FFD700";
      secondaryColor = "#000000";
    } else if (lower.contains('purple') || lower.contains('violet')) {
      primaryColor = "#4B2E83";
    } else if (lower.contains('orange')) {
      primaryColor = "#FF6600";
    } else if (lower.contains('maroon') || lower.contains('red')) {
      primaryColor = "#800000";
    } else if (lower.contains('tech') || lower.contains('state')) {
      primaryColor = "#000000";
      secondaryColor = "#FFD700";
    }

    return {
      'name': schoolName,
      'colors': [primaryColor, secondaryColor],
      'logo_url': _getLogoUrl(schoolName, null),
      'mascot': null,
    };
  }

  String _getLogoUrl(String schoolName, String? type) {
    // Generate avatar-style logo for all schools

    // Use ui-avatars for a nice placeholder logo with school initials
    final initials = schoolName
        .split(' ')
        .where(
          (w) =>
              w.isNotEmpty &&
              !['of', 'the', 'and', 'at', 'for'].contains(w.toLowerCase()),
        )
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join('');

    // Pick a background color based on the school name hash
    final colors = [
      '0039A6',
      '800000',
      '006341',
      'B3A369',
      '4B2E83',
      'C8102E',
      '003087',
    ];
    final colorIndex = schoolName.hashCode.abs() % colors.length;
    final bgColor = colors[colorIndex];

    return "https://ui-avatars.com/api/?name=$initials&background=$bgColor&color=ffffff&bold=true&size=200";
  }
}
