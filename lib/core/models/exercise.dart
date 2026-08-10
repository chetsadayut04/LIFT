class Exercise {
  final int? id;
  final String? uuid;
  final bool isSynced;
  final int sessionId;
  final String name;
  final int orderIndex;

  const Exercise({
    this.id,
    this.uuid,
    this.isSynced = false,
    required this.sessionId,
    required this.name,
    required this.orderIndex,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        isSynced: (map['is_synced'] as int? ?? 0) == 1,
        sessionId: map['session_id'] as int,
        name: map['name'] as String,
        orderIndex: map['order_index'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (uuid != null) 'uuid': uuid,
        'is_synced': isSynced ? 1 : 0,
        'session_id': sessionId,
        'name': name,
        'order_index': orderIndex,
      };

  Exercise copyWith({
    int? id,
    String? uuid,
    bool? isSynced,
    String? name,
  }) => Exercise(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        isSynced: isSynced ?? this.isSynced,
        sessionId: sessionId,
        name: name ?? this.name,
        orderIndex: orderIndex,
      );
}
