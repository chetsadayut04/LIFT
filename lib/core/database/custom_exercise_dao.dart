import 'database_helper.dart';

class CustomExercise {
  final int? id;
  final String uuid;
  final String name;
  final String? category;
  final DateTime createdAt;

  CustomExercise({
    this.id,
    required this.uuid,
    required this.name,
    this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'name': name,
      'category': category,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CustomExercise.fromMap(Map<String, dynamic> map) {
    return CustomExercise(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

class CustomExerciseDao {
  Future<void> insert(String name, {String? category}) async {
    final db = await DatabaseHelper.database;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final existing = await db.query(
      'custom_exercises',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmedName.toLowerCase()],
    );
    if (existing.isNotEmpty) return;

    await db.insert('custom_exercises', {
      'uuid': generateUUID(),
      'name': trimmedName,
      'category': category,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<String>> getAllNames() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'custom_exercises',
      columns: ['name'],
      orderBy: 'created_at DESC',
    );
    return maps.map((row) => row['name'] as String).toList();
  }

  Future<void> deleteByName(String name) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      'custom_exercises',
      where: 'LOWER(name) = ?',
      whereArgs: [name.trim().toLowerCase()],
    );
  }
}
