import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/views/package_detail_screen.dart';
import 'package:xfathub/features/booking/views/book_and_pay_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  @override
  void initState() {
    super.initState();
    // Use package-style import for the provider to match app_providers.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<BookingViewModel>(context, listen: false);
        provider.initializePackagesPage();
      }
    });
  }

  void _openPackageDetail(
    BuildContext context,
    BookingViewModel provider,
    PackageModel package,
  ) {
    provider.selectPackage(package);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PackageDetailScreen(package: package)),
    );
  }

  void _openBookSlot(
    BuildContext context,
    BookingViewModel provider,
    PackageModel package,
  ) {
    provider.selectPackage(package);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookAndPayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<BookingViewModel>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.packages.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFA500)),
              );
            }

            if (provider.errorMessage != null && provider.packages.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFFA500),
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'If the database is empty, run the booking seed SQL file.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await provider.refreshPackagesPage();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildCategoryPills(),
                    const SizedBox(height: 14),
                    if (provider.activePackages.isNotEmpty) ...[
                      _buildSectionTitle(
                        Icons.stars_rounded,
                        "Active Packages",
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.activePackages.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final pkg = provider.activePackages[index];
                          final credits =
                              provider.sessionsRemainingByPackage[pkg.id] ?? 0;
                          final expiry = provider.expiryByPackage[pkg.id];
                          return _buildActivePackageCard(
                            package: pkg,
                            credits: credits,
                            expiry: expiry,
                            onBookTap: () =>
                                _openBookSlot(context, provider, pkg),
                            onDetailsTap: () =>
                                _openPackageDetail(context, provider, pkg),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    _buildSectionTitle(Icons.layers, "Buy Packages"),
                    const SizedBox(height: 8),

                    if (provider.availablePackages.isEmpty &&
                        !provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "No additional packages to buy right now.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.availablePackages.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final pkg = provider.availablePackages[index];
                          return _buildPackageCard(
                            package: pkg,
                            onDetailsTap: () =>
                                _openPackageDetail(context, provider, pkg),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.card_giftcard, color: Color(0xFFFFA500), size: 28),
        const SizedBox(width: 8),
        const Text(
          "Packages",
          style: TextStyle(
            color: Color(0xFFFFA500),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF555555), size: 20),
          const SizedBox(width: 10),
          const Text(
            "Search classes or packages…",
            style: TextStyle(color: Color(0xFF444444), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    final categories = ["All", "Gym", "Yoga", "HIIT", "Swim"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final bool isActive = cat == "All";
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFFA500)
                  : const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFFFA500)
                    : const Color(0xFF333333),
                width: 1.5,
              ),
            ),
            child: Text(
              cat,
              style: TextStyle(
                color: isActive ? Colors.black : const Color(0xFFAAAAAA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFA500), size: 14),
        const SizedBox(width: 5),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard({
    required PackageModel package,
    required VoidCallback onDetailsTap,
  }) {
    IconData getIcon(String name) {
      switch (name) {
        case 'directions_run':
          return Icons.directions_run;
        case 'fitness_center':
        default:
          return Icons.fitness_center;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: package.isFeatured
            ? const Color(0xFF0F0F0F)
            : const Color(0xFF111111),
        border: Border.all(
          color: package.isFeatured
              ? const Color(0xFFFFA500)
              : const Color(0xFF2A2A2A),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getIcon(package.iconName),
                  color: const Color(0xFFFFA500),
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                package.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                package.description,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "RM ${package.price.toStringAsFixed(0)} ",
                              style: const TextStyle(
                                color: Color(0xFFFFA500),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(
                              text: "/ pack",
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFFFFA500),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${package.sessionsCount} Sessions Included",
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onDetailsTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "View Details",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (package.badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  package.badge!.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivePackageCard({
    required PackageModel package,
    required int credits,
    required DateTime? expiry,
    required VoidCallback onBookTap,
    required VoidCallback onDetailsTap,
  }) {
    final expiryLabel = expiry == null
        ? '-'
        : DateFormat('d MMM y').format(expiry);

    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  package.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$credits credits left · valid until $expiryLabel',
            style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: onBookTap,
                  child: const Text('Book Slot'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFA500)),
                ),
                onPressed: onDetailsTap,
                child: const Text(
                  'Details',
                  style: TextStyle(color: Color(0xFFFFA500)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
