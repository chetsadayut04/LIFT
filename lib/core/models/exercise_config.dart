class ExerciseConfig {
  final String name;
  final int repMin;
  final int repMax;

  const ExerciseConfig({
    required this.name,
    this.repMin = 8,
    this.repMax = 12,
  });

  factory ExerciseConfig.fromMap(Map<String, dynamic> map) => ExerciseConfig(
        name: map['name'] as String,
        repMin: (map['rep_min'] as int?) ?? 8,
        repMax: (map['rep_max'] as int?) ?? 12,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'rep_min': repMin,
        'rep_max': repMax,
      };
}
