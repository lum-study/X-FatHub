import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/features/booking/views/book_and_pay_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final PackageModel package;

  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BookingViewModel>();
      provider.selectPackage(widget.package);
      provider.refreshCurrentUserBookingData();
    });
  }

  Future<void> _buyPackage(BookingViewModel provider) async {
    try {
      final checkoutUrl = await provider.createCheckoutForPackage(
        widget.package.id,
      );
      final launched = await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Checkout URL: $checkoutUrl')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to start checkout: $e')));
    }
  }

  void _bookSlots(BookingViewModel provider) {
    provider.selectPackage(widget.package);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookAndPayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewModel>(
      builder: (context, provider, _) {
        final hasCredits = provider.sessionsRemaining > 0;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFFFFA500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Package Details',
                        style: TextStyle(
                          color: Color(0xFFFFA500),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHero(),
                  const SizedBox(height: 14),
                  _buildSummary(provider),
                  const SizedBox(height: 14),
                  _buildAllowedSlots(),
                  const SizedBox(height: 18),
                  _buildActionButtons(provider, hasCredits),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1000), Color(0xFF0F0F0F)],
        ),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.package.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.package.description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'RM ${widget.package.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFFFA500),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.package.sessionsCount} sessions included',
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BookingViewModel provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Package Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${provider.sessionsRemaining} sessions remaining',
            style: const TextStyle(
              color: Color(0xFFFFA500),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.nextExpiryDate == null
                ? 'No active purchase yet'
                : 'Valid until ${provider.nextExpiryDate!.toLocal().toIso8601String().split('T').first}',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowedSlots() {
    final classes = widget.package.allowedClassNames;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Slot Types',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (classes.isEmpty)
            const Text(
              'All gym slots are available for this package.',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: classes
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1000),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: const Color(0xFFFFA500)),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFFFA500),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BookingViewModel provider, bool hasCredits) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA500),
          foregroundColor: Colors.black,
        ),
        onPressed: hasCredits
            ? () => _bookSlots(provider)
            : () => _buyPackage(provider),
        child: Text(hasCredits ? 'Book Slot' : 'Buy Package'),
      ),
    );
  }
}
