import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../shared/constants.dart';
import 'studio_dashboard_screen.dart';

class IdentityReferenceScreen extends StatefulWidget {
  const IdentityReferenceScreen({super.key});

  @override
  State<IdentityReferenceScreen> createState() =>
      _IdentityReferenceScreenState();
}

class _IdentityReferenceScreenState extends State<IdentityReferenceScreen> {
  bool _isStitchMode = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageSource() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.softCharcoal,
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
              Text(
                'ADD IDENTITY ANCHOR',
                style: AppTypography.microBold(
                  color: Colors.white,
                ).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.matteGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.matteGold,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: AppTypography.smallSemiBold(color: Colors.white),
                ),
                subtitle: Text(
                  'Capture a new selfie',
                  style: AppTypography.small(color: Colors.white38),
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
                    color: AppColors.matteGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.matteGold,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: AppTypography.smallSemiBold(color: Colors.white),
                ),
                subtitle: Text(
                  'Select up to 5 photos',
                  style: AppTypography.small(color: Colors.white38),
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
      final session = context.read<SessionProvider>();
      if (session.identityImages.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 identity anchors allowed.')),
        );
        return;
      }

      if (fromCamera) {
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.front,
        );
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          session.addIdentityImage(bytes);
        }
      } else {
        // Multi-image picker from gallery
        final List<XFile> pickedFiles = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        for (var file in pickedFiles) {
          if (session.identityImages.length >= 5) break;
          final bytes = await file.readAsBytes();
          session.addIdentityImage(bytes);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // Widget to display an individual identity slot
  Widget _buildIdentitySlot(
    BuildContext context,
    int index,
    Uint8List? imageBytes,
  ) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.softCharcoal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: imageBytes != null ? AppColors.matteGold : Colors.white10,
              width: imageBytes != null ? 1 : 1,
            ),
          ),
          child: imageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Center(child: Icon(Icons.add, color: Colors.white24, size: 24)),
        ),
        if (imageBytes != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () =>
                  context.read<SessionProvider>().removeIdentityImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeToggle(String title, bool isStitch) {
    final isSelected = _isStitchMode == isStitch;
    return GestureDetector(
      onTap: () => setState(() {
        _isStitchMode = isStitch;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.matteGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppTypography.microBold(
            color: isSelected ? Colors.black : Colors.white54,
          ).copyWith(fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildGenderToggle(
    String title,
    String gender,
    SessionProvider session,
  ) {
    final isSelected = session.soloGender == gender;
    return GestureDetector(
      onTap: () => session.setSoloGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.matteGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppTypography.microBold(
            color: isSelected ? Colors.black : Colors.white54,
          ).copyWith(fontSize: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Header
              Text(
                'IDENTITY STUDIO™',
                style: AppTypography.h3Display(
                  color: Colors.white,
                ).copyWith(letterSpacing: 4, fontSize: 16),
              ),

              const SizedBox(height: 24),

              // Mode & Gender Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mode Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeToggle('IDENTITY LOCK', false),
                        _buildModeToggle('GROUP MODE', true),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                _isStitchMode
                    ? 'Create group photos with multiple people.'
                    : 'Upload 1-5 selfies to lock in your identity logic. More photos = higher facial fidelity.',
                textAlign: TextAlign.center,
                style: AppTypography.small(color: Colors.white54),
              ),

              const SizedBox(height: 24),

              // Main Content Area
              Expanded(
                child: _isStitchMode
                    ? _buildStitchModePlaceholder(context)
                    : Consumer<SessionProvider>(
                        builder: (context, session, _) {
                          final images = session.identityImages;
                          return Column(
                            children: [
                              // Grid of Identities
                              Expanded(
                                child: GridView.builder(
                                  itemCount: 5, // Always show 5 slots
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2, // 2 columns
                                        childAspectRatio: 1,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemBuilder: (context, index) {
                                    final img = index < images.length
                                        ? images[index]
                                        : null;
                                    // Make empty slots tappable to add
                                    if (img == null) {
                                      if (index == images.length) {
                                        // Next available slot
                                        return GestureDetector(
                                          onTap: _pickImageSource,
                                          child: _buildIdentitySlot(
                                            context,
                                            index,
                                            null,
                                          ),
                                        );
                                      } else {
                                        // Future slots (disabled look)
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white10.withValues(
                                              alpha: 0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.white10,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    return _buildIdentitySlot(
                                      context,
                                      index,
                                      img,
                                    );
                                  },
                                ),
                              ),

                              if (images.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  "Photos locked. AI will triangulate features.",
                                  style: AppTypography.micro(
                                    color: AppColors.matteGold,
                                  ).copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),

              // Action Button
              if (!_isStitchMode) ...[
                Consumer<SessionProvider>(
                  builder: (context, session, _) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGenderToggle('MALE', 'male', session),
                          _buildGenderToggle('FEMALE', 'female', session),
                          _buildGenderToggle('NEUTRAL', 'unspecified', session),
                        ],
                      ),
                    );
                  },
                ),
              ],
              Consumer<SessionProvider>(
                builder: (context, session, _) {
                  final hasImages = session.identityImages.isNotEmpty;
                  final ready = _isStitchMode || hasImages;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ready
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StudioDashboardScreen(
                                    startInStitchMode: _isStitchMode,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.matteGold,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white10,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isStitchMode
                            ? 'ENTER GROUP STUDIO'
                            : 'INITIATE SESSION (${session.identityImages.length}/5)',
                        style: AppTypography.button(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStitchModePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.softCharcoal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.matteGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            color: AppColors.matteGold.withValues(alpha: 0.6),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'ADD PEOPLE IN STUDIO',
            style: AppTypography.microBold(color: AppColors.matteGold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tap below to enter the Studio, then add up to 5 different identity photos for your group.',
              textAlign: TextAlign.center,
              style: AppTypography.micro(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}
