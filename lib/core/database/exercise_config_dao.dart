import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_config.dart';
import 'database_helper.dart';

class ExerciseConfigDao {
  final _supabase = Supabase.instance.client;

  Future<ExerciseConfig> get(String name) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'exercise_configs',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (rows.isEmpty) return ExerciseConfig(name: name);
    return ExerciseConfig.fromMap(rows.first);
  }

  Future<void> save(ExerciseConfig config) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // 1. Save to Supabase
    await _supabase.from('exercise_configs').upsert({
      'name': config.name,
      'user_id': user.id,
      'rep_min': config.repMin,
      'rep_max': config.repMax,
    });

    // 2. Save to SQLite read cache
    final db = await DatabaseHelper.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO exercise_configs (name, rep_min, rep_max) VALUES (?, ?, ?)',
      [config.name, config.repMin, config.repMax],
    );
  }
}
