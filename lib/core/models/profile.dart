class Profile {
  final String id;
  final double? height;
  final int updatedAt;

  const Profile({
    required this.id,
    this.height,
    required this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        height: (map['height'] as num?)?.toDouble(),
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'height': height,
        'updated_at': updatedAt,
      };

  Profile copyWith({
    String? id,
    double? height,
    int? updatedAt,
  }) => Profile(
        id: id ?? this.id,
        height: height ?? this.height,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
