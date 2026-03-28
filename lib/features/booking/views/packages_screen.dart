import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:xfathub/features/booking/providers/booking_provider.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/models/slot_model.dart';
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
        final provider = Provider.of<BookingProvider>(context, listen: false);
        provider.initializePackagesPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<BookingProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.packages.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFA500)));
            }

            return RefreshIndicator(
              onRefresh: () async {
                await provider.refreshPackagesPage();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildCategoryPills(),
                    const SizedBox(height: 14),
                    _buildSectionTitle(Icons.layers, "Class Packages"),
                    const SizedBox(height: 8),
                    
                    if (provider.packages.isEmpty && !provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("No packages available.", style: TextStyle(color: Colors.white54)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.packages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final pkg = provider.packages[index];
                          return _buildPackageCard(
                            package: pkg,
                            onTap: () {
                              provider.selectPackage(pkg);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BookAndPayScreen()),
                              );
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 14),
                    _buildSectionTitle(Icons.calendar_today, "Today's Gym Slots"),
                    const SizedBox(height: 8),

                    if (provider.slots.isEmpty && !provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("No slots available for today.", style: TextStyle(color: Colors.white54)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.slots.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final slot = provider.slots[index];
                          return _buildSlotCard(slot: slot);
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
        ),
        const Icon(Icons.notifications_none, color: Color(0xFFFFA500), size: 28),
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
              color: isActive ? const Color(0xFFFFA500) : const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isActive ? const Color(0xFFFFA500) : const Color(0xFF333333),
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

  Widget _buildPackageCard({required PackageModel package, required VoidCallback onTap}) {
    IconData getIcon(String name) {
      switch (name) {
        case 'directions_run': return Icons.directions_run;
        case 'fitness_center': 
        default: return Icons.fitness_center;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: package.isFeatured ? const Color(0xFF0F0F0F) : const Color(0xFF111111),
        border: Border.all(
          color: package.isFeatured ? const Color(0xFFFFA500) : const Color(0xFF2A2A2A),
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
                child: Icon(getIcon(package.iconName), color: const Color(0xFFFFA500), size: 20),
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
                          const Icon(Icons.check_circle,
                              color: Color(0xFFFFA500), size: 12),
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
                    onTap: onTap,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (package.isFeatured)
                            const Icon(Icons.bolt, color: Colors.black, size: 14),
                          const Text(
                            "Book",
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

  Widget _buildSlotCard({required SlotModel slot}) {
    Color spotsColor = const Color(0xFFAAAAAA);
    Color spotsBg = const Color(0xFF1E1E1E);

    if (slot.isLow) {
      spotsColor = const Color(0xFFFF6B35);
      spotsBg = const Color(0xFF1E1208);
    } else if (slot.isFull) {
      spotsColor = const Color(0xFF555555);
      spotsBg = const Color(0xFF1A1A1A);
    }

    final timeStr = DateFormat('hh:mm').format(slot.startTime);
    final ampmStr = DateFormat('a').format(slot.startTime);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ampmStr,
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.className,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFFFFA500), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      "${slot.coachName} · ${slot.location}",
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: spotsBg,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              slot.isFull ? "Full" : "${slot.spotsLeft} spots",
              style: TextStyle(
                color: spotsColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
