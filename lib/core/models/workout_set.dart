class WorkoutSet {
  final int? id;
  final String? uuid;
  final bool isSynced;
  final int exerciseId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final int createdAt;
  final bool isWarmup;

  const WorkoutSet({
    this.id,
    this.uuid,
    this.isSynced = false,
    required this.exerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.createdAt,
    this.isWarmup = false,
  });

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        isSynced: map['is_synced'] is bool
            ? map['is_synced'] as bool
            : (map['is_synced'] as int? ?? 0) == 1,
        exerciseId: map['exercise_id'] as int,
        setNumber: map['set_number'] as int,
        weightKg: (map['weight_kg'] as num).toDouble(),
        reps: map['reps'] as int,
        createdAt: map['created_at'] as int,
        isWarmup: map['is_warmup'] is bool
            ? map['is_warmup'] as bool
            : (map['is_warmup'] as int? ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (uuid != null) 'uuid': uuid,
        'is_synced': isSynced ? 1 : 0,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'created_at': createdAt,
        'is_warmup': isWarmup ? 1 : 0,
      };

  double get volume => weightKg * reps;

  WorkoutSet copyWith({
    int? id,
    String? uuid,
    bool? isSynced,
    int? setNumber,
  }) => WorkoutSet(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        isSynced: isSynced ?? this.isSynced,
        exerciseId: exerciseId,
        setNumber: setNumber ?? this.setNumber,
        weightKg: weightKg,
        reps: reps,
        createdAt: createdAt,
        isWarmup: isWarmup,
      );
}
