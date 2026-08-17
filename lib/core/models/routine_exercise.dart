class RoutineExercise {
  final int? id;
  final String? uuid;
  final bool isSynced;
  final int routineId;
  final String name;
  final int orderIndex;

  const RoutineExercise({
    this.id,
    this.uuid,
    this.isSynced = false,
    required this.routineId,
    required this.name,
    required this.orderIndex,
  });

  factory RoutineExercise.fromMap(Map<String, dynamic> map) => RoutineExercise(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        isSynced: (map['is_synced'] as int? ?? 0) == 1,
        routineId: map['routine_id'] as int,
        name: map['name'] as String,
        orderIndex: map['order_index'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (uuid != null) 'uuid': uuid,
        'is_synced': isSynced ? 1 : 0,
        'routine_id': routineId,
        'name': name,
        'order_index': orderIndex,
      };

  RoutineExercise copyWith({
    int? id,
    String? uuid,
    bool? isSynced,
    String? name,
    int? orderIndex,
  }) => RoutineExercise(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        isSynced: isSynced ?? this.isSynced,
        routineId: routineId,
        name: name ?? this.name,
        orderIndex: orderIndex ?? this.orderIndex,
      );
}
