class WorkoutSet {
  final int? id;
  final int exerciseId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final int createdAt;
  final bool isWarmup;

  const WorkoutSet({
    this.id,
    required this.exerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.createdAt,
    this.isWarmup = false,
  });

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
        id: map['id'] as int?,
        exerciseId: map['exercise_id'] as int,
        setNumber: map['set_number'] as int,
        weightKg: (map['weight_kg'] as num).toDouble(),
        reps: map['reps'] as int,
        createdAt: map['created_at'] as int,
        isWarmup: (map['is_warmup'] as int? ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'created_at': createdAt,
        'is_warmup': isWarmup ? 1 : 0,
      };

  double get volume => weightKg * reps;

  WorkoutSet copyWith({int? setNumber}) => WorkoutSet(
        id: id,
        exerciseId: exerciseId,
        setNumber: setNumber ?? this.setNumber,
        weightKg: weightKg,
        reps: reps,
        createdAt: createdAt,
        isWarmup: isWarmup,
      );
}
