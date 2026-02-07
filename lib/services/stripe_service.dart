import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class StripeService {
  static Future<void> init() async {
    // Skip Stripe initialization on web - it only works on native mobile
    if (kIsWeb) {
      debugPrint('Stripe: Skipping native initialization on web platform');
      return;
    }

    Stripe.publishableKey =
        dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? 'pk_live_...';
    await Stripe.instance.applySettings();
  }

  static Future<bool> handlePayment(
    String packageId,
    String customerEmail,
  ) async {
    // On web, use payment links instead of native Payment Sheet
    if (kIsWeb) {
      debugPrint('Stripe: Web platform detected, using payment link');
      final link = getPaymentLink(packageId);
      if (link != null) {
        final uri = Uri.parse('$link?prefilled_email=$customerEmail');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true; // Assume success - user will complete on Stripe page
        }
      }
      debugPrint('Stripe: No payment link found for $packageId');
      return false;
    }

    // Native mobile flow
    try {
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

      await Stripe.instance.presentPaymentSheet();
      return true;
    } catch (e) {
      debugPrint('Stripe Error: $e');
      return false;
    }
  }

  static String? getPaymentLink(String packageId) {
    // Live Stripe payment links for each package
    const links = {
      'INDEPENDENT_ARTIST': 'https://buy.stripe.com/28E5kv5eigiD04N0lW',
      'EXECUTIVE': 'https://buy.stripe.com/eVq5kv36ac2naJrfgQ',
      'ANNIVERSARY_SUITE': 'https://buy.stripe.com/8x24gr2263vR04N9Ww',
      'CINEMATIC_NOIR': 'https://buy.stripe.com/5kQ9AL7mqc2n04N5Gg',
      'ENTERTAINER': 'https://buy.stripe.com/fZubIT0Y2eavaJrecM',
      'SNAPSHOT_DAILY': 'https://buy.stripe.com/fZucMXfSW9Uf8Bj2u4',
      'SNAPSHOT_STYLE': 'https://buy.stripe.com/fZucMXfSW9Uf8Bj2u5',
    };
    return links[packageId];
  }
}
