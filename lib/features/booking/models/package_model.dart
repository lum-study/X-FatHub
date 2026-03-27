class PackageModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int sessionsCount;
  final String? badge;
  final bool isFeatured;
  final String iconName;

  PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.sessionsCount,
    this.badge,
    this.isFeatured = false,
    this.iconName = 'fitness_center',
  });

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    return PackageModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      sessionsCount: int.tryParse(map['sessions_count']?.toString() ?? '0') ?? 0,
      badge: map['badge']?.toString(),
      isFeatured: map['is_featured'] == true,
      iconName: map['icon_name']?.toString() ?? 'fitness_center',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'sessions_count': sessionsCount,
      'badge': badge,
      'is_featured': isFeatured,
      'icon_name': iconName,
    };
  }
}
