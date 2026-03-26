import 'package:flutter/material.dart';

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packages'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping,
              size: 64,
              color: Colors.orange.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Packages Module',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
