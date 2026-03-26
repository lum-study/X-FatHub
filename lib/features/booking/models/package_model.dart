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
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      sessionsCount: map['sessions_count'] ?? 0,
      badge: map['badge'],
      isFeatured: map['is_featured'] ?? false,
      iconName: map['icon_name'] ?? 'fitness_center',
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
