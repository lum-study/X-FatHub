class SlotModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String className;
  final String coachName;
  final String location;
  final int totalSpots;
  final int occupiedSpots;

  SlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.className,
    required this.coachName,
    required this.location,
    required this.totalSpots,
    this.occupiedSpots = 0,
  });

  bool get isFull => occupiedSpots >= totalSpots;
  bool get isLow => (totalSpots - occupiedSpots) <= 3 && !isFull;
  int get spotsLeft => totalSpots - occupiedSpots;

  factory SlotModel.fromMap(Map<String, dynamic> map) {
    return SlotModel(
      id: map['id']?.toString() ?? '',
      startTime: DateTime.tryParse(map['start_time']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(map['end_time']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
      className: map['class_name']?.toString() ?? '',
      coachName: map['coach_name']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      totalSpots: int.tryParse(map['total_spots']?.toString() ?? '20') ?? 20,
      occupiedSpots: int.tryParse(map['occupied_spots']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'class_name': className,
      'coach_name': coachName,
      'location': location,
      'total_spots': totalSpots,
      'occupied_spots': occupiedSpots,
    };
  }
}
