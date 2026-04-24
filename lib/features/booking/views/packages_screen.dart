import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/views/package_detail_screen.dart';
import 'package:xfathub/features/booking/views/book_and_pay_screen.dart';
import 'package:xfathub/features/booking/views/checkout_screen.dart';
import 'package:xfathub/features/booking/views/booking_history_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showInactive = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<BookingViewModel>(context, listen: false);
        provider.initializePackagesPage();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PackageModel> _filterPackages(List<PackageModel> packages) {
    return packages.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' ||
          p.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Color _getBadgeColor(String? badge) {
    switch (badge?.toLowerCase()) {
      case 'popular':
        return const Color(0xFFFFA500);
      case 'starter':
        return const Color(0xFF2196F3);
      case 'best value':
      case 'bestvalue':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFFFFA500);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'gym':
        return const Color(0xFF2196F3);
      case 'yoga':
        return const Color(0xFF9C27B0);
      case 'hiit':
        return const Color(0xFFF44336);
      case 'swim':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF888888);
    }
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

  void _openPurchaseFlow(
    BuildContext context,
    BookingViewModel provider,
    PackageModel package,
  ) {
    provider.selectPackage(package);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(package: package)),
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
                        Icons.wifi_off,
                        color: Color(0xFFFFA500),
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You are offline',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Only can view booking history from cache.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Connect to the internet to browse packages.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('My Bookings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA500),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => provider.refreshPackagesPage(),
              color: const Color(0xFFFFA500),
              backgroundColor: const Color(0xFF1A1A1A),
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
                    ..._buildPackagesList(provider),
                    const SizedBox(height: 24),
                    _buildInactiveToggle(provider),
                    if (_showInactive) ...[
                      const SizedBox(height: 16),
                      ..._buildInactivePackagesList(provider),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInactiveToggle(BookingViewModel provider) {
    final inactiveCount = _filterPackages(provider.inactivePackages).length;
    if (inactiveCount == 0 && !provider.isLoading) return const SizedBox.shrink();

    return Center(
      child: TextButton.icon(
        onPressed: () => setState(() => _showInactive = !_showInactive),
        icon: Icon(
          _showInactive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
        label: Text(
          _showInactive 
              ? 'Hide Expired/Inactive' 
              : 'Show Expired/Inactive ($inactiveCount)',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  List<Widget> _buildInactivePackagesList(BookingViewModel provider) {
    final inactiveFiltered = _filterPackages(provider.inactivePackages);
    if (inactiveFiltered.isEmpty) return [];

    return inactiveFiltered.map((pkg) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildInactivePackageCard(
          package: pkg,
          onDetailsTap: () => _openPackageDetail(context, provider, pkg),
        ),
      );
    }).toList();
  }

  Widget _buildInactivePackageCard({
    required PackageModel package,
    required VoidCallback onDetailsTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.grey[900]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                package.name,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Text(
                  'INACTIVE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            package.description,
            style: const TextStyle(color: Color(0xFF444444), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expired or Deactivated',
                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                onTap: onDetailsTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    "View Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  List<Widget> _buildPackagesList(BookingViewModel provider) {
    final widgets = <Widget>[];
    final activeFiltered = _filterPackages(provider.activePackages);
    final availableFiltered = _filterPackages(provider.availablePackages);

    if (activeFiltered.isNotEmpty) {
      widgets.add(_buildSectionTitle(Icons.stars_rounded, 'Active Packages'));
      widgets.add(const SizedBox(height: 8));
      for (var i = 0; i < activeFiltered.length; i++) {
        final pkg = activeFiltered[i];
        final credits = provider.sessionsRemainingByPackage[pkg.id] ?? 0;
        final expiry = provider.expiryByPackage[pkg.id];
        widgets.add(
          _buildActivePackageCard(
            package: pkg,
            credits: credits,
            expiry: expiry,
            onBookTap: () => _openBookSlot(context, provider, pkg),
            onBuyMoreTap: () => _openPurchaseFlow(context, provider, pkg),
            onDetailsTap: () => _openPackageDetail(context, provider, pkg),
          ),
        );
        if (i < activeFiltered.length - 1) {
          widgets.add(const SizedBox(height: 10));
        }
      }
      widgets.add(const SizedBox(height: 14));
    }

    widgets.add(_buildSectionTitle(Icons.layers, 'Buy Packages'));
    widgets.add(const SizedBox(height: 8));

    if (availableFiltered.isEmpty && !provider.isLoading) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No packages found.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    } else {
      for (var i = 0; i < availableFiltered.length; i++) {
        final pkg = availableFiltered[i];
        widgets.add(
          _buildPackageCard(
            package: pkg,
            onDetailsTap: () => _openPackageDetail(context, provider, pkg),
          ),
        );
        if (i < availableFiltered.length - 1) {
          widgets.add(const SizedBox(height: 10));
        }
      }
    }
    return widgets;
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.card_giftcard, color: Color(0xFFFFA500), size: 28),
        const SizedBox(width: 8),
        const Text(
          'Packages',
          style: TextStyle(
            color: Color(0xFFFFA500),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
          ),
          icon: const Icon(Icons.history, color: Color(0xFFFFA500), size: 24),
          tooltip: 'Booking History',
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
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Search classes or packages…",
                hintStyle: TextStyle(color: Color(0xFF444444), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(
                Icons.clear,
                color: Color(0xFF555555),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    final categories = ['All', 'Gym', 'Yoga', 'HIIT', 'Swim'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isActive = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
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
    const badgeColor = Color(0xFFFFA500);
    IconData getIcon(String name) =>
        name == 'directions_run' ? Icons.directions_run : Icons.fitness_center;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: package.isFeatured
            ? const Color(0xFF0F0F0F)
            : const Color(0xFF111111),
        border: Border.all(
          color: package.isFeatured ? badgeColor : const Color(0xFF2A2A2A),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      color: badgeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        package.category,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      package.category,
                      style: TextStyle(
                        color: _getCategoryColor(package.category),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
                              style: TextStyle(
                                color: badgeColor,
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
                          Icon(Icons.check_circle, color: badgeColor, size: 12),
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
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
                  color: badgeColor,
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
    required VoidCallback onBuyMoreTap,
    required VoidCallback onDetailsTap,
  }) {
    final expiryLabel = expiry == null
        ? '-'
        : DateFormat('d MMM y').format(expiry);
    const badgeColor = Color(0xFFFFA500);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor.withValues(alpha: 0.15), const Color(0xFF0F0F0F)],
        ),
        border: Border.all(color: badgeColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          package.category,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        package.category,
                        style: TextStyle(
                          color: _getCategoryColor(package.category),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
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
            '$credits sessions left · valid until $expiryLabel',
            style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: badgeColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: onBookTap,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 16),
                      SizedBox(width: 6),
                      Text('Book'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: badgeColor),
                  ),
                  onPressed: onBuyMoreTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 6),
                      Text('More', style: TextStyle(color: badgeColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: badgeColor),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onDetailsTap,
                  child: Icon(Icons.info_outline, color: badgeColor, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
