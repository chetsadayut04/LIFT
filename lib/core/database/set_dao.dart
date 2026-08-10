import '../models/workout_set.dart';
import 'database_helper.dart';

class SetDao {
  Future<WorkoutSet> insert(WorkoutSet set) async {
    final db = await DatabaseHelper.database;
    final id = await db.insert('sets', set.toMap());
    return WorkoutSet(
      id: id,
      exerciseId: set.exerciseId,
      setNumber: set.setNumber,
      weightKg: set.weightKg,
      reps: set.reps,
      createdAt: set.createdAt,
      isWarmup: set.isWarmup,
    );
  }

  Future<List<WorkoutSet>> getByExercise(int exerciseId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'sets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'set_number ASC',
    );
    return maps.map(WorkoutSet.fromMap).toList();
  }

  Future<List<WorkoutSet>> getByExerciseName(String name, String fromDate, String toDate) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE e.name = ? AND ss.date >= ? AND ss.date <= ? AND s.is_warmup = 0
    ''', [name, fromDate, toDate]);
    return maps.map(WorkoutSet.fromMap).toList();
  }

  Future<double> getTotalVolumeByDateRange(String fromDate, String toDate) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(s.weight_kg * s.reps) as total FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE ss.date >= ? AND ss.date <= ? AND s.is_warmup = 0
    ''', [fromDate, toDate]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Returns a per-exercise summary for a single date.
  Future<List<({String name, int setCount, double avgWeight, double totalVolume, double bestE1rm, bool hasPrToday})>>
      getExerciseSummaryByDate(String date) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT e.name,
             COUNT(s.id)                                              AS set_count,
             AVG(s.weight_kg)                                         AS avg_weight,
             SUM(s.weight_kg * s.reps)                                AS total_volume,
             MAX(s.weight_kg * (1.0 + CAST(s.reps AS REAL) / 30.0))  AS best_e1rm,
             MAX(s.weight_kg)                                          AS max_weight_today,
             (SELECT MAX(s2.weight_kg) FROM sets s2
              JOIN exercises e2 ON s2.exercise_id = e2.id
              JOIN sessions ss2 ON e2.session_id = ss2.id
              WHERE e2.name = e.name AND s2.is_warmup = 0 AND ss2.date < ?)  AS prev_pr
      FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE ss.date = ? AND s.is_warmup = 0
      GROUP BY e.name
      ORDER BY e.order_index ASC
    ''', [date, date]);
    return rows.map((r) {
      final maxToday = (r['max_weight_today'] as num?)?.toDouble() ?? 0.0;
      final prevPr = (r['prev_pr'] as num?)?.toDouble();
      return (
        name: r['name'] as String,
        setCount: (r['set_count'] as int?) ?? 0,
        avgWeight: (r['avg_weight'] as num?)?.toDouble() ?? 0.0,
        totalVolume: (r['total_volume'] as num?)?.toDouble() ?? 0.0,
        bestE1rm: (r['best_e1rm'] as num?)?.toDouble() ?? 0.0,
        hasPrToday: prevPr == null ? true : maxToday > prevPr,
      );
    }).toList();
  }

  Future<double> getLastSessionVolumeBeforeDate(String date) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(s.weight_kg * s.reps) AS vol
      FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE ss.date = (
        SELECT MAX(ss2.date) FROM sessions ss2 WHERE ss2.date < ?
      ) AND s.is_warmup = 0
    ''', [date]);
    return (result.first['vol'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getVolumePerExerciseByDateRange(
      String fromDate, String toDate) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT e.name, SUM(s.weight_kg * s.reps) as vol FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE ss.date >= ? AND ss.date <= ? AND s.is_warmup = 0
      GROUP BY e.name
    ''', [fromDate, toDate]);
    return {for (final m in maps) m['name'] as String: (m['vol'] as num).toDouble()};
  }

  Future<Map<String, double>> getVolumePerDay(String fromDate, String toDate) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT ss.date, SUM(s.weight_kg * s.reps) as vol
      FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE ss.date >= ? AND ss.date <= ? AND s.is_warmup = 0
      GROUP BY ss.date
    ''', [fromDate, toDate]);
    return {for (final r in rows) r['date'] as String: (r['vol'] as num).toDouble()};
  }

  Future<Map<String, double>> getVolumePerDayForExercise(
      String name, String fromDate, String toDate) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT ss.date, SUM(s.weight_kg * s.reps) as vol
      FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE e.name = ? AND ss.date >= ? AND ss.date <= ? AND s.is_warmup = 0
      GROUP BY ss.date
      ORDER BY ss.date ASC
    ''', [name, fromDate, toDate]);
    return {for (final r in rows) r['date'] as String: (r['vol'] as num).toDouble()};
  }

  /// Sets (non-warmup) from the most recent session before [beforeDate] that had [exerciseName].
  Future<List<({double weight, int reps})>> getLastSessionSetsForExercise(
      String exerciseName, String beforeDate) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT s.weight_kg, s.reps FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE e.name = ? AND s.is_warmup = 0
        AND ss.date = (
          SELECT MAX(ss2.date) FROM sessions ss2
          JOIN exercises e2 ON e2.session_id = ss2.id
          WHERE e2.name = ? AND ss2.date < ?
        )
      ORDER BY s.set_number ASC
    ''', [exerciseName, exerciseName, beforeDate]);
    return rows
        .map((r) => (weight: (r['weight_kg'] as num).toDouble(), reps: r['reps'] as int))
        .toList();
  }

  /// All-time max working weight for [exerciseName] across all sessions.
  Future<double?> getPrWeightForExercise(String exerciseName) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT MAX(s.weight_kg) as pr FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      WHERE e.name = ? AND s.is_warmup = 0
    ''', [exerciseName]);
    return (result.first['pr'] as num?)?.toDouble();
  }

  /// Max working weight per day for [name] within the date range (for progression chart).
  Future<Map<String, double>> getMaxWeightPerDayForExercise(
      String name, String fromDate, String toDate) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT ss.date, MAX(s.weight_kg) as max_weight
      FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE e.name = ? AND ss.date >= ? AND ss.date <= ? AND s.is_warmup = 0
      GROUP BY ss.date
      ORDER BY ss.date ASC
    ''', [name, fromDate, toDate]);
    return {for (final r in rows) r['date'] as String: (r['max_weight'] as num).toDouble()};
  }

  Future<DateTime?> getLatestDateForExercise(String name) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT MAX(ss.date) as last_date FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE e.name = ?
    ''', [name]);
    final raw = result.first['last_date'] as String?;
    if (raw == null) return null;
    return DateTime.parse(raw);
  }

  Future<List<({String name, double prKg, int prReps, int totalSets})>> getAllExercisePrs() async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      WITH ranked_sets AS (
        SELECT e.name,
               s.weight_kg,
               s.reps,
               s.weight_kg * (1.0 + CAST(s.reps AS REAL) / 30.0) AS e1rm,
               ROW_NUMBER() OVER (PARTITION BY e.name ORDER BY s.weight_kg * (1.0 + CAST(s.reps AS REAL) / 30.0) DESC) as rn,
               COUNT(s.id) OVER (PARTITION BY e.name) as total_sets
        FROM sets s
        JOIN exercises e ON s.exercise_id = e.id
        WHERE s.is_warmup = 0
      )
      SELECT name,
             weight_kg AS pr_kg,
             reps      AS pr_reps,
             total_sets,
             e1rm
      FROM ranked_sets
      WHERE rn = 1
      ORDER BY e1rm DESC
    ''');
    return rows
        .where((r) => r['pr_kg'] != null)
        .map((r) => (
              name: r['name'] as String,
              prKg: (r['pr_kg'] as num).toDouble(),
              prReps: (r['pr_reps'] as int?) ?? 1,
              totalSets: (r['total_sets'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<List<({String name, double prKg, int prReps, int totalSets})>> getExerciseStatsBySessionName(
      String sessionName) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      WITH ranked_sets AS (
        SELECT e.name,
               s.weight_kg,
               s.reps,
               s.weight_kg * (1.0 + CAST(s.reps AS REAL) / 30.0) AS e1rm,
               ROW_NUMBER() OVER (PARTITION BY e.name ORDER BY s.weight_kg * (1.0 + CAST(s.reps AS REAL) / 30.0) DESC) as rn,
               COUNT(s.id) OVER (PARTITION BY e.name) as total_sets
        FROM sets s
        JOIN exercises e ON s.exercise_id = e.id
        JOIN sessions ss ON e.session_id = ss.id
        WHERE s.is_warmup = 0
          AND ss.name = ?
      )
      SELECT name,
             weight_kg AS pr_kg,
             reps      AS pr_reps,
             total_sets,
             e1rm
      FROM ranked_sets
      WHERE rn = 1
      ORDER BY e1rm DESC
    ''', [sessionName]);
    return rows
        .where((r) => r['pr_kg'] != null)
        .map((r) => (
              name: r['name'] as String,
              prKg: (r['pr_kg'] as num).toDouble(),
              prReps: (r['pr_reps'] as int?) ?? 1,
              totalSets: (r['total_sets'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<List<({String name, double prKg, int prReps, int totalSets})>> getAllExercisePrsInRange(
      String from, String to) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      WITH ranked_sets AS (
        SELECT e.name,
               s.weight_kg,
               s.reps,
               s.weight_kg * (1.0 + CAST(s.reps AS REAL) / 30.0) AS e1rm,
               ROW_NUMBER() OVER (PARTITION BY e.name ORDER BY s.weight_kg * (1.0 + CAST(s.reps AS REAL) / 30.0) DESC) as rn,
               COUNT(s.id) OVER (PARTITION BY e.name) as total_sets
        FROM sets s
        JOIN exercises e ON s.exercise_id = e.id
        JOIN sessions ss ON e.session_id = ss.id
        WHERE s.is_warmup = 0
          AND ss.date >= ? AND ss.date <= ?
      )
      SELECT name,
             weight_kg AS pr_kg,
             reps      AS pr_reps,
             total_sets,
             e1rm
      FROM ranked_sets
      WHERE rn = 1
      ORDER BY e1rm DESC
    ''', [from, to]);
    return rows
        .where((r) => r['pr_kg'] != null)
        .map((r) => (
              name: r['name'] as String,
              prKg: (r['pr_kg'] as num).toDouble(),
              prReps: (r['pr_reps'] as int?) ?? 1,
              totalSets: (r['total_sets'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<int> getTotalSetsByDateRange(String fromDate, String toDate) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(s.id) as cnt FROM sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN sessions ss ON e.session_id = ss.id
      WHERE ss.date >= ? AND ss.date <= ? AND s.is_warmup = 0
    ''', [fromDate, toDate]);
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> renumberSets(int exerciseId) async {
    final db = await DatabaseHelper.database;
    final sets = await db.query('sets',
        where: 'exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'set_number ASC');
    for (var i = 0; i < sets.length; i++) {
      await db.update('sets', {'set_number': i + 1},
          where: 'id = ?', whereArgs: [sets[i]['id']]);
    }
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('sets', where: 'id = ?', whereArgs: [id]);
  }
}
