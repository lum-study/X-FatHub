import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/features/booking/views/payment_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final PackageModel package;

  const CheckoutScreen({super.key, required this.package});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with WidgetsBindingObserver {
  bool _isProcessing = false;
  bool _isAwaitingPaymentReturn = false;
  int _initialPackageCredits = -1;

  String get _deepLinkScheme => 'xfathub';
  String get _successUrl => '$_deepLinkScheme://payment/success';
  String get _cancelUrl => '$_deepLinkScheme://payment/cancel';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAwaitingPaymentReturn) {
      _verifyPaymentReturn();
    }
  }

  Future<void> _verifyPaymentReturn() async {
    // Relying on global deep link listener in main.dart now.
    // This local verification is removed to avoid duplicate navigation or race conditions.
    _isAwaitingPaymentReturn = false;
  }

  Future<void> _payWithCard() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final provider = context.read<BookingViewModel>();
      provider.selectPackage(widget.package);
      await provider.refreshCurrentUserBookingData();
      _initialPackageCredits = provider.sessionsRemainingForPackage(
        widget.package.id,
      );

      final checkoutUrl = await provider.createCheckoutForPackage(
        widget.package.id,
      );

      final uri = Uri.parse(checkoutUrl);
      final withSuccessParams = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'success_url': _successUrl,
          'cancel_url': _cancelUrl,
        },
      );

      final launched = await launchUrl(
        withSuccessParams,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open checkout: $checkoutUrl')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _isProcessing = false;
        _isAwaitingPaymentReturn = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete payment in browser. You will return here after redirect.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      setState(() {
        _isProcessing = false;
        _isAwaitingPaymentReturn = false;
      });
    }
  }

  Widget _buildMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFFFA500)
                  : const Color(0xFF2A2A2A),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFA500), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFFA500),
                  size: 14,
                )
              else
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.package;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(
                      Icons.chevron_left,
                      color: Color(0xFFFFA500),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Checkout',
                      style: TextStyle(
                        color: Color(0xFFFFA500),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.description,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'RM ${package.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFFFA500),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Payment Methods',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _buildMethodTile(
                icon: Icons.credit_card,
                title: 'Credit/Debit Card',
                subtitle: 'Pay securely via Stripe checkout.',
                enabled: true,
                onTap: _payWithCard,
              ),
              const SizedBox(height: 10),
              _buildMethodTile(
                icon: Icons.account_balance_wallet,
                title: 'E-Wallet',
                subtitle: 'Production integration will be added later.',
                enabled: false,
              ),
              const SizedBox(height: 10),
              _buildMethodTile(
                icon: Icons.account_balance,
                title: 'Online Bank Transfer',
                subtitle: 'Production integration will be added later.',
                enabled: false,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _isProcessing ? null : _payWithCard,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Proceed With Card',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
