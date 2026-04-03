/// Model representing a single GPS location point during an activity session
class ActivityLocationPoint {
  final String id; // Unique identifier
  final String activityId; // Foreign key to activity
  final double latitude;
  final double longitude;
  final double? altitude; // Optional elevation in meters
  final double? accuracy; // GPS accuracy in meters
  final double? speed; // Speed in m/s
  final DateTime timestamp; // When this point was recorded
  final int sequenceNumber; // Order of point in the route (for re-construction)

  ActivityLocationPoint({
    required this.id,
    required this.activityId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    required this.timestamp,
    required this.sequenceNumber,
  });

  /// Create a copy with optional field replacements
  ActivityLocationPoint copyWith({
    String? id,
    String? activityId,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    double? speed,
    DateTime? timestamp,
    int? sequenceNumber,
  }) {
    return ActivityLocationPoint(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'sequence_number': sequenceNumber,
    };
  }

  /// Create from JSON
  factory ActivityLocationPoint.fromJson(Map<String, dynamic> json) {
    return ActivityLocationPoint(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sequenceNumber: json['sequence_number'] as int,
    );
  }

  @override
  String toString() =>
      'ActivityLocationPoint(lat: $latitude, lon: $longitude, $timestamp)';
}
