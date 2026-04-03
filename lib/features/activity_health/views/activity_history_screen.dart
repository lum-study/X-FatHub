import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_model.dart';
import '../repositories/activity_repository.dart';
import 'activity_summary_screen.dart';

/// ViewModel for Activity History
class ActivityHistoryViewModel extends ChangeNotifier {
  final ActivityRepository _repository;

  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ActivityModel> get activities => _activities;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  ActivityHistoryViewModel({ActivityRepository? repository})
    : _repository = repository ?? ActivityRepository();

  /// Load activities for a user
  Future<void> loadActivities(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activities = await _repository.getActivitiesByUser(userId);
      // Sort by date descending
      _activities.sort((a, b) => b.startTime.compareTo(a.startTime));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load activities: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete an activity
  Future<void> deleteActivity(String activityId) async {
    try {
      await _repository.deleteActivity(activityId);
      _activities.removeWhere((a) => a.id == activityId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete activity: $e';
      notifyListeners();
    }
  }
}

/// Activity History Screen
/// Displays a list of all past activities with the ability to view details
class ActivityHistoryScreen extends StatefulWidget {
  final String userId;

  const ActivityHistoryScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  late ActivityHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ActivityHistoryViewModel();
    _viewModel.loadActivities(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivityHistoryViewModel>.value(
      value: _viewModel,
      child: Consumer<ActivityHistoryViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            );
          }

          if (viewModel.hasError) {
            return Center(
              child: Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (viewModel.activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No activities yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking to see your activities here',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: viewModel.activities.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final activity = viewModel.activities[index];
              return _buildActivityCard(context, activity, viewModel);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    ActivityModel activity,
    ActivityHistoryViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Load route points and navigation to summary
            final repository = ActivityRepository();
            final routePoints = await repository.getRoutePoints(activity.id);
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ActivitySummaryScreen(
                    activity: activity,
                    routePoints: routePoints,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date & Delete Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title ??
                              '${activity.activityType[0].toUpperCase()}${activity.activityType.substring(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.startTime.toString().split('.')[0],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text(
                                'Delete Activity?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'This action cannot be undone.',
                                style: TextStyle(color: Colors.grey),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed ?? false) {
                            await viewModel.deleteActivity(activity.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Activity deleted'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      color: Colors.grey[800],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatTile(
                      label: 'Distance',
                      value:
                          '${activity.distanceTraveled.toStringAsFixed(2)} km',
                    ),
                    _buildStatTile(
                      label: 'Duration',
                      value: activity.durationString,
                    ),
                    _buildStatTile(
                      label: 'Pace',
                      value: '${activity.averagePace.toStringAsFixed(2)} km/h',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({required String label, required String value}) {
    return Center(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
