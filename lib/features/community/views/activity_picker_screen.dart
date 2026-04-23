import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../activity_health/models/activity_model.dart';
import '../../activity_health/repositories/activity_repository.dart';

class ActivityPickerScreen extends StatefulWidget {
  const ActivityPickerScreen({super.key});

  @override
  State<ActivityPickerScreen> createState() => _ActivityPickerScreenState();
}

class _ActivityPickerScreenState extends State<ActivityPickerScreen> {
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final repository = ActivityRepository();

      // Fetch activities for the current authenticated user
      final authActivities = currentUserId != null 
          ? await repository.getActivitiesByUser(currentUserId) 
          : <ActivityModel>[];
          
      // Also fetch 'user123' activities which were recorded as a fallback in ActivityLogScreen
      final fallbackActivities = await repository.getActivitiesByUser('user123');
      
      // Combine them and remove duplicates by ID
      final Map<String, ActivityModel> uniqueActivities = {};
      for (var act in [...authActivities, ...fallbackActivities]) {
        uniqueActivities[act.id] = act;
      }
      final allActivities = uniqueActivities.values.toList();
      
      allActivities.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      if (mounted) {
        setState(() {
          _activities = allActivities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Select a Workout', style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _activities.isEmpty
                  ? const Center(child: Text('No workouts found.', style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final act = _activities[index];
                        final title = act.title ?? '${act.activityType[0].toUpperCase()}${act.activityType.substring(1)}';
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.fitness_center, color: Colors.black, size: 20),
                          ),
                          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${act.distanceTraveled.toStringAsFixed(2)} km • ${act.durationString}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.pop(context, act);
                          },
                        );
                      },
                    ),
    );
  }
}