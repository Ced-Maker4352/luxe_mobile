import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';

class StripeService {
  static Future<void> init() async {
    // Note: You should have STRIPE_PUBLISHABLE_KEY in your .env
    Stripe.publishableKey =
        dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? 'pk_live_...';
    await Stripe.instance.applySettings();
  }

  static Future<bool> handlePayment(
    String packageId,
    String customerEmail,
  ) async {
    try {
      // 1. Create Payment Intent on your backend
      final response = await http.post(
        Uri.parse('${dotenv.env['VITE_API_URL']}/api/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'packageId': packageId,
          'customerEmail': customerEmail,
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

  static String? getPaymentLink(String packageId) {
    // These match the test links in your web app's paymentLinks.ts
    const links = {
      'INDEPENDENT_ARTIST':
          'https://buy.stripe.com/test_28E5kv5eigiD04N0lW7N600',
      'EXECUTIVE': 'https://buy.stripe.com/test_eVq5kv36ac2naJrfgQ7N601',
      'BIRTHDAY_LUXE': 'https://buy.stripe.com/test_8x24gr2263vR04N9Ww7N602',
      'CINEMATIC_NOIR': 'https://buy.stripe.com/test_5kQ9AL7mqc2n04N5Gg7N603',
      'ENTERTAINER': 'https://buy.stripe.com/test_fZubIT0Y2eavaJrecM7N604',
      'MOTION': 'https://buy.stripe.com/test_fZucMXfSW9Uf8Bj2u47N605',
    };
    return links[packageId];
  }
}
