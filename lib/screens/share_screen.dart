import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../shared/constants.dart';
import '../widgets/app_drawer.dart';

class ShareScreen extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? description;

  const ShareScreen({super.key, this.imageUrl, this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCharcoal,
      appBar: AppBar(
        backgroundColor: AppColors.midnightNavy,
        elevation: 0,
        title: Text(
          'SHARE',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: AppColors.matteGold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.matteGold),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Share Your Creations',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Export and share your AI-generated content across platforms',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
              ),
              const SizedBox(height: 40),
              _buildShareOption(
                context: context,
                icon: Icons.facebook,
                title: 'Facebook',
                description: 'Share to your timeline',
                color: const Color(0xFF1877F2),
                onTap: () => _shareToFacebook(context),
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                context: context,
                icon: Icons.photo_library,
                title: 'Instagram',
                description: 'Post to your feed or story',
                color: const Color(0xFFE4405F),
                onTap: () => _shareToInstagram(context),
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                context: context,
                icon: Icons.send,
                title: 'Twitter / X',
                description: 'Tweet your creation',
                color: Colors.black,
                onTap: () => _shareToTwitter(context),
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                context: context,
                icon: Icons.link,
                title: 'Copy Link',
                description: 'Share via link',
                color: AppColors.matteGold,
                onTap: () => _copyLink(context),
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                context: context,
                icon: Icons.download,
                title: 'Download',
                description: 'Save to device',
                color: Colors.green,
                onTap: () => _downloadImage(context),
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                context: context,
                icon: Icons.email,
                title: 'Email',
                description: 'Send via email',
                color: Colors.blueAccent,
                onTap: () => _shareViaEmail(context),
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                context: context,
                icon: Icons.share,
                title: 'Share More',
                description: 'Share via other apps',
                color: Colors.purple,
                onTap: () => _shareGeneric(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.matteGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.matteGold,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  // Share to Facebook
  Future<void> _shareToFacebook(BuildContext context) async {
    final url = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(imageUrl ?? 'https://yourapp.com')}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showMessage(context, 'Could not open Facebook');
      }
    }
  }

  // Share to Instagram
  Future<void> _shareToInstagram(BuildContext context) async {
    _showMessage(
      context,
      'Opening Instagram...\nNote: Instagram sharing requires their official API integration',
    );
    final url = Uri.parse('https://www.instagram.com/');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Share to Twitter/X
  Future<void> _shareToTwitter(BuildContext context) async {
    final content = _getShareContent();
    final url = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(content)}&url=${Uri.encodeComponent(imageUrl ?? '')}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showMessage(context, 'Could not open Twitter/X');
      }
    }
  }

  // Copy link to clipboard
  Future<void> _copyLink(BuildContext context) async {
    final link = imageUrl ?? 'https://yourapp.com/share';
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      _showMessage(context, 'Link copied to clipboard!');
    }
  }

  // Download image
  Future<void> _downloadImage(BuildContext context) async {
    if (imageUrl == null || imageUrl!.isEmpty) {
      _showMessage(context, 'No image to download');
      return;
    }

    try {
      _showMessage(context, 'Downloading image...');

      // Download image data
      final response = await http.get(Uri.parse(imageUrl!));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        // Save to gallery
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: 'luxe_creation_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (context.mounted) {
          if (result['isSuccess'] == true) {
            _showMessage(context, 'Image saved to gallery!');
          } else {
            _showMessage(context, 'Failed to save image');
          }
        }
      } else {
        if (context.mounted) {
          _showMessage(context, 'Failed to download image');
        }
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
      if (context.mounted) {
        _showMessage(context, 'Error: ${e.toString()}');
      }
    }
  }

  // Share via email
  Future<void> _shareViaEmail(BuildContext context) async {
    final content = _getShareContent();
    final emailUrl = Uri.parse(
      'mailto:?subject=${Uri.encodeComponent(title ?? 'Check out my creation')}&body=${Uri.encodeComponent('$content\n\n${imageUrl ?? ''}')}',
    );

    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl);
    } else {
      if (context.mounted) {
        _showMessage(context, 'Could not open email app');
      }
    }
  }

  // Generic share using share_plus
  Future<void> _shareGeneric(BuildContext context) async {
    final content = _getShareContent();

    try {
      if (imageUrl != null && imageUrl!.isNotEmpty) {
        await Share.share(
          '$content\n\n$imageUrl',
          subject: title ?? 'Check out my creation',
        );
      } else {
        await Share.share(content, subject: title ?? 'Check out my creation');
      }
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (context.mounted) {
        _showMessage(context, 'Error sharing: ${e.toString()}');
      }
    }
  }

  String _getShareContent() {
    final parts = <String>[];
    if (title != null && title!.isNotEmpty) {
      parts.add(title!);
    }
    if (description != null && description!.isNotEmpty) {
      parts.add(description!);
    }
    if (parts.isEmpty) {
      return 'Check out my AI-generated creation from Luxe Mobile!';
    }
    return parts.join(' - ');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.midnightNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
