import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../shared/constants.dart';

class StripeService {
  static Future<void> init() async {
    try {
      // Skip Stripe initialization on web as flutter_stripe has limited web support
      if (kIsWeb) {
        debugPrint('Stripe: Skipping native initialization on web platform');
        return;
      }

      // Note: You should have STRIPE_PUBLISHABLE_KEY in your .env
      Stripe.publishableKey =
          dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? 'pk_live_...';
      await Stripe.instance.applySettings();
      debugPrint('Stripe: Initialized successfully');
    } catch (e) {
      debugPrint('Stripe initialization error: $e');
      // Don't throw - allow app to continue even if Stripe fails
    }
  }

  static Future<bool> handlePayment(
    String packageId,
    String customerEmail, {
    String? promoCode,
  }) async {
    try {
      // On web, use payment links instead of native PaymentSheet
      if (kIsWeb) {
        debugPrint(
          'Stripe: Web platform detected, use getPaymentLink() instead',
        );
        return false;
      }

      // 1. Create Payment Intent on your backend
      final response = await http.post(
        Uri.parse('${dotenv.env['VITE_API_URL']}/api/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'packageId': packageId,
          'customerEmail': customerEmail,
          'promoCode': promoCode,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend PaymentIntent creation failed');
      }

      final data = jsonDecode(response.body);

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['paymentIntent'],
          merchantDisplayName: 'Luxe AI Studio',
          customerId: data['customer'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.matteGold,
              background: AppColors.midnightNavy,
              componentBackground: AppColors.softCharcoal,
              componentDivider: Color(0xFF202020),
              primaryText: Colors.white,
              secondaryText: Colors.white54,
              placeholderText: Colors.white24,
            ),
          ),
        ),
      );

      // 3. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      return true;
    } catch (e) {
      debugPrint('Stripe Error: $e');
      return false;
    }
  }

  /// Returns a Stripe Payment Link URL with user identification metadata.
  ///
  /// Appends `client_reference_id` (Supabase auth UID) so the webhook
  /// can identify which user completed the payment, and passes the
  /// `package_id` via URL so Stripe includes it in the session metadata.
  static String? getPaymentLink(String packageId, {String? promoCode}) {
    const links = {
      'socialQuick': 'https://buy.stripe.com/14A4gr11S25B6m89LqfEk00',
      'creatorPack': 'https://buy.stripe.com/3cI00bdOEdOjfWI6zefEk01',
      'professionalShoot': 'https://buy.stripe.com/00w28j7qg39FfWI6zefEk02',
      'agencyMaster': 'https://buy.stripe.com/aFa7sD3a0fWr11O1eUfEk06',
      // Subscriptions
      'sub_monthly_19': 'https://buy.stripe.com/dRm28jeSIdOj39Wf5KfEk03',
      'sub_monthly_49': 'https://buy.stripe.com/bJe3cndOEaC7fWI4r6fEk04',
      'sub_monthly_99': 'https://buy.stripe.com/cNi14f3a05hNfWI7DifEk05',
      // Legacy / Fallback
      'branding':
          'https://buy.stripe.com/00w28j7qg39FfWI6zefEk02', // Fallback to pro shoot
    };

    String? baseUrl = links[packageId];
    if (baseUrl == null) return null;

    // Append user identification for webhook processing.
    // We encode both userId and packageId into client_reference_id (format: "userId:packageId")
    // because Stripe Payment Links don't allow passing custom metadata via URL parameters,
    // but they do carry the client_reference_id through to the webhook.
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final uri = Uri.parse(baseUrl);
    final params = Map<String, String>.from(uri.queryParameters);

    if (userId != null) {
      params['client_reference_id'] = '$userId:$packageId';
    }

    // Note: For Payment Links, metadata must be configured in Stripe Dashboard.
    // The client_reference_id is passed via URL and available in the webhook event.

    if (promoCode != null && promoCode.isNotEmpty) {
      params['prefilled_promo_code'] = promoCode;
      debugPrint('Stripe: Applying promo code $promoCode to $packageId');
    }

    final updatedUri = uri.replace(
      queryParameters: params.isEmpty ? null : params,
    );
    return updatedUri.toString();
  }
}
