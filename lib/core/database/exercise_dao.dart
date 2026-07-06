import '../models/exercise.dart';
import 'database_helper.dart';

class ExerciseDao {
  Future<Exercise> insert(Exercise exercise) async {
    final db = await DatabaseHelper.database;
    final id = await db.insert('exercises', exercise.toMap());
    return exercise.copyWith(id: id);
  }

  Future<List<Exercise>> getBySession(int sessionId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'exercises',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<String>> getAllNames() async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT name FROM exercises ORDER BY name ASC',
    );
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<List<String>> getRecentNames({int limit = 8}) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT e.name
      FROM exercises e
      JOIN sessions s ON e.session_id = s.id
      ORDER BY s.date DESC, e.id DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<void> updateName(int id, String name) async {
    final db = await DatabaseHelper.database;
    await db.update('exercises', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateOrderIndex(int id, int orderIndex) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'exercises',
      {'order_index': orderIndex},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByName(String name) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('exercises', columns: ['id'], where: 'name = ?', whereArgs: [name]);
    for (final m in maps) {
      final id = m['id'] as int;
      await db.delete('sets', where: 'exercise_id = ?', whereArgs: [id]);
      await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
    }
  }
}
