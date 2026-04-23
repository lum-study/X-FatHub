import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/features/booking/views/book_and_pay_screen.dart';
import 'package:xfathub/features/booking/views/checkout_screen.dart';

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
      provider.loadSelectedPackageDetails();
      provider.refreshCurrentUserBookingData();
    });
  }

  Future<void> _buyPackage(BookingViewModel provider) async {
    provider.selectPackage(widget.package);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(package: widget.package),
      ),
    );
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
        final packageCredits = provider.sessionsRemainingForPackage(
          widget.package.id,
        );
        final packageExpiry = provider.expiryForPackage(widget.package.id);
        final hasCredits = packageCredits > 0;

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
                  _buildSummary(packageCredits, packageExpiry),
                  const SizedBox(height: 14),
                  _buildBenefits(),
                  const SizedBox(height: 14),
                  _buildRules(),
                  const SizedBox(height: 14),
                  _buildGymMapping(provider),
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

  Widget _buildSummary(int packageCredits, DateTime? packageExpiry) {
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
            '$packageCredits sessions remaining',
            style: const TextStyle(
              color: Color(0xFFFFA500),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            packageExpiry == null
                ? 'No active purchase yet'
                : 'Valid until ${packageExpiry.toLocal().toIso8601String().split('T').first}',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    final package = widget.package;
    final benefits = package.benefits.isEmpty
        ? <String>[
            '${package.sessionsCount} training sessions included',
            'Book only eligible slot types for this package',
            'Session balance tracked in your active package wallet',
          ]
        : package.benefits;

    return _buildCardSection(
      title: 'Benefits',
      child: Column(
        children: benefits.map((item) => _buildBulletItem(item)).toList(),
      ),
    );
  }

  Widget _buildRules() {
    final package = widget.package;
    final rules = package.rules.isEmpty
        ? const <String>[
            'A session is deducted only after successful booking confirmation.',
            'Cancelled sessions are handled by server-side booking policy.',
            'Only authenticated users can purchase and consume package credits.',
          ]
        : package.rules;

    return _buildCardSection(
      title: 'Rules',
      child: Column(
        children: rules.map((item) => _buildBulletItem(item)).toList(),
      ),
    );
  }

  Widget _buildGymMapping(BookingViewModel provider) {
    final mappedGyms = provider.selectedPackageGyms;
    final fallbackGyms = widget.package.gymNames;
    final gymLabels = mappedGyms.map((gym) {
      final venue = gym.venue?.trim();
      if (venue == null || venue.isEmpty) {
        return gym.name;
      }
      return '${gym.name} - $venue';
    }).toList();
    final labels = gymLabels.isNotEmpty ? gymLabels : fallbackGyms;

    return _buildCardSection(
      title: 'Gyms For This Package',
      child: labels.isEmpty
          ? const Text(
              'No gym mapping has been configured yet for this package.',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels
                  .map(
                    (gym) => Container(
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
                        gym,
                        style: const TextStyle(
                          color: Color(0xFFFFA500),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
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

  Widget _buildCardSection({required String title, required Widget child}) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, color: Color(0xFFFFA500), size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BookingViewModel provider, bool hasCredits) {
    return Column(
      children: [
        SizedBox(
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
        ),
        if (hasCredits) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFA500)),
                foregroundColor: const Color(0xFFFFA500),
              ),
              onPressed: () => _buyPackage(provider),
              child: const Text('Buy More'),
            ),
          ),
        ],
      ],
    );
  }
}
