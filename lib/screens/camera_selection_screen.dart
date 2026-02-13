import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/constants.dart';
import '../models/types.dart';
import '../providers/session_provider.dart';
import 'identity_reference_screen.dart';

class CameraSelectionScreen extends StatelessWidget {
  const CameraSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: AppColors.midnightNavy,
            pinned: true,
            title: Text(
              'SELECT OPTIC RIG',
              style: TextStyle(
                letterSpacing: 4,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final rig = cameraRigs[index];
                return _buildRigCard(context, rig);
              }, childCount: cameraRigs.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRigCard(BuildContext context, CameraRig rig) {
    return GestureDetector(
      onTap: () {
        context.read<SessionProvider>().setSelectedRig(rig);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const IdentityReferenceScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.softCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(rig.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rig.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.matteGold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rig.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSpecItem('SENSOR', rig.specs.sensor),
                _buildSpecItem('LENS', rig.specs.lens),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
