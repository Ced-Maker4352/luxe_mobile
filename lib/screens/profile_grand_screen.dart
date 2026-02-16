import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/constants.dart';
import '../widgets/app_drawer.dart';

class ProfileGrandScreen extends StatefulWidget {
const ProfileGrandScreen({super.key});

@override
State<ProfileGrandScreen> createState() => _ProfileGrandScreenState();
}

class _ProfileGrandScreenState extends State<ProfileGrandScreen> {
final _supabase = Supabase.instance.client;
User? _user;
Map<String, dynamic>? _profile;
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadProfile();
}

Future<void> _loadProfile() async {
try {
_user = _supabase.auth.currentUser;
if (_user != null) {
final response = await _supabase
.from('profiles')
.select()
.eq('id', _user!.id)
.maybeSingle();
setState(() {
_profile = response;
_isLoading = false;
});
} else {
setState(() => _isLoading = false);
}
} catch (e) {
debugPrint('Error loading profile: $e');
setState(() => _isLoading = false);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.softCharcoal,
appBar: AppBar(
backgroundColor: AppColors.midnightNavy,
elevation: 0,
title: Text(
'PROFILE GRAND',
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
body: _isLoading
? const Center(child: CircularProgressIndicator(color: AppColors.matteGold))
: SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.all(24.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
const SizedBox(height: 20),
CircleAvatar(
radius: 60,
backgroundColor: AppColors.matteGold.withValues(alpha: 0.2),
child: Icon(
Icons.person,
size: 60,
color: AppColors.matteGold,
),
),
const SizedBox(height: 24),
Text(
_profile?['full_name'] ?? _user?.email?.split('@')[0] ?? 'User',
style: GoogleFonts.inter(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
const SizedBox(height: 8),
Text(
_user?.email ?? 'No email',
style: GoogleFonts.inter(
fontSize: 14,
color: Colors.grey[400],
),
),
const SizedBox(height: 40),
_buildInfoCard('Account Type', 'Premium Member', Icons.workspace_premium),
const SizedBox(height: 16),
_buildInfoCard('Member Since', '2024', Icons.calendar_today),
const SizedBox(height: 16),
_buildInfoCard('Projects Created', '12', Icons.photo_library),
const SizedBox(height: 16),
_buildInfoCard('Styles Explored', '8', Icons.palette),
const SizedBox(height: 40),
ElevatedButton(
onPressed: () async {
await _supabase.auth.signOut();
if (context.mounted) {
Navigator.pushReplacementNamed(context, '/auth');
}
},
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.matteGold,
padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(8),
),
),
child: Text(
'SIGN OUT',
style: GoogleFonts.inter(
fontSize: 14,
fontWeight: FontWeight.w600,
letterSpacing: 1.5,
color: AppColors.softCharcoal,
),
),
),
],
),
),
),
);
}

Widget _buildInfoCard(String label, String value, IconData icon) {
return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: AppColors.midnightNavy,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: AppColors.matteGold.withValues(alpha: 0.3),
width: 1,
),
),
child: Row(
children: [
Icon(icon, color: AppColors.matteGold, size: 24),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: GoogleFonts.inter(
fontSize: 12,
color: Colors.grey[400],
fontWeight: FontWeight.w500,
),
),
const SizedBox(height: 4),
Text(
value,
style: GoogleFonts.inter(
fontSize: 16,
color: Colors.white,
fontWeight: FontWeight.w600,
),
),
],
),
),
],
),
);
}
}
