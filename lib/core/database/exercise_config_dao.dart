import '../models/exercise_config.dart';
import 'database_helper.dart';

class ExerciseConfigDao {
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
    final db = await DatabaseHelper.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO exercise_configs (name, rep_min, rep_max) VALUES (?, ?, ?)',
      [config.name, config.repMin, config.repMax],
    );
  }
}
