class GymModel {
  final String id;
  final String name;
  final String? venue;
  final String? address;
  final String status;

  const GymModel({
    required this.id,
    required this.name,
    this.venue,
    this.address,
    required this.status,
  });

  factory GymModel.fromMap(Map<String, dynamic> map) {
    return GymModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      venue: map['venue']?.toString(),
      address: map['address']?.toString(),
      status: map['status']?.toString() ?? 'active',
    );
  }
}
