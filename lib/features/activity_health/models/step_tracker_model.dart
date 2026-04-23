/// Model representing the step tracking data
class StepTrackerModel {
  final int steps;
  final int goalSteps;
  final double distance; // in kilometers
  final double progress; // 0.0 to 1.0
  final double kcal; // calculated as: distance(km) × bodyWeight(kg) × 0.75
  final DateTime timestamp;
  final List<int> dailySteps; // Last 7 days of step counts (Monday to Sunday)
  final List<String> dayLabels; // ['M', 'T', 'W', 'T', 'F', 'S', 'S']

  StepTrackerModel({
    required this.steps,
    required this.goalSteps,
    required this.distance,
    required this.progress,
    required this.kcal,
    required this.timestamp,
    this.dailySteps = const [0, 0, 0, 0, 0, 0, 0],
    this.dayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  });

  /// Create a copy of this model with optional field replacements
  StepTrackerModel copyWith({
    int? steps,
    int? goalSteps,
    double? distance,
    double? progress,
    double? kcal,
    DateTime? timestamp,
    List<int>? dailySteps,
    List<String>? dayLabels,
  }) {
    return StepTrackerModel(
      steps: steps ?? this.steps,
      goalSteps: goalSteps ?? this.goalSteps,
      distance: distance ?? this.distance,
      progress: progress ?? this.progress,
      kcal: kcal ?? this.kcal,
      timestamp: timestamp ?? this.timestamp,
      dailySteps: dailySteps ?? this.dailySteps,
      dayLabels: dayLabels ?? this.dayLabels,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'goalSteps': goalSteps,
      'distance': distance,
      'progress': progress,
      'kcal': kcal,
      'timestamp': timestamp.toIso8601String(),
      'dailySteps': dailySteps,
      'dayLabels': dayLabels,
    };
  }

  /// Create from JSON
  factory StepTrackerModel.fromJson(Map<String, dynamic> json) {
    return StepTrackerModel(
      steps: json['steps'] as int? ?? 0,
      goalSteps: json['goalSteps'] as int? ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      dailySteps: json['dailySteps'] != null
          ? List<int>.from(json['dailySteps'] as List)
          : [0, 0, 0, 0, 0, 0, 0],
      dayLabels: json['dayLabels'] != null
          ? List<String>.from(json['dayLabels'] as List)
          : ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    );
  }

  @override
  String toString() =>
      'StepTrackerModel(steps: $steps, goalSteps: $goalSteps, distance: $distance, progress: $progress, kcal: $kcal, dailySteps: $dailySteps)';
}
