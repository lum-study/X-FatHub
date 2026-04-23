import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'login_screen.dart';
import 'profile_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileViewModel>();

    return profileProvider.isAuthenticated
        ? const ProfileDashboardScreen()
        : const LoginScreen();
  }
}

