import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import 'database_helper.dart';

class ExerciseDao {
  final _supabase = Supabase.instance.client;

  Future<Exercise> insert(Exercise exercise) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final response = await _supabase.from('exercises').insert({
      'user_id': user.id,
      'session_id': exercise.sessionId,
      'name': exercise.name,
      'order_index': exercise.orderIndex,
    }).select().single();

    final inserted = Exercise.fromMap(response);

    // Save to SQLite read cache
    final db = await DatabaseHelper.database;
    await db.insert('exercises', {
      'id': inserted.id,
      'session_id': inserted.sessionId,
      'name': inserted.name,
      'order_index': inserted.orderIndex,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return inserted;
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
    // 1. Update on Supabase
    await _supabase.from('exercises').update({'name': name}).eq('id', id);

    // 2. Update SQLite Read Cache
    final db = await DatabaseHelper.database;
    await db.update(
      'exercises',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateOrderIndex(int id, int orderIndex) async {
    // 1. Update on Supabase
    await _supabase.from('exercises').update({'order_index': orderIndex}).eq('id', id);

    // 2. Update SQLite Read Cache
    final db = await DatabaseHelper.database;
    await db.update(
      'exercises',
      {'order_index': orderIndex},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    // 1. Delete from Supabase
    await _supabase.from('exercises').delete().eq('id', id);

    // 2. Delete from SQLite
    final db = await DatabaseHelper.database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByName(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Delete from Supabase
    await _supabase.from('exercises').delete().eq('user_id', user.id).eq('name', name);

    // 2. Delete from SQLite (need to delete sets and exercises)
    final db = await DatabaseHelper.database;
    final maps = await db.query('exercises', columns: ['id'], where: 'name = ?', whereArgs: [name]);
    for (final m in maps) {
      final id = m['id'] as int;
      await db.delete('sets', where: 'exercise_id = ?', whereArgs: [id]);
      await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
    }
  }
}
