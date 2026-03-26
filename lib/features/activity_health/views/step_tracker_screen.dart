import 'package:flutter/material.dart';
import 'dashboard.dart';

class StepTrackerScreen extends StatelessWidget {
  const StepTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Tracker'),
        elevation: 0,
      ),
      body: Dashboard(),
    );
  }
}
