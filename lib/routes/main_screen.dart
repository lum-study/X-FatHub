import 'package:flutter/material.dart';
import 'package:xfathub/features/activity_health/views/dashboard.dart';
import 'package:xfathub/features/home/views/home_screen.dart';
import 'package:xfathub/features/booking/views/packages_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 2; // Home is at index 2

  final pages = [
    const Center(child: Text("Post Screen")), // Placeholder for Post
    const PackagesScreen(),
    const HomeScreen(),
    Dashboard(),
    const Center(child: Text("Profile Screen")), // Placeholder for Profile
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (index != 2) {
          setState(() => index = 2);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        floatingActionButton: SizedBox(
          height: 65,
          width: 65,
          child: FloatingActionButton(
            onPressed: () => setState(() => index = 2),
            backgroundColor: const Color(0xFFFFA500),
            shape: const CircleBorder(),
            elevation: 4,
            child: Icon(
              Icons.home,
              size: 32,
              color: index == 2 ? Colors.black : Colors.black.withOpacity(0.7),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF0D0D0D),
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Side Buttons
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.grid_view_rounded, "Post"),
                      _buildNavItem(1, Icons.card_giftcard, "Packages"),
                    ],
                  ),
                ),
                const SizedBox(width: 80), // Space for FAB
                // Right Side Buttons
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(3, Icons.fitness_center, "Tracker"),
                      _buildNavItem(4, Icons.person_outline, "Profile"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int itemIndex, IconData icon, String label) {
    final isSelected = index == itemIndex;
    return GestureDetector(
      onTap: () => setState(() => index = itemIndex),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF555555),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF555555),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
