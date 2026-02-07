import 'package:flutter/material.dart';
import '../models/types.dart';

class SessionProvider extends ChangeNotifier {
  PackageDetails? _selectedPackage;
  CameraRig? _selectedRig;
  String? _uploadedImagePath;
  final List<GenerationResult> _results = [];
  bool _isGenerating = false;

  PackageDetails? get selectedPackage => _selectedPackage;
  CameraRig? get selectedRig => _selectedRig;
  String? get uploadedImagePath => _uploadedImagePath;
  List<GenerationResult> get results => _results;
  bool get isGenerating => _isGenerating;

  void addResult(GenerationResult result) {
    _results.insert(0, result);
    notifyListeners();
  }

  void setGenerating(bool val) {
    _isGenerating = val;
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

  void uploadImage(String path) {
    _uploadedImagePath = path;
    notifyListeners();
  }
}
