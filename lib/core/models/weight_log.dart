class WeightLog {
  final int? id;
  final String? uuid;
  final double weightKg;
  final int loggedAt;

  const WeightLog({
    this.id,
    this.uuid,
    required this.weightKg,
    required this.loggedAt,
  });

  factory WeightLog.fromMap(Map<String, dynamic> map) => WeightLog(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        weightKg: (map['weight_kg'] as num).toDouble(),
        loggedAt: map['logged_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (uuid != null) 'uuid': uuid,
        'weight_kg': weightKg,
        'logged_at': loggedAt,
      };

  WeightLog copyWith({
    int? id,
    String? uuid,
    double? weightKg,
    int? loggedAt,
  }) => WeightLog(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        weightKg: weightKg ?? this.weightKg,
        loggedAt: loggedAt ?? this.loggedAt,
      );
}
