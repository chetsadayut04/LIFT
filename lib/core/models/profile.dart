class Profile {
  final String id;
  final double? height;
  final String? fitnessGoal;
  final int updatedAt;

  const Profile({
    required this.id,
    this.height,
    this.fitnessGoal,
    required this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        height: (map['height'] as num?)?.toDouble(),
        fitnessGoal: map['fitness_goal'] as String?,
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'height': height,
        'fitness_goal': fitnessGoal,
        'updated_at': updatedAt,
      };

  Profile copyWith({
    String? id,
    double? height,
    String? fitnessGoal,
    int? updatedAt,
  }) => Profile(
        id: id ?? this.id,
        height: height ?? this.height,
        fitnessGoal: fitnessGoal ?? this.fitnessGoal,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
