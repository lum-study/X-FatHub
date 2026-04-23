import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodels/activity_tracking_viewmodel.dart';
import '../models/activity_model.dart';

/// Live Activity Tracking Screen
/// Displays real-time map with user location, route, and activity metrics
class ActivityTrackingScreen extends StatefulWidget {
  final String userId;
  final String activityType;
  final String? title;
  final String? description;

  const ActivityTrackingScreen({
    Key? key,
    required this.userId,
    required this.activityType,
    this.title,
    this.description,
  }) : super(key: key);

  @override
  State<ActivityTrackingScreen> createState() => _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends State<ActivityTrackingScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeActivity();
  }

  Future<void> _initializeActivity() async {
    final viewModel = Provider.of<ActivityTrackingViewModel>(
      context,
      listen: false,
    );

    try {
      print('🔍 Initializing activity tracking...');
      
      // Initialize permissions and location services
      await viewModel.init(widget.userId, null);

      if (viewModel.hasError) {
        print('❌ Init failed: ${viewModel.errorMessage}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Init Error: ${viewModel.errorMessage}'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('✓ Permissions granted, ready to start activity');
      // Don't start automatically - wait for user to press Start button
    } catch (e) {
      print('❌ Initialization exception: $e');
    }
  }

  Future<void> _startTracking() async {
    final viewModel = Provider.of<ActivityTrackingViewModel>(
      context,
      listen: false,
    );

    try {
      print('▶️ Starting activity tracking...');
      
      await viewModel.startActivity(
        userId: widget.userId,
        activityType: widget.activityType,
        title: widget.title,
        description: widget.description,
      );

      if (viewModel.hasError) {
        print('❌ Start activity failed: ${viewModel.errorMessage}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Start Error: ${viewModel.errorMessage}'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('✓ Activity tracking started');
    } catch (e) {
      print('❌ Start tracking exception: $e');
    }
  }

  @override
  void dispose() {
    print('🧹 ActivityTrackingScreen dispose called');
    
    // Ensure MapController is disposed
    _mapController.dispose();
    
    // Stop any active tracking when screen is disposed
    final viewModel = Provider.of<ActivityTrackingViewModel>(
      context,
      listen: false,
    );
    
    if (viewModel.isTracking) {
      print('⚠️ Activity still tracking during screen dispose - stopping...');
      viewModel.discardActivity();
    }
    
    print('✅ ActivityTrackingScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent accidental back during tracking
        if (context.read<ActivityTrackingViewModel>().isTracking) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stop activity before exiting'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Consumer<ActivityTrackingViewModel>(
            builder: (context, viewModel, _) {
            // Convert viewModel route points to LatLng for map display
            final routeLatLngs = viewModel.routePoints.isNotEmpty
                ? viewModel.routePoints
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList()
                : <LatLng>[];

            // Get current position from last route point or use default
            final currentPosition = viewModel.currentLocation != null
                ? LatLng(viewModel.currentLocation!.latitude,
                    viewModel.currentLocation!.longitude)
                : (routeLatLngs.isNotEmpty
                    ? LatLng(viewModel.routePoints.last.latitude,
                        viewModel.routePoints.last.longitude)
                    : const LatLng(51.5, -0.09));

            // Update map center - both during tracking and when location is acquired
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (viewModel.currentLocation != null) {
                // Always center on current location (preview or tracking)
                _mapController.move(currentPosition, 17);
              } else if (viewModel.isTracking &&
                  routeLatLngs.isNotEmpty) {
                // Fallback if no currentLocation but tracking
                _mapController.move(currentPosition, 17);
              }
            });

            return Stack(
              children: [
                // Map - Full screen
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentPosition,
                      initialZoom: 17,
                      minZoom: 1,
                      maxZoom: 19,
                    ),
                    children: [
                      // OpenStreetMap tiles
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.xfathub',
                        maxNativeZoom: 19,
                        subdomains: const ['a', 'b', 'c'],
                        retinaMode: true,
                      ),
                      // Route polyline
                      if (routeLatLngs.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routeLatLngs,
                              color: Colors.orange.withOpacity(0.7),
                              strokeWidth: 4.0,
                              borderColor: Colors.orangeAccent,
                              borderStrokeWidth: 1.0,
                            ),
                          ],
                        ),
                      // Route start marker
                      if (routeLatLngs.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: routeLatLngs.first,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.flag_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      // Current location marker
                      if (viewModel.currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: currentPosition,
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Error Banner (if exists)
                if (viewModel.hasError)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.red.withOpacity(0.9),
                      padding: const EdgeInsets.all(16),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ERROR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              viewModel.errorMessage ?? 'Unknown error',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Refresh button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    print('🔄 Retrying location acquisition...');
                                    viewModel.retryLocationTracking(widget.userId);
                                  },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Open location settings button
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    print('📍 Opening location settings...');
                                    await Geolocator.openLocationSettings();
                                  },
                                  icon: const Icon(Icons.location_on, size: 18),
                                  label: const Text('Open Settings'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Start Button + Dashboard Container (Bottom)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // Center on current location
                                _mapController.move(
                                  LatLng(viewModel.currentLocation!.latitude,
                                      viewModel.currentLocation!.longitude),
                                  17,
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.location_searching,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Start Button
                      _buildControlButtons(viewModel),
                      // Spacing
                      const SizedBox(height: 12),
                      // Dashboard Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black87.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMetricsDashboard(viewModel),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            },
          ),
        ),
      ),
    );
  }

  /// Build metrics dashboard widget
  Widget _buildMetricsDashboard(ActivityTrackingViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Time',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              viewModel.formattedElapsedTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Distance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Distance',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              viewModel.formattedDistance,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Pace
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pace',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              viewModel.formattedPace,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Status indicator
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: viewModel.isPaused ? Colors.yellow : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              viewModel.isPaused ? 'Paused' : 'Tracking',
              style: TextStyle(
                color: viewModel.isPaused ? Colors.yellow : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build control buttons
  Widget _buildControlButtons(ActivityTrackingViewModel viewModel) {
    // Show "Start" button if not tracking and we have initial location
    if (!viewModel.isTracking && viewModel.hasInitialLocation) {
      return ElevatedButton.icon(
        onPressed: _startTracking,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          minimumSize: const Size.fromHeight(50),
        ),
      );
    }

    // Show disabled Start button while waiting for location
    if (!viewModel.isTracking && !viewModel.hasInitialLocation && !viewModel.isLoading) {
      return ElevatedButton.icon(
        onPressed: null,  // Disabled
        icon: const Icon(Icons.location_searching),
        label: const Text('Acquiring Location...'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          minimumSize: const Size.fromHeight(50),
        ),
      );
    }

    // Show Pause/Stop/Discard buttons when tracking
    if (viewModel.isTracking) {
      return Row(
        children: [
          // Pause/Resume button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                if (viewModel.isPaused) {
                  await viewModel.resumeActivity();
                } else {
                  await viewModel.pauseActivity();
                }
              },
              icon: Icon(viewModel.isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(viewModel.isPaused ? 'Resume' : 'Pause'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Stop button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text(
                      'End Activity?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to end this activity?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'End',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed ?? false) {
                  final success = await viewModel.completeActivity();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Activity saved successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.of(context).pop(viewModel.currentActivity);
                  }
                }
              },
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Discard button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text(
                      'Discard Activity?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'This activity will not be saved.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Discard',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed ?? false) {
                  await viewModel.discardActivity();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('Discard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    // Default: loading state
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.hourglass_empty),
      label: const Text('Initializing...'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }
}