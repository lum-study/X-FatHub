import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 64, color: Colors.orange.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Home Module', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Coming soon',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ],
        ),
      ),
    );
  }
}
