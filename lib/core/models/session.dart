class Session {
  final int? id;
  final String date;
  final String? name;
  final int createdAt;
  final int? finishedAt;

  bool get isFinished => finishedAt != null;

  String get displayDate {
    final parts = date.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : date;
  }

  const Session({
    this.id,
    required this.date,
    this.name,
    required this.createdAt,
    this.finishedAt,
  });

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as int?,
        date: map['date'] as String,
        name: map['name'] as String?,
        createdAt: map['created_at'] as int,
        finishedAt: map['finished_at'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        if (name != null) 'name': name,
        'created_at': createdAt,
        if (finishedAt != null) 'finished_at': finishedAt,
      };

  Session copyWith({int? id, String? name, int? finishedAt}) => Session(
        id: id ?? this.id,
        date: date,
        name: name ?? this.name,
        createdAt: createdAt,
        finishedAt: finishedAt ?? this.finishedAt,
      );
}
