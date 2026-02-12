import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

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
              primary: Color(0xFFD4AF37),
              background: Color(0xFF0A0A0A),
              componentBackground: Color(0xFF141414),
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

  static String? getPaymentLink(String packageId, {String? promoCode}) {
    // These match the test links in your web app's paymentLinks.ts
    const links = {
      'SOCIAL_QUICK': 'https://buy.stripe.com/test_28E5kv5eigiD04N0lW7N600',
      'CREATOR_PACK': 'https://buy.stripe.com/test_eVq5kv36ac2naJrfgQ7N601',
      'PROFESSIONAL_SHOOT':
          'https://buy.stripe.com/test_5kQ9AL7mqc2n04N5Gg7N603',
      'AGENCY_MASTER': 'https://buy.stripe.com/test_fZubIT0Y2eavaJrecM7N604',
      // Subscriptions
      'sub_monthly_19': 'https://buy.stripe.com/test_28E5kv5eigiD04N0lW7N600',
      'sub_monthly_49': 'https://buy.stripe.com/test_eVq5kv36ac2naJrfgQ7N601',
      'sub_monthly_99': 'https://buy.stripe.com/test_5kQ9AL7mqc2n04N5Gg7N603',
      // Legacy / Fallback
      'branding': 'https://buy.stripe.com/test_eVq5kv36ac2naJrfgQ7N601',
    };

    String? baseUrl = links[packageId];
    if (baseUrl != null && promoCode != null && promoCode.isNotEmpty) {
      // In a real app, you'd apply the promo code to the link or backend
      debugPrint('Stripe: Applying promo code $promoCode to $packageId');
    }
    return baseUrl;
  }
}
