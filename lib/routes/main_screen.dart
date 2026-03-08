import 'package:flutter/material.dart';
import 'package:xfathub/features/activity_health/views/dashboard.dart';
import 'package:xfathub/features/activity_health/views/hydration_log.dart';
import 'package:xfathub/features/home/views/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 2;

  final pages = [
    const Center(child: Text("Post Screen")), // Placeholder
    const Center(child: Text("Packages Screen")), // Placeholder
    HomeScreen(),
    Dashboard(),
    HydrationLog(),
  ];

  final titles = [
    'Post', 'Packages', 'Home', 'Tracker', 'Profile'
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:  () async {
        if (index != 2) {
          // If not on Home tab, go back to Home tab
          setState(() => index = 2);
          return false; // prevent default back action
        } else {
          // If already on Home tab, allow default back action (exit app)
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[index]),
        ),
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: (value) {
            setState(() {
              index = value;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk),
              label: "Post",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: "Packages",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: "Tracker",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}