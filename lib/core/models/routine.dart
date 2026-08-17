class Routine {
  final int? id;
  final String? uuid;
  final bool isSynced;
  final String name;
  final int createdAt;

  const Routine({
    this.id,
    this.uuid,
    this.isSynced = false,
    required this.name,
    required this.createdAt,
  });

  factory Routine.fromMap(Map<String, dynamic> map) => Routine(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        isSynced: (map['is_synced'] as int? ?? 0) == 1,
        name: map['name'] as String,
        createdAt: map['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (uuid != null) 'uuid': uuid,
        'is_synced': isSynced ? 1 : 0,
        'name': name,
        'created_at': createdAt,
      };

  Routine copyWith({
    int? id,
    String? uuid,
    bool? isSynced,
    String? name,
    int? createdAt,
  }) => Routine(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        isSynced: isSynced ?? this.isSynced,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
}
