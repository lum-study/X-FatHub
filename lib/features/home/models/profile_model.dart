class ProfileModel {
  final String id;
  final String email;
  final String? name;
  final String? bio;
  final String? profilePictureUrl;
  final double? weightGoal;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    this.name,
    this.bio,
    this.profilePictureUrl,
    this.weightGoal,
    this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      bio: map['bio'] as String?,
      profilePictureUrl: map['profile_picture_url'] as String?,
      weightGoal: (map['weight_goal'] as num?)?.toDouble(),
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
      'weight_goal': weightGoal,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? profilePictureUrl,
    double? weightGoal,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      weightGoal: weightGoal ?? this.weightGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
