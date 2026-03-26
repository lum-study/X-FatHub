import 'package:flutter/material.dart';
import 'package:xfathub/core/config/env_config.dart';
import 'package:xfathub/core/service/supabase_service.dart';
import 'package:xfathub/routes/app_routes.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.init();
  await SupabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return
    // Can specify the global provider here
    MaterialApp(
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
    );
  }
}