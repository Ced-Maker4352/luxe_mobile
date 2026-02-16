import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'shared/constants.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/boutique_screen.dart';
import 'screens/camera_selection_screen.dart';
import 'screens/identity_reference_screen.dart';
import 'screens/studio_dashboard_screen.dart';
import 'providers/session_provider.dart';
import 'services/stripe_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/brand_studio_screen.dart';
import 'screens/profile_grand_screen.dart';
import 'screens/share_screen.dart';
import 'screens/gallery_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  await Supabase.initialize(
    url: dotenv.env['VITE_SUPABASE_URL']!,
    anonKey: dotenv.env['VITE_SUPABASE_ANON_KEY']!,
  );

  await StripeService.init(); // Initialize Stripe
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Luxe AI Studio',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.matteGold,
        scaffoldBackgroundColor: AppColors.midnightNavy,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashScreen(),
      routes: {
        '/boutique': (context) => const BoutiqueScreen(),
        '/camera': (context) => const CameraSelectionScreen(),
        '/identity': (context) => const IdentityReferenceScreen(),
        '/studio': (context) => const StudioDashboardScreen(),
        '/brand_studio': (context) => const BrandStudioScreen(),
        '/auth': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileGrandScreen(),
        '/share': (context) => const ShareScreen(),
        '/gallery': (context) => const GalleryScreen(),
      },
    );
  }
}
