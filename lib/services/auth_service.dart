import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // 1. Web
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(OAuthProvider.google);
        return null; // Web redirects, so no immediate response
      }

      // 2. Mobile (Android / iOS)
      // Note: This requires google_sign_in package and platform configuration
      // (SHA-1 in Firebase/Google Cloud Console, google-services.json, Info.plist)

      const webClientId =
          '925697717577-5c3nejgcjg3l19k76kifbnd5pfp9rbnj.apps.googleusercontent.com';
      const iosClientId =
          '925697717577-fke5epuauuh500pe48d5n9g6mdlh3f57.apps.googleusercontent.com';

      // Use the singleton instance
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Initialize configuration
      await googleSignIn.initialize(
        clientId: kIsWeb ? null : iosClientId,
        serverClientId: webClientId,
      );

      // Trigger interactive sign-in
      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {
          // Ignore if google sign in fails to sign out (e.g. not signed in via google)
        }
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<bool> hasActiveSubscription() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Check 'profiles' table for subscription status
      // Assuming you have a 'profiles' table with 'is_subscribed' or 'subscription_tier'
      final data = await _supabase
          .from('profiles')
          .select('is_subscribed')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return false;
      return data['is_subscribed'] == true;
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false; // Fail safe to not granting access
    }
  }

  Future<void> decrementUserCredit(String type) async {
    try {
      final user = currentUser;
      if (user == null) return;

      // 1. Get current count
      final data = await getUserProfile();
      if (data == null) return;

      final key = type == 'video' ? 'video_generations' : 'photo_generations';

      // Inference logic for credits if columns are missing
      int current = data[key] ?? data['generations_remaining'] ?? 0;
      if (current == 0 && data[key] == null) {
        final tier = data['subscription_tier'] as String?;
        if (tier != null) {
          if (tier.contains('creatorPack'))
            current = 30;
          else if (tier.contains('professionalShoot'))
            current = 80;
          else if (tier.contains('agencyMaster'))
            current = 200;
          else if (tier.contains('socialQuick'))
            current = 5;
        }
      }

      if (current > 0) {
        // 2. Decrement
        // Check which column to update based on what exists in the profile
        String updateKey = key;
        if (!data.containsKey(key)) {
          if (data.containsKey('generations_remaining')) {
            updateKey = 'generations_remaining';
          } else {
            debugPrint('Warning: No valid credit column found to update.');
            return;
          }
        }

        await _supabase
            .from('profiles')
            .update({updateKey: current - 1})
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error decrementing credit: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return data;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }
}
