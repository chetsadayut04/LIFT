import 'package:sqflite/sqflite.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';
import '../models/routine_set.dart';
import 'database_helper.dart';

class RoutineDao {
  Future<Routine> insertRoutine(Routine routine) async {
    final db = await DatabaseHelper.database;
    final uuid = routine.uuid ?? generateUUID();
    final toInsert = routine.copyWith(uuid: uuid);

    final id = await db.insert('routines', {
      'uuid': toInsert.uuid,
      'name': toInsert.name,
      'created_at': toInsert.createdAt,
      'is_synced': toInsert.isSynced ? 1 : 0,
    });

    return toInsert.copyWith(id: id);
  }

  Future<RoutineExercise> insertExercise(RoutineExercise ex) async {
    final db = await DatabaseHelper.database;
    final uuid = ex.uuid ?? generateUUID();
    final toInsert = ex.copyWith(uuid: uuid);

    final id = await db.insert('routine_exercises', {
      'uuid': toInsert.uuid,
      'routine_id': toInsert.routineId,
      'name': toInsert.name,
      'order_index': toInsert.orderIndex,
      'is_synced': toInsert.isSynced ? 1 : 0,
    });

    return toInsert.copyWith(id: id);
  }

  Future<RoutineSet> insertSet(RoutineSet rSet) async {
    final db = await DatabaseHelper.database;
    final uuid = rSet.uuid ?? generateUUID();
    final toInsert = rSet.copyWith(uuid: uuid);

    final id = await db.insert('routine_sets', {
      'uuid': toInsert.uuid,
      'routine_exercise_id': toInsert.routineExerciseId,
      'set_number': toInsert.setNumber,
      'weight_kg': toInsert.weightKg,
      'reps': toInsert.reps,
      'is_warmup': toInsert.isWarmup ? 1 : 0,
      'is_synced': toInsert.isSynced ? 1 : 0,
    });

    return toInsert.copyWith(id: id);
  }

  Future<List<Routine>> getRoutines() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('routines', orderBy: 'created_at DESC');
    return maps.map(Routine.fromMap).toList();
  }

  Future<List<RoutineExercise>> getExercisesForRoutine(int routineId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'order_index ASC',
    );
    return maps.map(RoutineExercise.fromMap).toList();
  }

  Future<List<RoutineSet>> getSetsForExercise(int exerciseId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'routine_sets',
      where: 'routine_exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'set_number ASC',
    );
    return maps.map(RoutineSet.fromMap).toList();
  }

  Future<void> deleteRoutine(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveFullRoutine({
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      final routineUuid = generateUUID();
      final routineId = await txn.insert('routines', {
        'uuid': routineUuid,
        'name': name,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      });

      for (int i = 0; i < exercises.length; i++) {
        final exMap = exercises[i];
        final exName = exMap['name'] as String;
        final exUuid = generateUUID();
        final exId = await txn.insert('routine_exercises', {
          'uuid': exUuid,
          'routine_id': routineId,
          'name': exName,
          'order_index': i,
          'is_synced': 0,
        });

        final sets = exMap['sets'] as List<dynamic>;
        for (int j = 0; j < sets.length; j++) {
          final setMap = sets[j] as Map<String, dynamic>;
          final setUuid = generateUUID();
          await txn.insert('routine_sets', {
            'uuid': setUuid,
            'routine_exercise_id': exId,
            'set_number': j + 1,
            'weight_kg': (setMap['weight_kg'] as num?)?.toDouble() ?? 0.0,
            'reps': setMap['reps'] as int? ?? 10,
            'is_warmup': (setMap['is_warmup'] as bool? ?? false) ? 1 : 0,
            'is_synced': 0,
          });
        }
      }
    });
  }
}
