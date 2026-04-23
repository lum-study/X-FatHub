import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xfathub/core/config/env_config.dart';
import 'package:xfathub/core/service/supabase_service.dart';
import 'package:xfathub/core/service/permission_service.dart';
import 'package:xfathub/core/providers/app_providers.dart';
import 'package:xfathub/routes/app_routes.dart';
import 'package:xfathub/core/service/background_service.dart';
import 'package:xfathub/core/service/work_manager_service.dart';
import 'package:xfathub/features/activity_health/views/hydration_log_screen.dart';
import 'package:xfathub/routes/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.init();
  await SupabaseService.init();
  
  // Initialize Background Service for continuous step tracking
  await BackgroundService.initializeService();
  
  // Initialize WorkManager for reliable scheduled background tasks
  await WorkManagerService.initWorkManager();
  
  // Execute quick sync on app launch
  await WorkManagerService.executeQuickSyncOnAppLaunch();
  
  // Request permissions early (Activity recognition for step tracking)
  await PermissionService.requestStepTrackerPermissions();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const deepLinkChannel = MethodChannel('com.example.xfathub/deep_link');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Listen for deep link calls from Android
    deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'navigate') {
        final route = call.arguments['route'] as String;
        print('📱 Deep link route received: $route');
        
        // Navigate to the route
        if (route == '/hydration') {
          // Use the MainNavigationScreen's method to navigate within the tracker tab
          MainNavigationScreen.navigateToTrackerRoute(
            const HydrationLogScreen(),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'X-FatHub',
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: Colors.orange,
          scaffoldBackgroundColor: Colors.black,

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,   // AppBar background
            foregroundColor: Colors.orange,   // AppBar text & icon color
          ),

          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.white,
            type: BottomNavigationBarType.fixed,
          ),

          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.orange),
            bodyMedium: TextStyle(color: Colors.orange),
            bodySmall: TextStyle(color: Colors.orange),
            titleLarge: TextStyle(color: Colors.orange),
            titleMedium: TextStyle(color: Colors.orange),
            titleSmall: TextStyle(color: Colors.orange),
            labelLarge: TextStyle(color: Colors.orange),
            labelMedium: TextStyle(color: Colors.orange),
            labelSmall: TextStyle(color: Colors.orange),
          ),
        ),
      ),
    );
  }
}
