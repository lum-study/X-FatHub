import 'package:flutter/material.dart';

class TrackerFeatureListScreen extends StatelessWidget {
  const TrackerFeatureListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Select a tracker',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            _buildFeatureCard(
              context,
              icon: Icons.directions_walk,
              title: 'Step Tracker',
              description: 'Track your daily steps and goals',
              onTap: () => Navigator.of(context).pushNamed('/tracker/step-tracker'),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.local_drink,
              title: 'Hydration Log',
              description: 'Log your water intake',
              onTap: () => Navigator.of(context).pushNamed('/tracker/hydration-log'),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.directions_run,
              title: 'Activity Log',
              description: 'Track jogging and cycling with maps',
              onTap: () => Navigator.of(context).pushNamed('/tracker/activity-log'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF2A2A2A)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF262626),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.orange,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
