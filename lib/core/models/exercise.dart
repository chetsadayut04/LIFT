class Exercise {
  final int? id;
  final int sessionId;
  final String name;
  final int orderIndex;

  const Exercise({
    this.id,
    required this.sessionId,
    required this.name,
    required this.orderIndex,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as int?,
        sessionId: map['session_id'] as int,
        name: map['name'] as String,
        orderIndex: map['order_index'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'name': name,
        'order_index': orderIndex,
      };

  Exercise copyWith({int? id, String? name}) => Exercise(
        id: id ?? this.id,
        sessionId: sessionId,
        name: name ?? this.name,
        orderIndex: orderIndex,
      );
}
