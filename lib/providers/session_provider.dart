import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/types.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class SessionProvider extends ChangeNotifier {
  PackageDetails? _selectedPackage;
  CameraRig? _selectedRig;
  Uint8List? _uploadedImageBytes;
  String? _uploadedImageName;
  final List<GenerationResult> _results = [];
  bool _isGenerating = false;
  StyleOption? _selectedStyle;
  bool _isSingleStyleMode = false;
  bool _preserveAgeAndBody = true;
  String _soloGender = 'female'; // Default to female

  PackageDetails? get selectedPackage => _selectedPackage;
  CameraRig? get selectedRig => _selectedRig;
  Uint8List? get uploadedImageBytes => _uploadedImageBytes;
  String? get uploadedImageName => _uploadedImageName;
  List<GenerationResult> get results => _results;
  bool get isGenerating => _isGenerating;
  StyleOption? get selectedStyle => _selectedStyle;
  bool get isSingleStyleMode => _isSingleStyleMode;
  bool get preserveAgeAndBody => _preserveAgeAndBody;
  String get soloGender => _soloGender;

  void addResult(GenerationResult result) {
    _results.insert(0, result);
    notifyListeners();
  }

  void setPreserveAgeAndBody(bool val) {
    _preserveAgeAndBody = val;
    notifyListeners();
  }

  void setSoloGender(String gender) {
    _soloGender = gender;
    notifyListeners();
  }

  void setGenerating(bool val) {
    _isGenerating = val;
    notifyListeners();
  }

  void setSingleStyleMode(bool val) {
    _isSingleStyleMode = val;
    notifyListeners();
  }

  void selectPackage(PackageDetails package) {
    _selectedPackage = package;
    notifyListeners();
  }

  void selectRig(CameraRig rig) {
    _selectedRig = rig;
    notifyListeners();
  }

  void selectStyle(StyleOption style) {
    _selectedStyle = style;
    _isSingleStyleMode = true;
    notifyListeners();
  }

  /// Store image bytes directly (works on web and mobile)
  void uploadImageBytes(Uint8List bytes, String name) {
    _uploadedImageBytes = bytes;
    _uploadedImageName = name;
    notifyListeners();
  }

  /// Legacy method for compatibility - stores name only
  void uploadImage(String path) {
    _uploadedImageName = path;
    notifyListeners();
  }

  /// Check if we have a valid image uploaded
  bool get hasUploadedImage => _uploadedImageBytes != null;

  /// Clear only the uploaded solo portrait image (without clearing entire session)
  void clearUploadedImage() {
    _uploadedImageBytes = null;
    _uploadedImageName = null;
    notifyListeners();
  }

  /// Clear the current session
  void clearSession() {
    _uploadedImageBytes = null;
    _uploadedImageName = null;
    _results.clear();
    _isGenerating = false;
    _selectedStyle = null; // Clear style
    _isSingleStyleMode = false; // Reset mode
    notifyListeners();
  }

  // STITCH STUDIO STATE
  final List<StitchSubject> _stitchImages = [];
  String _stitchVibe = 'individual'; // 'matching', 'individual'

  // VIRTUAL TRY-ON STATE
  Uint8List? _clothingReferenceBytes;
  String? _clothingReferenceName;

  List<StitchSubject> get stitchImages => _stitchImages;
  String get stitchVibe => _stitchVibe;
  Uint8List? get clothingReferenceBytes => _clothingReferenceBytes;
  String? get clothingReferenceName => _clothingReferenceName;
  bool get hasClothingReference => _clothingReferenceBytes != null;

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

  // USER PROFILE & CREDITS
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  Future<void> fetchUserProfile() async {
    final data = await AuthService().getUserProfile();
    if (data != null) {
      _userProfile = UserProfile.fromJson(data);
      notifyListeners();
    }
  }

  // Call this after successful generation to decrement locally or refresh
  Future<void> decrementCredit(String type) async {
    if (_userProfile == null) return;

    // Call service to update DB
    await AuthService().decrementUserCredit(type);

    // Refresh local state to match server
    fetchUserProfile();
  }
}
