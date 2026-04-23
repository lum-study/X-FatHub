import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:supabase_flutter/supabase_flutter.dart'; //add by weikang
import '../viewmodels/step_tracker_viewmodel.dart';
import 'activity_tracking_screen.dart';
import 'activity_history_screen.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  String? _selectedActivityType;
  String? _activityTitle;
  String? _activityDescription;

  @override
  Widget build(BuildContext context) {
    final stepTrackerViewModel = context.watch<StepTrackerViewModel>();
    final userId = 'user123'; // This should come from auth provider
    //final userId = Supabase.instance.client.auth.currentUser?.id ?? 'user123'; // add by weikang

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            'Live Activity Tracking',
          ),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Start Tracking'),
              Tab(text: 'History'),
            ],
            indicatorColor: Colors.black,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.white,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // Start Tracking Tab
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Activity Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActivityTypeSelector(),
                    const SizedBox(height: 24),
                    const Text(
                      'Activity Title (Optional)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => _activityTitle = value,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g., Morning Walk',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.orange,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.orange,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.orangeAccent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Notes (Optional)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => _activityDescription = value,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add notes about your activity...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.orange,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.orange,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.orangeAccent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedActivityType != null
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ActivityTrackingScreen(
                                          userId: userId,
                                          activityType: _selectedActivityType!,
                                          title: _activityTitle,
                                          description: _activityDescription,
                                        ),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.location_on),
                        label: const Text(
                          'Start Tracking',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
              // History Tab
              ActivityHistoryScreen(userId: userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTypeSelector() {
    final activityTypes = ['Running', 'Cycling'];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: activityTypes.map((type) {
        final isSelected = _selectedActivityType == type.toLowerCase();
        return GestureDetector(
          onTap: () => setState(
            () => _selectedActivityType = type.toLowerCase(),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.grey[900],
              border: Border.all(
                color: isSelected ? Colors.orangeAccent : Colors.orange,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
