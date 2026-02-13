import 'package:flutter/material.dart';
import '../models/types.dart';
import '../services/stripe_service.dart';
import 'access_granted_screen.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../shared/constants.dart';

class SingleStyleSelectionScreen extends StatefulWidget {
  final PackageDetails package;

  const SingleStyleSelectionScreen({super.key, required this.package});

  @override
  State<SingleStyleSelectionScreen> createState() =>
      _SingleStyleSelectionScreenState();
}

class _SingleStyleSelectionScreenState
    extends State<SingleStyleSelectionScreen> {
  StyleOption? _selectedStyle;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Prevert selection if styles exist
    if (widget.package.styles.isNotEmpty) {
      _selectedStyle = widget.package.styles.first;
    }
  }

  Future<void> _handlePayment() async {
    if (_selectedStyle == null) return;

    // Show email dialog
    final emailController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.softCharcoal,
        title: Text(
          'One-Time Payment: ${widget.package.payAsYouGoPrice}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Email for Receipt',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, emailController.text),
            child: Text(
              'PAY NOW',
              style: TextStyle(color: AppColors.matteGold),
            ),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Create a temporary "Single Style" package for processing
      // In a real app, you'd have specific Stripe Price IDs for these
      final success = await StripeService.handlePayment(
        "PAY_GO_${widget.package.id.name}_${_selectedStyle!.id}",
        result,
      );

      if (success && mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.setSelectedPackage(widget.package);
        session.setSelectedStyle(_selectedStyle!);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AccessGrantedScreen(
              package: widget.package,
              isPromoCode: false,
              singleStyleMode:
                  true, // We will need to add this to AccessGrantedScreen
              selectedStyleId: _selectedStyle!.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "SELECT STYLE",
          style: TextStyle(
            color: AppColors.matteGold,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Choose one style from the ${widget.package.name} collection to try immediately.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

          // Style List
          Expanded(
            child: ListView.builder(
              itemCount: widget.package.styles.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final style = widget.package.styles[index];
                final isSelected = style.id == _selectedStyle?.id;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 50)),
                  curve: AppMotion.cinematic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStyle = style),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.softCharcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.matteGold, width: 2)
                            : Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          // Image Preview
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                            child: Image.network(
                              style.image,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  style.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  style.description,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Checkbox
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.matteGold
                                  : Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.softCharcoal,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: PremiumButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  isLoading: _isProcessing,
                  child: Text('PAY ${widget.package.payAsYouGoPrice}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
