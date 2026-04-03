import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/activity_model.dart';
import '../models/activity_location_point.dart';

/// Activity Summary Screen
/// Displays a summary of a completed activity with route map and statistics
class ActivitySummaryScreen extends StatefulWidget {
  final ActivityModel activity;
  final List<ActivityLocationPoint> routePoints;

  const ActivitySummaryScreen({
    Key? key,
    required this.activity,
    this.routePoints = const [],
  }) : super(key: key);

  @override
  State<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  List<LatLng> _getRouteLatLng() {
    final validPoints = widget.routePoints
        .where((p) {
          // Filter out invalid coordinates
          final lat = p.latitude;
          final lng = p.longitude;
          final isValid =
              lat.isFinite &&
              lng.isFinite &&
              lat >= -90 &&
              lat <= 90 &&
              lng >= -180 &&
              lng <= 180;
          if (!isValid) {
            print('⚠️ Filtered invalid coordinate: lat=$lat, lng=$lng');
          }
          return isValid;
        })
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    if (validPoints.length < widget.routePoints.length) {
      print(
        '📍 Route points: ${widget.routePoints.length} total, ${validPoints.length} valid',
      );
    }

    return validPoints;
  }

  @override
  Widget build(BuildContext context) {
    final routeLatLng = _getRouteLatLng();
    LatLngBounds? bounds;

    // Only create bounds if we have at least 2 valid points
    if (routeLatLng.length >= 2) {
      try {
        bounds = LatLngBounds.fromPoints(routeLatLng);
        // Validate bounds are valid numbers
        if (!bounds.north.isFinite ||
            !bounds.south.isFinite ||
            !bounds.east.isFinite ||
            !bounds.west.isFinite) {
          bounds = null;
        }
      } catch (e) {
        print('❌ Error calculating bounds: $e');
        bounds = null;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Activity Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // Route Map
            if (bounds != null)
              Container(
                height: 300,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(50),
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.xfathub',
                      ),
                      // Route Polyline
                      PolylineLayer(
                        polylines: [
                          if (routeLatLng.isNotEmpty)
                            Polyline(
                              points: routeLatLng,
                              color: Colors.orange.withOpacity(0.7),
                              strokeWidth: 4.0,
                              borderColor: Colors.orangeAccent,
                              borderStrokeWidth: 1.0,
                            ),
                        ],
                      ),
                      // Start and End Markers
                      MarkerLayer(
                        markers: [
                          // Start marker
                          if (routeLatLng.isNotEmpty)
                            Marker(
                              point: routeLatLng.first,
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
                          // End marker
                          if (routeLatLng.isNotEmpty)
                            Marker(
                              point: routeLatLng.last,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.stop_circle_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 200,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'No route data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            // Activity Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activity.title ??
                        '${widget.activity.activityType[0].toUpperCase()}${widget.activity.activityType.substring(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.activity.startTime.toString().split('.')[0]}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Main Statistics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Column(
                  children: [
                    // Distance & Duration Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          label: 'Distance',
                          value:
                              '${widget.activity.distanceTraveled.toStringAsFixed(2)} km',
                          color: Colors.orange,
                        ),
                        _buildStatColumn(
                          label: 'Duration',
                          value: widget.activity.durationString,
                          color: Colors.blue,
                        ),
                        _buildStatColumn(
                          label: 'Pace',
                          value:
                              '${widget.activity.averagePace.toStringAsFixed(2)} km/h',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Detailed Statistics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Start Time',
                      _formatDateTime(widget.activity.startTime),
                    ),
                    _buildStatRow(
                      'End Time',
                      _formatDateTime(
                        widget.activity.endTime ?? DateTime.now(),
                      ),
                    ),
                    _buildStatRow(
                      'Fastest Pace',
                      '${widget.activity.maxSpeed!.toStringAsFixed(2)} km/h',
                    ),
                    _buildStatRow(
                      'Route Points',
                      '${widget.routePoints.length}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description if available
            if (widget.activity.description != null &&
                widget.activity.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.activity.description!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
