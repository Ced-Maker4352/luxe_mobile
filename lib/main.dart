import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const SplashScreen(),
      routes: {
        '/boutique': (context) => const BoutiqueScreen(),
        '/camera': (context) => const CameraSelectionScreen(),
        '/identity': (context) => const IdentityReferenceScreen(),
        '/studio': (context) => const StudioDashboardScreen(),
        '/auth': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
