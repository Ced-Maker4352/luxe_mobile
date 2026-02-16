import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/constants.dart';
import '../widgets/app_drawer.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

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
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 40),
              _buildShareOption(
                icon: Icons.facebook,
                title: 'Facebook',
                description: 'Share to your timeline',
                color: const Color(0xFF1877F2),
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                icon: Icons.photo_library,
                title: 'Instagram',
                description: 'Post to your feed or story',
                color: const Color(0xFFE4405F),
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                icon: Icons.send,
                title: 'Twitter / X',
                description: 'Tweet your creation',
                color: Colors.black,
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                icon: Icons.link,
                title: 'Copy Link',
                description: 'Share via link',
                color: AppColors.matteGold,
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                icon: Icons.download,
                title: 'Download',
                description: 'Save to device',
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildShareOption(
                icon: Icons.email,
                title: 'Email',
                description: 'Send via email',
                color: Colors.blueAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.matteGold,
          size: 16,
        ),
        onTap: () {
          // Share functionality would be implemented here
        },
      ),
    );
  }
}
