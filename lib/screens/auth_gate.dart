import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import 'login_screen.dart';
import 'boutique_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.midnightNavy,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.matteGold),
              ),
            ),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const BoutiqueScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
