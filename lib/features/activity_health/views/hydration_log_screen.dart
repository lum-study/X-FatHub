import 'package:flutter/material.dart';
import 'hydration_log.dart';

class HydrationLogScreen extends StatelessWidget {
  const HydrationLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration Log'),
        elevation: 0,
      ),
      body: HydrationLog(),
    );
  }
}
