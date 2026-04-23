import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/home/views/home_screen.dart';
import '../features/home/views/profile_dashboard_screen.dart';
import '../features/community/views/feeds_screen.dart';
import '../features/booking/views/packages_screen.dart';
import '../features/activity_health/views/tracker_feature_list_screen.dart';
import '../features/home/providers/profile_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();

  /// Navigate to a specific route within the tracker tab
  static void navigateToTrackerRoute(Widget screen) {
    _MainNavigationScreenState._navigateToTrackerRoute(screen);
  }
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 2;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  // Static reference to the current state for deep link navigation
  static _MainNavigationScreenState? _instance;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  /// Navigate to a specific route within a tab
  static void _navigateToTrackerRoute(Widget screen) {
    if (_instance != null) {
      // Switch to tracker tab if not already there
      if (_instance!._selectedIndex != 3) {
        _instance!.setState(() {
          _instance!._selectedIndex = 3;
        });
      }
      // Push the screen onto the tracker tab's navigator
      _instance!._navigatorKeys[3].currentState?.push(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final isAuthenticated = profileProvider.isAuthenticated;

    // If not authenticated, show only the Home (Login) screen without navigation
    if (!isAuthenticated) {
      return const HomeScreen();
    }

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildTab(0, (_) => const FeedsScreen()),
            _buildTab(1, (_) => const PackagesScreen()),
            _buildTab(2, (_) => const HomeScreen()),
            _buildTab(3, (_) => const TrackerFeatureListScreen()),
            _buildTab(4, (_) => const ProfileDashboardScreen()), // Profile tab shows dashboard, settings via icon
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF0D0D0D),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, "Community"),
                _buildNavItem(1, Icons.card_giftcard, "Packages"),
                _buildHomeNavItem(),
                _buildNavItem(3, Icons.fitness_center, "Tracker"),
                _buildNavItem(4, Icons.person_outline, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
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

  Widget _buildHomeNavItem() {
    final isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFA500),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home,
              size: 20,
              color: isSelected ? Colors.black : Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, WidgetBuilder homeBuilder) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: homeBuilder);
      },
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _handleBackPress() async {
    if (_navigatorKeys[_selectedIndex].currentState?.canPop() ?? false) {
      _navigatorKeys[_selectedIndex].currentState?.pop();
      return false;
    } else {
      if (_selectedIndex == 2) return Future.value(true);
      setState(() => _selectedIndex = 2);
      return false;
    }
  }
}
