class ProfileModel {
  final String id;
  final String email;
  final String? name;
  final String? bio;
  final String? profilePictureUrl;
  final int? age;
  final double? currentWeight; // in kg
  final double? goalWeight; // in kg
  final double? height; // in cm
  final int? stepGoal; // steps per day
  final double? hydrationGoal; // in liters
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    this.name,
    this.bio,
    this.profilePictureUrl,
    this.age,
    this.currentWeight,
    this.goalWeight,
    this.height,
    this.stepGoal,
    this.hydrationGoal,
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
      goalWeight: (map['goal_weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      stepGoal: map['step_goal'] as int?,
      hydrationGoal: (map['hydration_goal'] as num?)?.toDouble(),
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
      'goal_weight': goalWeight,
      'height': height,
      'step_goal': stepGoal,
      'hydration_goal': hydrationGoal,
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
    double? goalWeight,
    double? height,
    int? stepGoal,
    double? hydrationGoal,
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
      goalWeight: goalWeight ?? this.goalWeight,
      height: height ?? this.height,
      stepGoal: stepGoal ?? this.stepGoal,
      hydrationGoal: hydrationGoal ?? this.hydrationGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
