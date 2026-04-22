import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/profile/views/home_screen.dart';
import '../features/profile/views/profile_dashboard_screen.dart';
import '../features/community/views/feeds_screen.dart';
import '../features/booking/views/packages_screen.dart';
import '../features/activity_health/views/tracker_feature_list_screen.dart';
import '../features/community/providers/community_provider.dart';
import '../features/profile/viewmodels/profile_viewmodel.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 2;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<ProfileViewModel>();
    final isAuthenticated = profileViewModel.isAuthenticated;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildNavItem(0, Icons.grid_view_rounded, "Community")),
                Expanded(child: _buildNavItem(1, Icons.card_giftcard, "Packages")),
                Expanded(child: _buildHomeNavItem()),
                Expanded(child: _buildNavItem(3, Icons.fitness_center, "Tracker")),
                Expanded(child: _buildNavItem(4, Icons.person_outline, "Profile")),
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
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildHomeNavItem() {
    final isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                color: isSelected ? Colors.black : Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
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

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CommunityProvider>().requestScrollToTop();
      });
    }
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
