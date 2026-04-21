class ProfileModel {
  final String id;
  final String email;
  final String? name;
  final String? bio;
  final String? profilePictureUrl;
  final int? age;
  final double? currentWeight; // in kg
  final double? initialWeight; // in kg - starting weight for progress calculation
  final double? weightGoal; // in kg - renamed from goalWeight for consistency
  final double? height; // in cm
  final int? stepsGoal; // steps per day - renamed from stepGoal for consistency
  final double? hydrationGoal; // in liters
  final bool profileCompleted; // flag to track if user completed initial setup
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    this.name,
    this.bio,
    this.profilePictureUrl,
    this.age,
    this.currentWeight,
    this.initialWeight,
    this.weightGoal,
    this.height,
    this.stepsGoal,
    this.hydrationGoal,
    this.profileCompleted = false,
    this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      bio: map['bio'] as String?,
      profilePictureUrl: map['profile_picture_url'] as String?,
      age: map['age'] as int?,
      currentWeight: (map['current_weight'] as num?)?.toDouble(),
      initialWeight: (map['initial_weight'] as num?)?.toDouble(),
      weightGoal: (map['weight_goal'] as num?)?.toDouble() ?? (map['goal_weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      stepsGoal: map['steps_goal'] as int? ?? map['step_goal'] as int?,
      hydrationGoal: (map['hydration_goal'] as num?)?.toDouble(),
      profileCompleted: map['profile_completed'] as bool? ?? false,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'age': age,
      'current_weight': currentWeight,
      'initial_weight': initialWeight,
      'weight_goal': weightGoal,
      'height': height,
      'steps_goal': stepsGoal,
      'hydration_goal': hydrationGoal,
      'profile_completed': profileCompleted,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? profilePictureUrl,
    int? age,
    double? currentWeight,
    double? initialWeight,
    double? weightGoal,
    double? height,
    int? stepsGoal,
    double? hydrationGoal,
    bool? profileCompleted,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      age: age ?? this.age,
      currentWeight: currentWeight ?? this.currentWeight,
      initialWeight: initialWeight ?? this.initialWeight,
      weightGoal: weightGoal ?? this.weightGoal,
      height: height ?? this.height,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      hydrationGoal: hydrationGoal ?? this.hydrationGoal,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
