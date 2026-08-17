class RoutineSet {
  final int? id;
  final String? uuid;
  final bool isSynced;
  final int routineExerciseId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isWarmup;

  const RoutineSet({
    this.id,
    this.uuid,
    this.isSynced = false,
    required this.routineExerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.isWarmup = false,
  });

  factory RoutineSet.fromMap(Map<String, dynamic> map) => RoutineSet(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        isSynced: (map['is_synced'] as int? ?? 0) == 1,
        routineExerciseId: map['routine_exercise_id'] as int,
        setNumber: map['set_number'] as int,
        weightKg: (map['weight_kg'] as num).toDouble(),
        reps: map['reps'] as int,
        isWarmup: (map['is_warmup'] as int? ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (uuid != null) 'uuid': uuid,
        'is_synced': isSynced ? 1 : 0,
        'routine_exercise_id': routineExerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'is_warmup': isWarmup ? 1 : 0,
      };

  RoutineSet copyWith({
    int? id,
    String? uuid,
    bool? isSynced,
    int? setNumber,
    double? weightKg,
    int? reps,
    bool? isWarmup,
  }) => RoutineSet(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        isSynced: isSynced ?? this.isSynced,
        routineExerciseId: routineExerciseId,
        setNumber: setNumber ?? this.setNumber,
        weightKg: weightKg ?? this.weightKg,
        reps: reps ?? this.reps,
        isWarmup: isWarmup ?? this.isWarmup,
      );
}
