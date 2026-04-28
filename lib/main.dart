import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:xfathub/core/config/env_config.dart';
import 'package:xfathub/core/service/supabase_service.dart';
import 'package:xfathub/core/service/permission_service.dart';
import 'package:xfathub/core/providers/app_providers.dart';
import 'package:xfathub/routes/app_routes.dart';
import 'package:xfathub/core/service/background_service.dart';
import 'package:xfathub/core/service/work_manager_service.dart';
import 'package:xfathub/features/activity_health/views/hydration_log_screen.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:xfathub/routes/main_navigation_screen.dart';

import 'core/service/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.init();
  await SupabaseService.init();
  
  // Initialize Background Service for continuous step tracking
  await BackgroundService.initializeService();
  
  // Initialize WorkManager for reliable scheduled background tasks
  await WorkManagerService.initWorkManager();
  
  // Request permissions early (Activity recognition for step tracking)
  await PermissionService.requestStepTrackerPermissions();
  
  // Request notification permission (Android 13+)
  await PermissionService.requestNotificationPermission();

  // Initialize Notification Service
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const deepLinkChannel = MethodChannel('com.example.xfathub/deep_link');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
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
        } else if (route == '/payment/success') {
          navigatorKey.currentState?.pushNamed(AppRoutes.paymentSuccess);
        } else if (route == '/payment/cancel') {
          navigatorKey.currentState?.pushNamed(AppRoutes.paymentCancel);
        } else if (route.contains('/auth/verified')) {
          navigatorKey.currentState?.pushNamed(AppRoutes.emailVerified);
        }
      }
    });
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      
      if (isOnline && _wasOffline) {
        debugPrint('🌐 Network restored. Refreshing app data...');
        _refreshAppData();
      }
      
      _wasOffline = !isOnline;
    });
  }

  void _refreshAppData() {
    // Wrap in microtask to ensure context is available if needed, 
    // though using provider via context in initState/listeners requires caution.
    Future.microtask(() {
      if (!mounted) return;
      
      final context = navigatorKey.currentContext;
      if (context == null) return;

      // Refresh Booking Data
      final bookingVM = Provider.of<BookingViewModel>(context, listen: false);
      bookingVM.refreshPackagesPage();
      
      // Refresh Profile Data
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
      profileVM.init();

      // You can add more viewmodels here as needed
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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
          // Set canvasColor and colorScheme surface to black to prevent white flashes
          canvasColor: Colors.black,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange).copyWith(
            surface: Colors.black,
            onSurface: Colors.orange,
            background: Colors.black,
          ),
          primarySwatch: Colors.orange,
          primaryColor: Colors.orange,
          scaffoldBackgroundColor: Colors.black,

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,   // AppBar background
            foregroundColor: Colors.orange,   // AppBar text & icon color
            elevation: 0,
          ),

          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
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
