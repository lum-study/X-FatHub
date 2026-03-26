import 'package:flutter/material.dart';

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
              _buildPackageCard(
                isFeatured: true,
                badge: "Popular",
                icon: Icons.fitness_center,
                name: "Ultimate Strength Pack",
                desc: "12 Sessions · Full Gym Access · Trainer Guided",
                price: "199",
                sessions: "12 Sessions Included",
              ),
              const SizedBox(height: 10),
              _buildPackageCard(
                isFeatured: false,
                icon: Icons.directions_run,
                name: "HIIT Blast — 6 Sessions",
                desc: "High Intensity · Cardio Focused · Group Class",
                price: "89",
                sessions: "6 Sessions Included",
              ),
              const SizedBox(height: 14),
              _buildSectionTitle(Icons.calendar_today, "Today's Gym Slots"),
              const SizedBox(height: 8),
              _buildSlotCard(
                time: "07:00",
                ampm: "AM",
                name: "Morning Strength",
                coach: "Coach Rafi · Zone A",
                spots: "4 spots",
              ),
              const SizedBox(height: 8),
              _buildSlotCard(
                time: "10:00",
                ampm: "AM",
                name: "Yoga Flow",
                coach: "Coach Aina · Studio 2",
                spots: "2 left",
                isLow: true,
              ),
              const SizedBox(height: 8),
              _buildSlotCard(
                time: "06:00",
                ampm: "PM",
                name: "Evening HIIT",
                coach: "Coach Ben · Zone B",
                spots: "Full",
                isFull: true,
              ),
            ],
          ),
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

  Widget _buildPackageCard({
    required bool isFeatured,
    String? badge,
    required IconData icon,
    required String name,
    required String desc,
    required String price,
    required String sessions,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFeatured ? const Color(0xFF0F0F0F) : const Color(0xFF111111),
        border: Border.all(
          color: isFeatured ? const Color(0xFFFFA500) : const Color(0xFF2A2A2A),
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
                child: Icon(icon, color: const Color(0xFFFFA500), size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
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
                              text: "RM $price ",
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
                            sessions,
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA500),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFeatured)
                          const Icon(Icons.bolt, color: Colors.black, size: 14),
                        Text(
                          "Buy",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (badge != null)
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
                  badge.toUpperCase(),
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

  Widget _buildSlotCard({
    required String time,
    required String ampm,
    required String name,
    required String coach,
    required String spots,
    bool isLow = false,
    bool isFull = false,
  }) {
    Color spotsColor = const Color(0xFFAAAAAA);
    Color spotsBg = const Color(0xFF1E1E1E);

    if (isLow) {
      spotsColor = const Color(0xFFFF6B35);
      spotsBg = const Color(0xFF1E1208);
    } else if (isFull) {
      spotsColor = const Color(0xFF555555);
      spotsBg = const Color(0xFF1A1A1A);
    }

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
                  time,
                  style: const TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ampm,
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
                  name,
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
                      coach,
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
              spots,
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
