import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.midnightNavy,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.softPlatinum.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Center(
              child: Text(
                'LUXE AI',
                style: AppTypography.h3Display(
                  color: AppColors.matteGold,
                ).copyWith(letterSpacing: 4),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.storefront,
                  title: 'BOUTIQUE',
                  route: '/boutique',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.camera_alt,
                  title: 'STUDIO',
                  route: '/studio',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'PROFILE',
                  route: '/profile', // Placeholder or upcoming
                ),
                Divider(color: AppColors.softPlatinum.withValues(alpha: 0.1)),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'SIGN OUT',
                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'v1.2.0 • Luxe AI Corp',
              style: AppTypography.micro(color: AppColors.mutedGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    // Check if current route matches
    // This is hard to do perfectly with loose routes, but we can verify against simple strings if passed
    // For now, simple navigation.

    return ListTile(
      leading: Icon(icon, color: AppColors.softPlatinum),
      title: Text(
        title,
        style: AppTypography.bodyRegular(
          color: AppColors.softPlatinum,
        ).copyWith(letterSpacing: 1.5),
      ),
      onTap:
          onTap ??
          () {
            Navigator.pop(context); // Close drawer
            if (route != null) {
              // Avoid pushing same route on top
              // Navigator.pushReplacementNamed(context, route);
              // Or navigate strictly
              Navigator.pushNamed(context, route);
            }
          },
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      hoverColor: AppColors.matteGold.withValues(alpha: 0.1),
    );
  }
}
