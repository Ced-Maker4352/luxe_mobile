import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import 'studio_dashboard_screen.dart';

class IdentityReferenceScreen extends StatefulWidget {
  const IdentityReferenceScreen({super.key});

  @override
  State<IdentityReferenceScreen> createState() =>
      _IdentityReferenceScreenState();
}

class _IdentityReferenceScreenState extends State<IdentityReferenceScreen> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SELECT IMAGE SOURCE',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Use your camera to capture a portrait',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: true);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Select an existing photo from your device',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: false);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
        if (mounted) {
          // Store bytes directly in SessionProvider (works on web and mobile)
          context.read<SessionProvider>().uploadImageBytes(
            bytes,
            pickedFile.name,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'IDENTITY REFERENCE',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 4,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload your baseline portrait. Our AI Rigs use this to lock your distinct facial geometry.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              GestureDetector(
                onTap: _showImageSourceOptions,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'DRAG OR TAP TO UPLOAD',
                              style: TextStyle(
                                color: Colors.white24,
                                letterSpacing: 2,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const Spacer(),

              if (_imageBytes != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const StudioDashboardScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'INITIATE STUDIO SESSION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: _showImageSourceOptions,
                child: Text(
                  _imageBytes == null
                      ? 'HOW TO CHOOSE THE BEST PHOTO'
                      : 'CHANGE REFERENCE IMAGE',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
