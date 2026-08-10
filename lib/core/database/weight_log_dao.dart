import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weight_log.dart';
import 'database_helper.dart';

class WeightLogDao {
  final _supabase = Supabase.instance.client;

  Future<WeightLog> insert(double weightKg, int loggedAt) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final response = await _supabase.from('weight_logs').insert({
      'user_id': user.id,
      'weight_kg': weightKg,
      'logged_at': loggedAt,
    }).select().single();

    final inserted = WeightLog.fromMap(response);

    // Save to SQLite read cache
    final db = await DatabaseHelper.database;
    await db.insert(
      'weight_logs',
      {
        'id': inserted.id,
        'uuid': inserted.uuid,
        'weight_kg': inserted.weightKg,
        'logged_at': inserted.loggedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return inserted;
  }

  Future<void> delete(int id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // Delete remote
    await _supabase.from('weight_logs').delete().eq('id', id);

    // Delete local cache
    final db = await DatabaseHelper.database;
    await db.delete(
      'weight_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<WeightLog>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'weight_logs',
      orderBy: 'logged_at DESC',
    );
    return maps.map(WeightLog.fromMap).toList();
  }
}
