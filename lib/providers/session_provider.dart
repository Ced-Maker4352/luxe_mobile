import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/types.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class SessionProvider extends ChangeNotifier {
  // === SELECTION STATE ===
  PackageDetails? _selectedPackage;
  CameraRig? _selectedRig;
  StyleOption? _selectedStyle;
  bool _isSingleStyleMode = false;
  String? _soloGender; // Nullable for toggle
  bool _preserveAgeAndBody = true;
  bool _isEnterpriseMode = false;

  // === GENERATION STATE ===
  bool _isGenerating = false;
  final List<GenerationResult> _results = [];

  // === IDENTITY LOCK STATE (Multi-Image Support) ===
  final List<Uint8List> _identityImages = [];

  // Backward compatibility: Returns the first image or null
  Uint8List? get uploadedImageBytes =>
      _identityImages.isNotEmpty ? _identityImages.first : null;

  String? _uploadedImageName;
  String? get uploadedImageName => _uploadedImageName;

  // === STITCH STUDIO STATE ===
  final List<StitchSubject> _stitchImages = [];
  String _stitchVibe = 'individual'; // 'matching', 'individual'

  // === VIRTUAL TRY-ON STATE ===
  Uint8List? _clothingReferenceBytes;
  String? _clothingReferenceName;

  // === CAMPUS STUDIO STATE ===
  SchoolCampus? _selectedCampus;
  Uint8List? _campusReferenceBytes;

  // === CUSTOM BACKGROUND STATE ===
  Uint8List? _backgroundReferenceBytes;
  String? _backgroundReferenceName;

  // === USER PROFILE & CREDITS ===
  UserProfile? _userProfile;

  // === GETTERS ===
  SchoolCampus? get selectedCampus => _selectedCampus;
  Uint8List? get campusReferenceBytes => _campusReferenceBytes;
  bool get hasCampusReference => _campusReferenceBytes != null;
  PackageDetails? get selectedPackage => _selectedPackage;
  CameraRig? get selectedRig => _selectedRig;
  StyleOption? get selectedStyle => _selectedStyle;
  bool get isSingleStyleMode => _isSingleStyleMode;
  String get soloGender => _soloGender ?? 'female';
  bool get preserveAgeAndBody => _preserveAgeAndBody;
  bool get isEnterpriseMode => _isEnterpriseMode;

  bool get isGenerating => _isGenerating;
  List<GenerationResult> get results => List.unmodifiable(_results);

  List<Uint8List> get identityImages => _identityImages;
  bool get hasUploadedImage => _identityImages.isNotEmpty;

  List<StitchSubject> get stitchImages => _stitchImages;
  String get stitchVibe => _stitchVibe;

  Uint8List? get clothingReferenceBytes => _clothingReferenceBytes;
  String? get clothingReferenceName => _clothingReferenceName;
  bool get hasClothingReference => _clothingReferenceBytes != null;

  Uint8List? get backgroundReferenceBytes => _backgroundReferenceBytes;
  String? get backgroundReferenceName => _backgroundReferenceName;
  bool get hasBackgroundReference => _backgroundReferenceBytes != null;

  UserProfile? get userProfile => _userProfile;

  // === SETTERS & METHODS (Triggering re-analysis) ===

  void setSelectedPackage(PackageDetails package) {
    _selectedPackage = package;
    notifyListeners();
  }

  void setSelectedRig(CameraRig? rig) {
    _selectedRig = rig;
    notifyListeners();
  }

  void setSelectedStyle(StyleOption? style) {
    _selectedStyle = style;
    notifyListeners();
  }

  void toggleSingleStyleMode(bool enabled) {
    _isSingleStyleMode = enabled;
    notifyListeners();
  }

  void setSoloGender(String? gender) {
    _soloGender = gender;
    notifyListeners();
  }

  String? _selectedBodyType; // Nullable
  String get selectedBodyType => _selectedBodyType ?? 'Fit';

  void setSelectedBodyType(String? bodyType) {
    _selectedBodyType = bodyType;
    notifyListeners();
  }

  void setPreserveAgeAndBody(bool value) {
    _preserveAgeAndBody = value;
    notifyListeners();
  }

  void setEnterpriseMode(bool value) {
    _isEnterpriseMode = value;
    notifyListeners();
  }

  void setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  void addResult(GenerationResult result) {
    _results.insert(0, result);
    notifyListeners();
  }

  /// Store a single image (Legacy / First Image) - clears existing list
  void uploadImageBytes(Uint8List bytes, String name) {
    _identityImages.clear();
    _identityImages.add(bytes);
    _uploadedImageName = name;
    notifyListeners();
  }

  /// Add an image to the identity lock list (Max 5)
  void addIdentityImage(Uint8List bytes) {
    if (_identityImages.length < 5) {
      _identityImages.add(bytes);
      notifyListeners();
    }
  }

  /// Remove an image from the identity lock list
  void removeIdentityImage(int index) {
    if (index >= 0 && index < _identityImages.length) {
      _identityImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Legacy method for compatibility - stores name only
  void uploadImage(String path) {
    _uploadedImageName = path;
    notifyListeners();
  }

  /// Clear only the uploaded solo portrait images
  void clearUploadedImage() {
    _identityImages.clear();
    _uploadedImageName = null;
    notifyListeners();
  }

  /// Clear the current session
  void clearSession() {
    _identityImages.clear();
    _uploadedImageName = null;
    _results.clear();
    _isGenerating = false;
    _selectedStyle = null; // Clear style
    _isSingleStyleMode = false; // Reset mode
    // Keep rig and package as they might be defaults
    notifyListeners();
  }

  // === STITCH METHODS ===
  void addStitchImage(Uint8List bytes, {String gender = 'female'}) {
    if (_stitchImages.length < 5) {
      _stitchImages.add(StitchSubject(bytes: bytes, gender: gender));
      notifyListeners();
    }
  }

  void updateStitchGender(int index, String gender) {
    if (index >= 0 && index < _stitchImages.length) {
      _stitchImages[index].gender = gender;
      notifyListeners();
    }
  }

  void removeStitchImage(int index) {
    if (index >= 0 && index < _stitchImages.length) {
      _stitchImages.removeAt(index);
      notifyListeners();
    }
  }

  void setStitchVibe(String vibe) {
    _stitchVibe = vibe;
    notifyListeners();
  }

  // === CLOTHING METHODS ===
  void uploadClothingReference(Uint8List bytes, String name) {
    _clothingReferenceBytes = bytes;
    _clothingReferenceName = name;
    notifyListeners();
  }

  void clearClothingReference() {
    _clothingReferenceBytes = null;
    _clothingReferenceName = null;
    notifyListeners();
  }

  // === BACKGROUND METHODS ===
  void uploadBackgroundReference(Uint8List bytes, String name) {
    _backgroundReferenceBytes = bytes;
    _backgroundReferenceName = name;
    notifyListeners();
  }

  void clearBackgroundReference() {
    _backgroundReferenceBytes = null;
    _backgroundReferenceName = null;
    notifyListeners();
  }

  // === CAMPUS STUDIO METHODS ===
  void setCampus(SchoolCampus? campus) {
    _selectedCampus = campus;
    notifyListeners();
  }

  void uploadCampusLogo(Uint8List bytes) {
    _campusReferenceBytes = bytes;
    notifyListeners();
  }

  void clearCampus() {
    _selectedCampus = null;
    _campusReferenceBytes = null;
    notifyListeners();
  }

  // === CREDIT METHODS ===
  Future<void> fetchUserProfile() async {
    final data = await AuthService().getUserProfile();
    debugPrint("SessionProvider: Fetched user profile: $data");
    if (data != null) {
      _userProfile = UserProfile.fromJson(data);
      debugPrint(
        "SessionProvider: Parsed profile - Photos: ${_userProfile?.photoGenerations}, Video: ${_userProfile?.videoGenerations}",
      );
      notifyListeners();
    } else {
      debugPrint("SessionProvider: User profile data is null");
    }
  }

  // === ACCESS CONTROL ===
  bool canAccessFeature(String feature) {
    if (_userProfile == null) return false;
    final tier = _userProfile!.subscriptionTier?.toLowerCase() ?? 'starter';

    // Robust checking for tier levels
    final isProOrAbove =
        tier.contains('creator') || // Added Creator Pack ($29)
        tier.contains('pro') ||
        tier.contains('unlimited') ||
        tier.contains('agency') ||
        tier.contains('sub_monthly_49') ||
        tier.contains('sub_monthly_99') ||
        tier.contains('professionalshoot') ||
        tier.contains('agencymaster');

    final isUnlimitedOrAbove =
        tier.contains('unlimited') ||
        tier.contains('agency') ||
        tier.contains('sub_monthly_99') ||
        tier.contains('agencymaster');

    switch (feature) {
      case 'video':
      case 'stitch':
      case 'retouch':
      case 'virtual_tryon':
      case 'custom_backdrop':
      case 'body_type':
        return isProOrAbove;
      case 'unlimited_styles':
      case 'campus_studio':
        return isUnlimitedOrAbove;
      default:
        return true;
    }
  }

  // Call this after successful generation to decrement locally or refresh
  Future<void> decrementCredit(String type) async {
    if (_userProfile == null) return;

    // Call service to update DB
    await AuthService().decrementUserCredit(type);

    // Refresh local state to match server
    await fetchUserProfile();
  }
}
