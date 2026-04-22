class PackageModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int sessionsCount;
  final String? badge;
  final bool isFeatured;
  final String iconName;
  final List<String> allowedClassNames;
  final List<String> benefits;
  final List<String> rules;
  final List<String> gymNames;

  PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.sessionsCount,
    this.badge,
    this.isFeatured = false,
    this.iconName = 'fitness_center',
    this.allowedClassNames = const [],
    this.benefits = const [],
    this.rules = const [],
    this.gymNames = const [],
  });

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    return PackageModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      sessionsCount:
          int.tryParse(map['sessions_count']?.toString() ?? '0') ?? 0,
      badge: map['badge']?.toString(),
      isFeatured: map['is_featured'] == true,
      iconName: map['icon_name']?.toString() ?? 'fitness_center',
      allowedClassNames: _parseAllowedClassNames(map['allowed_class_names']),
      benefits: _parseStringList(map['benefits']),
      rules: _parseStringList(map['rules']),
      gymNames: _parseStringList(map['gym_names']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.isNotEmpty) {
      final cleaned = value.replaceAll('{', '').replaceAll('}', '');
      return cleaned
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static List<String> _parseAllowedClassNames(dynamic value) {
    return _parseStringList(value);
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
      'allowed_class_names': allowedClassNames,
      'benefits': benefits,
      'rules': rules,
      'gym_names': gymNames,
    };
  }
}
