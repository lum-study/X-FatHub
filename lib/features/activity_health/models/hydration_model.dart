/// Model representing a single hydration entry
class HydrationEntry {
  final int? id;
  final String date; // Format: YYYY-MM-DD
  final String time; // Format: HH:mm
  final int amountMl; // Amount in milliliters
  final bool synced; // Whether synced to Supabase
  final DateTime createdAt;

  HydrationEntry({
    this.id,
    required this.date,
    required this.time,
    required this.amountMl,
    this.synced = false,
    required this.createdAt,
  });

  /// Create a copy of this entry with optional field replacements
  HydrationEntry copyWith({
    int? id,
    String? date,
    String? time,
    int? amountMl,
    bool? synced,
    DateTime? createdAt,
  }) {
    return HydrationEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      amountMl: amountMl ?? this.amountMl,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'amount_ml': amountMl,
      'synced': synced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory HydrationEntry.fromJson(Map<String, dynamic> json) {
    return HydrationEntry(
      id: json['id'] as int?,
      date: json['date'] as String,
      time: json['time'] as String,
      amountMl: json['amount'] as int? ?? json['amount_ml'] as int,
      synced: (json['synced'] as int?) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Create from database map
  factory HydrationEntry.fromDb(Map<String, dynamic> map) {
    return HydrationEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      time: map['time'] as String,
      amountMl: map['amount'] as int,
      synced: (map['synced'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() => 'HydrationEntry($date $time: ${amountMl}ml)';
}

/// Model representing the hydration tracking data
class HydrationTrackerModel {
  final int todayConsumption; // in milliliters
  final int dailyGoal; // in milliliters
  final double progress; // 0.0 to 1.0
  final List<HydrationEntry> todayEntries;
  final DateTime timestamp;

  HydrationTrackerModel({
    required this.todayConsumption,
    required this.dailyGoal,
    required this.progress,
    required this.todayEntries,
    required this.timestamp,
  });

  /// Create a copy of this model with optional field replacements
  HydrationTrackerModel copyWith({
    int? todayConsumption,
    int? dailyGoal,
    double? progress,
    List<HydrationEntry>? todayEntries,
    DateTime? timestamp,
  }) {
    return HydrationTrackerModel(
      todayConsumption: todayConsumption ?? this.todayConsumption,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      progress: progress ?? this.progress,
      todayEntries: todayEntries ?? this.todayEntries,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert consumption from ml to liters
  double get consumptionInLiters => todayConsumption / 1000;
  
  /// Convert goal from ml to liters
  double get goalInLiters => dailyGoal / 1000;

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'today_consumption': todayConsumption,
      'daily_goal': dailyGoal,
      'progress': progress,
      'today_entries': todayEntries.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory HydrationTrackerModel.fromJson(Map<String, dynamic> json) {
    return HydrationTrackerModel(
      todayConsumption: json['today_consumption'] as int,
      dailyGoal: json['daily_goal'] as int,
      progress: json['progress'] as double,
      todayEntries: (json['today_entries'] as List?)
              ?.map((e) => HydrationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() => 'HydrationTrackerModel(${consumptionInLiters.toStringAsFixed(1)}L / ${goalInLiters.toStringAsFixed(1)}L, progress: ${(progress * 100).toStringAsFixed(1)}%)';
}
