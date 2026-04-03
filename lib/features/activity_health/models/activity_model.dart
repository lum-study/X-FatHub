import 'activity_location_point.dart';

/// Enum for activity status
enum ActivityStatus { notStarted, active, paused, completed, discarded }

/// Model representing a complete activity session (workout/walk/run)
class ActivityModel {
  final String id; // Unique identifier (UUID)
  final String userId; // User who performed the activity
  final String activityType; // 'walk', 'run', 'hike', etc.
  final String? title; // Custom title for the activity
  final String? description; // Optional notes

  // Timing
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? totalDuration; // Total elapsed time (excluding pauses)

  // Location & Route Data
  final double distanceTraveled; // in kilometers
  final List<ActivityLocationPoint> routePoints; // GPS coordinates of the route
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;

  // Activity Metrics
  final int stepCount; // Total steps during activity
  final double caloriesBurned; // Estimated calories (kcal)
  final double averagePace; // km/h
  final double? maxSpeed; // km/h
  final double? elevationGain; // meters (if altitude data available)

  // Status & Sync
  final ActivityStatus status;
  final bool isSyncedToServer; // Whether saved to Supabase
  final DateTime createdAt;
  final DateTime? updatedAt;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.activityType,
    this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.totalDuration,
    this.distanceTraveled = 0.0,
    this.routePoints = const [],
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.stepCount = 0,
    this.caloriesBurned = 0.0,
    this.averagePace = 0.0,
    this.maxSpeed,
    this.elevationGain,
    this.status = ActivityStatus.notStarted,
    this.isSyncedToServer = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a copy with optional field replacements
  ActivityModel copyWith({
    String? id,
    String? userId,
    String? activityType,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    Duration? totalDuration,
    double? distanceTraveled,
    List<ActivityLocationPoint>? routePoints,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    int? stepCount,
    double? caloriesBurned,
    double? averagePace,
    double? maxSpeed,
    double? elevationGain,
    ActivityStatus? status,
    bool? isSyncedToServer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDuration: totalDuration ?? this.totalDuration,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      routePoints: routePoints ?? this.routePoints,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      stepCount: stepCount ?? this.stepCount,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      averagePace: averagePace ?? this.averagePace,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      elevationGain: elevationGain ?? this.elevationGain,
      status: status ?? this.status,
      isSyncedToServer: isSyncedToServer ?? this.isSyncedToServer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if activity is currently active
  bool get isActive => status == ActivityStatus.active;

  /// Check if activity is completed
  bool get isCompleted => status == ActivityStatus.completed;

  /// Get formatted duration string
  String get durationString {
    // Use totalDuration if available
    Duration? duration = totalDuration;
    
    // If totalDuration is null but endTime exists, calculate from timestamps
    if (duration == null && endTime != null) {
      duration = endTime!.difference(startTime);
    }
    
    // If still no duration, return placeholder
    if (duration == null) return '--:--:--';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity_type': activityType,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_duration_seconds': totalDuration?.inSeconds,
      'distance_traveled': distanceTraveled,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'step_count': stepCount,
      'calories_burned': caloriesBurned,
      'average_pace': averagePace,
      'max_speed': maxSpeed,
      'elevation_gain': elevationGain,
      'status': status.name,
      'is_synced_to_server': isSyncedToServer,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityType: json['activity_type'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      totalDuration: json['total_duration_seconds'] != null
          ? Duration(seconds: json['total_duration_seconds'] as int)
          : null,
      distanceTraveled: (json['distance_traveled'] as num?)?.toDouble() ?? 0.0,
      startLatitude: (json['start_latitude'] as num?)?.toDouble(),
      startLongitude: (json['start_longitude'] as num?)?.toDouble(),
      endLatitude: (json['end_latitude'] as num?)?.toDouble(),
      endLongitude: (json['end_longitude'] as num?)?.toDouble(),
      stepCount: json['step_count'] as int? ?? 0,
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble() ?? 0.0,
      averagePace: (json['average_pace'] as num?)?.toDouble() ?? 0.0,
      maxSpeed: (json['max_speed'] as num?)?.toDouble(),
      elevationGain: (json['elevation_gain'] as num?)?.toDouble(),
      status: ActivityStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => ActivityStatus.notStarted,
      ),
      isSyncedToServer: (json['is_synced_to_server'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'ActivityModel(id: $id, type: $activityType, distance: ${distanceTraveled}km, status: $status)';
}
