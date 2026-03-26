import 'package:flutter/material.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: Colors.orange.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Activity Log',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Track jogging and cycling with map integration',
              style: TextStyle(color: Color(0xFFAAAAAA)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
