import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';
import '../models/routine_set.dart';
import 'database_helper.dart';

class RoutineDao {
  final _supabase = Supabase.instance.client;
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
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('routines').delete().eq('id', id);
      } catch (_) {}
    }
    final db = await DatabaseHelper.database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveFullRoutine({
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final user = _supabase.auth.currentUser;
    final routineUuid = generateUUID();
    final createdAt = DateTime.now().millisecondsSinceEpoch;

    if (user != null) {
      try {
        final pushed = await _pushNewRoutineToSupabase(
          userId: user.id,
          routineUuid: routineUuid,
          name: name,
          createdAt: createdAt,
          exercises: exercises,
        );
        await _saveCloudRoutineLocally(pushed);
        return;
      } catch (_) {
        // Fall back to local unsynced save if offline or remote error
      }
    }

    await _saveLocalUnsyncedRoutine(
      routineUuid: routineUuid,
      name: name,
      createdAt: createdAt,
      exercises: exercises,
    );
  }

  Future<void> updateFullRoutine({
    required int routineId,
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final db = await DatabaseHelper.database;
    final user = _supabase.auth.currentUser;

    final existingRows = await db.query(
      'routines',
      where: 'id = ?',
      whereArgs: [routineId],
      limit: 1,
    );
    final existingUuid = existingRows.isNotEmpty
        ? (existingRows.first['uuid'] as String?) ?? generateUUID()
        : generateUUID();
    final existingCreatedAt = existingRows.isNotEmpty
        ? (existingRows.first['created_at'] as int? ??
            DateTime.now().millisecondsSinceEpoch)
        : DateTime.now().millisecondsSinceEpoch;
    final wasSynced = existingRows.isNotEmpty &&
        (existingRows.first['is_synced'] as int? ?? 0) == 1;

    if (user != null) {
      try {
        if (wasSynced) {
          await _supabase
              .from('routines')
              .update({'name': name, 'is_synced': 1})
              .eq('id', routineId);
          await _supabase
              .from('routine_exercises')
              .delete()
              .eq('routine_id', routineId);
          final pushedExercises = await _pushExercisesToSupabase(
            userId: user.id,
            routineId: routineId,
            exercises: exercises,
          );
          await db.transaction((txn) async {
            await txn.update(
              'routines',
              {'name': name, 'uuid': existingUuid, 'is_synced': 1},
              where: 'id = ?',
              whereArgs: [routineId],
            );
            await _replaceLocalExercisesAndSets(
              txn,
              routineId: routineId,
              exercises: pushedExercises,
              isSynced: 1,
            );
          });
          return;
        } else {
          final pushed = await _pushNewRoutineToSupabase(
            userId: user.id,
            routineUuid: existingUuid,
            name: name,
            createdAt: existingCreatedAt,
            exercises: exercises,
          );
          await db.delete('routines', where: 'id = ?', whereArgs: [routineId]);
          await _saveCloudRoutineLocally(pushed);
          return;
        }
      } catch (_) {
        // Fall back to local unsynced update if offline or remote error
      }
    }

    await db.transaction((txn) async {
      await txn.update(
        'routines',
        {'name': name, 'is_synced': 0},
        where: 'id = ?',
        whereArgs: [routineId],
      );
      await _replaceLocalExercisesAndSets(
        txn,
        routineId: routineId,
        exercises: exercises,
        isSynced: 0,
      );
    });
  }

  /// Uploads any local routines with `is_synced = 0` to Supabase before cache refresh.
  Future<void> syncUnsyncedRoutines() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final db = await DatabaseHelper.database;
    final unsynced = await db.query(
      'routines',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );
    if (unsynced.isEmpty) return;

    for (final r in unsynced) {
      final localId = r['id'] as int;
      final uuid = (r['uuid'] as String?) ?? generateUUID();
      final name = r['name'] as String;
      final createdAt = r['created_at'] as int;

      final exRows = await db.query(
        'routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [localId],
        orderBy: 'order_index ASC',
      );
      final exercises = <Map<String, dynamic>>[];
      for (final ex in exRows) {
        final setRows = await db.query(
          'routine_sets',
          where: 'routine_exercise_id = ?',
          whereArgs: [ex['id']],
          orderBy: 'set_number ASC',
        );
        exercises.add({
          'name': ex['name'] as String,
          'sets': setRows
              .map((s) => {
                    'weight_kg': (s['weight_kg'] as num?)?.toDouble() ?? 0.0,
                    'reps': s['reps'] as int? ?? 10,
                    'is_warmup': (s['is_warmup'] as int? ?? 0) == 1,
                  })
              .toList(),
        });
      }

      try {
        await _pushNewRoutineToSupabase(
          userId: user.id,
          routineUuid: uuid,
          name: name,
          createdAt: createdAt,
          exercises: exercises,
        );
        await db.delete('routines', where: 'id = ?', whereArgs: [localId]);
      } catch (_) {
        // Ignore individual failure; next sync will retry
      }
    }
  }

  Future<Map<String, dynamic>> _pushNewRoutineToSupabase({
    required String userId,
    required String routineUuid,
    required String name,
    required int createdAt,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final routineRes = await _supabase
        .from('routines')
        .upsert(
          {
            'uuid': routineUuid,
            'user_id': userId,
            'name': name,
            'created_at': createdAt,
            'is_synced': 1,
          },
          onConflict: 'uuid',
        )
        .select()
        .single();

    final remoteRoutineId = routineRes['id'] as int;
    // Clear any partial exercises if this was a retry on same uuid
    await _supabase
        .from('routine_exercises')
        .delete()
        .eq('routine_id', remoteRoutineId);

    final pushedExercises = await _pushExercisesToSupabase(
      userId: userId,
      routineId: remoteRoutineId,
      exercises: exercises,
    );

    return {
      'id': remoteRoutineId,
      'uuid': routineRes['uuid'] as String? ?? routineUuid,
      'name': name,
      'created_at': createdAt,
      'exercises': pushedExercises,
    };
  }

  Future<List<Map<String, dynamic>>> _pushExercisesToSupabase({
    required String userId,
    required int routineId,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final pushedExercises = <Map<String, dynamic>>[];
    for (int i = 0; i < exercises.length; i++) {
      final exMap = exercises[i];
      final exName = exMap['name'] as String;
      final exUuid = generateUUID();

      final exRes = await _supabase
          .from('routine_exercises')
          .insert({
            'uuid': exUuid,
            'user_id': userId,
            'routine_id': routineId,
            'name': exName,
            'order_index': i,
            'is_synced': 1,
          })
          .select()
          .single();

      final remoteExId = exRes['id'] as int;
      final sets = exMap['sets'] as List<dynamic>;
      final pushedSets = <Map<String, dynamic>>[];

      if (sets.isNotEmpty) {
        final payload = <Map<String, dynamic>>[];
        for (int j = 0; j < sets.length; j++) {
          final setMap = sets[j] as Map<String, dynamic>;
          payload.add({
            'uuid': generateUUID(),
            'user_id': userId,
            'routine_exercise_id': remoteExId,
            'set_number': j + 1,
            'weight_kg': (setMap['weight_kg'] as num?)?.toDouble() ?? 0.0,
            'reps': setMap['reps'] as int? ?? 10,
            'is_warmup': setMap['is_warmup'] as bool? ?? false,
            'is_synced': 1,
          });
        }
        final setRes =
            await _supabase.from('routine_sets').insert(payload).select();
        for (final row in setRes) {
          pushedSets.add(Map<String, dynamic>.from(row));
        }
      }

      pushedExercises.add({
        'id': remoteExId,
        'uuid': exRes['uuid'] as String? ?? exUuid,
        'name': exName,
        'order_index': i,
        'sets': pushedSets,
      });
    }
    return pushedExercises;
  }

  Future<void> _saveCloudRoutineLocally(Map<String, dynamic> pushed) async {
    final db = await DatabaseHelper.database;
    final routineId = pushed['id'] as int;
    await db.transaction((txn) async {
      await txn.insert(
        'routines',
        {
          'id': routineId,
          'uuid': pushed['uuid'],
          'name': pushed['name'],
          'created_at': pushed['created_at'],
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _replaceLocalExercisesAndSets(
        txn,
        routineId: routineId,
        exercises: pushed['exercises'] as List<Map<String, dynamic>>,
        isSynced: 1,
      );
    });
  }

  Future<void> _saveLocalUnsyncedRoutine({
    required String routineUuid,
    required String name,
    required int createdAt,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      final routineId = await txn.insert('routines', {
        'uuid': routineUuid,
        'name': name,
        'created_at': createdAt,
        'is_synced': 0,
      });
      await _replaceLocalExercisesAndSets(
        txn,
        routineId: routineId,
        exercises: exercises,
        isSynced: 0,
      );
    });
  }

  Future<void> _replaceLocalExercisesAndSets(
    Transaction txn, {
    required int routineId,
    required List<Map<String, dynamic>> exercises,
    required int isSynced,
  }) async {
    final oldExs = await txn.query(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
    for (final ex in oldExs) {
      await txn.delete(
        'routine_sets',
        where: 'routine_exercise_id = ?',
        whereArgs: [ex['id']],
      );
    }
    await txn.delete(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );

    for (int i = 0; i < exercises.length; i++) {
      final exMap = exercises[i];
      final exId = await txn.insert(
        'routine_exercises',
        {
          if (exMap['id'] != null) 'id': exMap['id'],
          'uuid': (exMap['uuid'] as String?) ?? generateUUID(),
          'routine_id': routineId,
          'name': exMap['name'] as String,
          'order_index': i,
          'is_synced': isSynced,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final sets = exMap['sets'] as List<dynamic>;
      for (int j = 0; j < sets.length; j++) {
        final setMap = sets[j] as Map<String, dynamic>;
        final rawWarmup = setMap['is_warmup'];
        final isWarmupInt = rawWarmup is bool
            ? (rawWarmup ? 1 : 0)
            : (rawWarmup as int? ?? 0);
        await txn.insert(
          'routine_sets',
          {
            if (setMap['id'] != null) 'id': setMap['id'],
            'uuid': (setMap['uuid'] as String?) ?? generateUUID(),
            'routine_exercise_id': exId,
            'set_number': j + 1,
            'weight_kg': (setMap['weight_kg'] as num?)?.toDouble() ?? 0.0,
            'reps': setMap['reps'] as int? ?? 10,
            'is_warmup': isWarmupInt,
            'is_synced': isSynced,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }
}
