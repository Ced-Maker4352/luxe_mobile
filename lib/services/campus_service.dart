import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CampusService {
  static final CampusService _instance = CampusService._internal();
  factory CampusService() => _instance;
  CampusService._internal();

  static const String _ua =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36";

  Future<List<Map<String, dynamic>>> searchSchoolsByZip(String zipCode) async {
    List<Map<String, dynamic>> schools = [];
    debugPrint("CampusService: Searching for $zipCode...");

    try {
      // 1. Public Schools
      final publicUrl =
          "https://nces.ed.gov/ccd/schoolsearch/school_list.asp?Search=1&Zip=$zipCode";
      debugPrint("CampusService: Fetching $publicUrl");
      final publicRes = await http.get(
        Uri.parse(publicUrl),
        headers: {"User-Agent": _ua},
      );

      if (publicRes.statusCode == 200) {
        // Robust Regex for NCES format
        final matches = RegExp(
          r'href=["'
          ']school_detail\.asp\?[^>"'
          ']+["'
          '][^>]*>([^<]+)<\/a>',
          caseSensitive: false,
        ).allMatches(publicRes.body);

        debugPrint("CampusService: Found ${matches.length} public schools.");

        for (final match in matches) {
          final name = match.group(1)?.trim() ?? "";
          if (name.isNotEmpty && !schools.any((s) => s['name'] == name)) {
            schools.add({
              "name": _toTitleCase(name),
              "city": "Unknown",
              "state": "",
              "zip": zipCode,
            });
          }
        }
      } else {
        debugPrint("CampusService: Public IP error ${publicRes.statusCode}");
      }

      // 2. Private Schools
      if (schools.isEmpty) {
        final privUrl =
            "https://nces.ed.gov/surveys/pss/privateschoolsearch/school_list.asp?Search=1&Zip=$zipCode";
        debugPrint("CampusService: Fetching $privUrl");
        final privRes = await http.get(
          Uri.parse(privUrl),
          headers: {"User-Agent": _ua},
        );
        if (privRes.statusCode == 200) {
          final matches = RegExp(
            r'href=["'
            ']school_detail\.asp\?[^>"'
            ']+["'
            '][^>]*>([^<]+)<\/a>',
            caseSensitive: false,
          ).allMatches(privRes.body);

          debugPrint("CampusService: Found ${matches.length} private schools.");

          for (final match in matches) {
            final name = match.group(1)?.trim() ?? "";
            if (name.isNotEmpty && !schools.any((s) => s['name'] == name)) {
              schools.add({
                "name": _toTitleCase(name),
                "city": "Unknown",
                "state": "",
                "zip": zipCode,
              });
            }
          }
        }
      }

      // 3. Colleges
      final collegeUrl = "https://nces.ed.gov/collegenavigator/?zp=$zipCode";
      debugPrint("CampusService: Fetching $collegeUrl");
      final collegeRes = await http.get(
        Uri.parse(collegeUrl),
        headers: {"User-Agent": _ua},
      );
      if (collegeRes.statusCode == 200) {
        final matches = RegExp(
          r'<a href="[^"]+"><strong>([^<]+)</strong></a>',
          caseSensitive: false,
        ).allMatches(collegeRes.body);

        debugPrint("CampusService: Found ${matches.length} colleges.");

        for (final match in matches) {
          final name = match.group(1)?.trim() ?? "";
          if (name.isNotEmpty && !schools.any((s) => s['name'] == name)) {
            schools.add({
              "name": _toTitleCase(name),
              "city": "Unknown",
              "state": "",
              "zip": zipCode,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("CampusService Error: $e");
    }

    return schools.take(100).toList();
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Future<Map<String, dynamic>> discoverSchoolIdentity(String schoolName) async {
    // Default colors
    String primaryColor = "#000000";
    String secondaryColor = "#FFD700";

    final lower = schoolName.toLowerCase();
    if (lower.contains("valley") ||
        lower.contains("university") ||
        lower.contains("state"))
      primaryColor = "#800000";
    if (lower.contains("lake") ||
        lower.contains("ocean") ||
        lower.contains("blue") ||
        lower.contains("sea"))
      primaryColor = "#000080";
    if (lower.contains("forest") ||
        lower.contains("oak") ||
        lower.contains("green"))
      primaryColor = "#006400";
    if (lower.contains("tech") ||
        lower.contains("central") ||
        lower.contains("high"))
      primaryColor = "#000000";

    final domain = schoolName.replaceAll(" ", "").toLowerCase() + ".edu";
    String logoUrl;

    if (lower.contains("highschool") || lower.contains("elementary")) {
      logoUrl =
          "https://ui-avatars.com/api/?name=${Uri.encodeComponent(schoolName)}&background=random";
    } else {
      logoUrl = "https://logo.clearbit.com/$domain";
    }

    return {
      "name": schoolName,
      "colors": [primaryColor, secondaryColor],
      "logo_url": logoUrl,
    };
  }
}
