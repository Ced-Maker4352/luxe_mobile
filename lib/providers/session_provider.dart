import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/types.dart';

class SessionProvider extends ChangeNotifier {
  PackageDetails? _selectedPackage;
  CameraRig? _selectedRig;
  Uint8List? _uploadedImageBytes;
  String? _uploadedImageName;
  final List<GenerationResult> _results = [];
  bool _isGenerating = false;
  StyleOption? _selectedStyle;
  bool _isSingleStyleMode = false;

  PackageDetails? get selectedPackage => _selectedPackage;
  CameraRig? get selectedRig => _selectedRig;
  Uint8List? get uploadedImageBytes => _uploadedImageBytes;
  String? get uploadedImageName => _uploadedImageName;
  List<GenerationResult> get results => _results;
  bool get isGenerating => _isGenerating;
  StyleOption? get selectedStyle => _selectedStyle;
  bool get isSingleStyleMode => _isSingleStyleMode;

  void addResult(GenerationResult result) {
    _results.insert(0, result);
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
}
