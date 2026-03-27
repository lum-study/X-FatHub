import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/home/views/home_screen.dart';
import '../features/post/views/post_screen.dart';
import '../features/packages/views/packages_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/activity_health/views/tracker_feature_list_screen.dart';
import '../features/activity_health/views/step_tracker_screen.dart';
import '../features/activity_health/views/hydration_log_screen.dart';
import '../features/activity_health/views/activity_log_screen.dart';
import '../features/activity_health/viewmodels/step_tracker_viewmodel.dart';
import '../features/activity_health/repositories/step_tracker_repository.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 2;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  // Define all the tabs
  static const List<String> _tabNames = [
    'Post',
    'Packages',
    'Home',
    'Tracker',
    'Profile',
  ];
  static const List<IconData> _tabIcons = [
    Icons.add_circle_outline,
    Icons.shopping_bag,
    Icons.home,
    Icons.fitness_center,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // Post tab with its own navigator
            _buildTab(0, (_) => const PostScreen()),
            // Packages tab with its own navigator
            _buildTab(1, (_) => const PackagesScreen()),
            // Home tab with its own navigator
            _buildTab(2, (_) => const HomeScreen()),
            // Tracker tab with nested navigation
            _buildTrackerTab(),
            // Profile tab with its own navigator
            _buildTab(4, (_) => const ProfileScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          items: List.generate(
            _tabNames.length,
            (index) => BottomNavigationBarItem(
              icon: Icon(_tabIcons[index]),
              label: _tabNames[index],
            ),
          ),
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

  Widget _buildTrackerTab() {
    return Navigator(
      key: _navigatorKeys[3],
      onGenerateRoute: (settings) {
        WidgetBuilder builder;

        switch (settings.name) {
          case '/tracker/step-tracker':
            builder = (_) => ChangeNotifierProvider(
              create: (_) => StepTrackerViewModel(
                repository: StepTrackerRepository(),
              ),
              child: const StepTrackerScreen(),
            );
            break;
          case '/tracker/hydration-log':
            builder = (_) => HydrationLogScreen();
            break;
          case '/tracker/activity-log':
            builder = (_) => const ActivityLogScreen();
            break;
          default:
            builder = (_) => const TrackerFeatureListScreen();
        }

        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) {
      // If tapping the same tab, pop to root
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      // Switch to the new tab
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<bool> _handleBackPress() {
    // Check if the current tab's navigator can pop
    if (_navigatorKeys[_selectedIndex].currentState?.canPop() ?? false) {
      _navigatorKeys[_selectedIndex].currentState?.pop();
      return Future.value(false); // Don't exit the app
    } else {
      // If we're in the Home tab and can't pop, exit
      if (_selectedIndex == 2) {
        return Future.value(true); // Exit the app
      } else {
        // Otherwise, return to Home tab
        setState(() {
          _selectedIndex = 2;
        });
        return Future.value(false); // Don't exit the app
      }
    }
  }
}
