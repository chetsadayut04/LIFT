import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String generateUUID() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  values[6] = (values[6] & 0x0f) | 0x40; // version 4
  values[8] = (values[8] & 0x3f) | 0x80; // variant RFC 4122
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    if (i == 4 || i == 6 || i == 8 || i == 10) {
      buffer.write('-');
    }
    buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  static Future<String> _dbPath() async {
    if (kIsWeb) {
      return 'weightlifting.db';
    }
    if (Platform.isWindows) {
      final appData =
          Platform.environment['APPDATA'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      final dir = Directory(join(appData, 'weightlifting_tracker'));
      await dir.create(recursive: true);
      return join(dir.path, 'weightlifting.db');
    }
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '.';
      final dir = Directory(
        join(home, '.local', 'share', 'weightlifting_tracker'),
      );
      await dir.create(recursive: true);
      return join(dir.path, 'weightlifting.db');
    }
    return join(await getDatabasesPath(), 'weightlifting.db');
  }

  static Future<Database> _open() async {
    return openDatabase(
      await _dbPath(),
      version: 10,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT,
            is_synced INTEGER DEFAULT 0,
            date TEXT NOT NULL,
            name TEXT,
            created_at INTEGER NOT NULL,
            finished_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT,
            is_synced INTEGER DEFAULT 0,
            session_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            order_index INTEGER NOT NULL,
            FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE sets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT,
            is_synced INTEGER DEFAULT 0,
            exercise_id INTEGER NOT NULL,
            set_number INTEGER NOT NULL,
            weight_kg REAL NOT NULL,
            reps INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            is_warmup INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE exercise_configs (
            name TEXT PRIMARY KEY,
            rep_min INTEGER NOT NULL DEFAULT 8,
            rep_max INTEGER NOT NULL DEFAULT 12,
            is_synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE tombstones (
            uuid TEXT PRIMARY KEY,
            table_name TEXT NOT NULL,
            deleted_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            height REAL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE weight_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE,
            weight_kg REAL NOT NULL,
            logged_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE routines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            is_synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE routine_exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE,
            routine_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            order_index INTEGER NOT NULL,
            is_synced INTEGER DEFAULT 0,
            FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE routine_sets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE,
            routine_exercise_id INTEGER NOT NULL,
            set_number INTEGER NOT NULL,
            weight_kg REAL NOT NULL DEFAULT 0.0,
            reps INTEGER NOT NULL DEFAULT 10,
            is_warmup INTEGER NOT NULL DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            FOREIGN KEY (routine_exercise_id) REFERENCES routine_exercises(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE ai_chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE,
            is_user INTEGER NOT NULL,
            text TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE custom_exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE,
            name TEXT UNIQUE NOT NULL,
            category TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE sessions ADD COLUMN name TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE sets ADD COLUMN is_warmup INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE sessions ADD COLUMN finished_at INTEGER',
          );
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS exercise_configs (
              name TEXT PRIMARY KEY,
              rep_min INTEGER NOT NULL DEFAULT 8,
              rep_max INTEGER NOT NULL DEFAULT 12
            )
          ''');
        }
        if (oldVersion < 6) {
          try {
            await db.execute(
              'ALTER TABLE sessions ADD COLUMN finished_at INTEGER',
            );
          } catch (_) {
            // Ignore if column already exists
          }
        }
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE sessions ADD COLUMN uuid TEXT');
          await db.execute(
            'ALTER TABLE sessions ADD COLUMN is_synced INTEGER DEFAULT 0',
          );
          await db.execute('ALTER TABLE exercises ADD COLUMN uuid TEXT');
          await db.execute(
            'ALTER TABLE exercises ADD COLUMN is_synced INTEGER DEFAULT 0',
          );
          await db.execute('ALTER TABLE sets ADD COLUMN uuid TEXT');
          await db.execute(
            'ALTER TABLE sets ADD COLUMN is_synced INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE exercise_configs ADD COLUMN is_synced INTEGER DEFAULT 0',
          );
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tombstones (
              uuid TEXT PRIMARY KEY,
              table_name TEXT NOT NULL,
              deleted_at INTEGER NOT NULL
            )
          ''');
          await _backfillUUIDs(db);
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS profiles (
              id TEXT PRIMARY KEY,
              height REAL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS weight_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uuid TEXT UNIQUE,
              weight_kg REAL NOT NULL,
              logged_at INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS routines (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uuid TEXT UNIQUE,
              name TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              is_synced INTEGER DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS routine_exercises (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uuid TEXT UNIQUE,
              routine_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              order_index INTEGER NOT NULL,
              is_synced INTEGER DEFAULT 0,
              FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS routine_sets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uuid TEXT UNIQUE,
              routine_exercise_id INTEGER NOT NULL,
              set_number INTEGER NOT NULL,
              weight_kg REAL NOT NULL DEFAULT 0.0,
              reps INTEGER NOT NULL DEFAULT 10,
              is_warmup INTEGER NOT NULL DEFAULT 0,
              is_synced INTEGER DEFAULT 0,
              FOREIGN KEY (routine_exercise_id) REFERENCES routine_exercises(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ai_chat_messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uuid TEXT UNIQUE,
              is_user INTEGER NOT NULL,
              text TEXT NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS custom_exercises (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uuid TEXT UNIQUE,
              name TEXT UNIQUE NOT NULL,
              category TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  static Future<void> _backfillUUIDs(Database db) async {
    final sessions = await db.query(
      'sessions',
      columns: ['id'],
      where: 'uuid IS NULL',
    );
    for (final row in sessions) {
      final id = row['id'] as int;
      await db.update(
        'sessions',
        {'uuid': generateUUID()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    final exercises = await db.query(
      'exercises',
      columns: ['id'],
      where: 'uuid IS NULL',
    );
    for (final row in exercises) {
      final id = row['id'] as int;
      await db.update(
        'exercises',
        {'uuid': generateUUID()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    final sets = await db.query('sets', columns: ['id'], where: 'uuid IS NULL');
    for (final row in sets) {
      final id = row['id'] as int;
      await db.update(
        'sets',
        {'uuid': generateUUID()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  static Future<void> clearAndPopulateCache() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final db = await database;
    await db.transaction((txn) async {
      // Clear existing local tables
      await txn.delete('sets');
      await txn.delete('exercises');
      await txn.delete('sessions');
      await txn.delete('exercise_configs');
      await txn.delete('profiles');
      await txn.delete('weight_logs');

      // Fetch all from Supabase
      final remoteSessions = await supabase
          .from('sessions')
          .select()
          .eq('user_id', user.id);
      final remoteExercises = await supabase
          .from('exercises')
          .select()
          .eq('user_id', user.id);
      final remoteSets = await supabase
          .from('sets')
          .select()
          .eq('user_id', user.id);
      final remoteConfigs = await supabase
          .from('exercise_configs')
          .select()
          .eq('user_id', user.id);
      final remoteProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      final remoteWeightLogs = await supabase
          .from('weight_logs')
          .select()
          .eq('user_id', user.id);

      // Insert into local SQLite
      for (final s in remoteSessions) {
        await txn.insert('sessions', {
          'id': s['id'] as int,
          'date': s['date'] as String,
          'name': s['name'] as String?,
          'created_at': s['created_at'] as int,
          'finished_at': s['finished_at'] as int?,
        });
      }

      for (final ex in remoteExercises) {
        await txn.insert('exercises', {
          'id': ex['id'] as int,
          'session_id': ex['session_id'] as int,
          'name': ex['name'] as String,
          'order_index': ex['order_index'] as int,
        });
      }

      for (final s in remoteSets) {
        await txn.insert('sets', {
          'id': s['id'] as int,
          'exercise_id': s['exercise_id'] as int,
          'set_number': s['set_number'] as int,
          'weight_kg': (s['weight_kg'] as num).toDouble(),
          'reps': s['reps'] as int,
          'created_at': s['created_at'] as int,
          'is_warmup': (s['is_warmup'] as bool) ? 1 : 0,
        });
      }

      for (final cfg in remoteConfigs) {
        await txn.insert('exercise_configs', {
          'name': cfg['name'] as String,
          'rep_min': cfg['rep_min'] as int,
          'rep_max': cfg['rep_max'] as int,
        });
      }

      if (remoteProfile != null) {
        await txn.insert('profiles', {
          'id': remoteProfile['id'] as String,
          'height': (remoteProfile['height'] as num?)?.toDouble(),
          'updated_at': remoteProfile['updated_at'] as int,
        });
      }

      for (final wl in remoteWeightLogs) {
        await txn.insert('weight_logs', {
          'id': wl['id'] as int,
          'uuid': wl['uuid'] as String,
          'weight_kg': (wl['weight_kg'] as num).toDouble(),
          'logged_at': wl['logged_at'] as int,
        });
      }

      try {
        final remoteRoutines = await supabase
            .from('routines')
            .select()
            .eq('user_id', user.id);
        final remoteRoutineExercises = await supabase
            .from('routine_exercises')
            .select()
            .eq('user_id', user.id);
        final remoteRoutineSets = await supabase
            .from('routine_sets')
            .select()
            .eq('user_id', user.id);

        if (remoteRoutines.isNotEmpty) {
          await txn.delete('routine_sets');
          await txn.delete('routine_exercises');
          await txn.delete('routines');

          for (final r in remoteRoutines) {
            await txn.insert('routines', {
              'id': r['id'] as int,
              'uuid': r['uuid'] as String?,
              'name': r['name'] as String,
              'created_at': r['created_at'] as int,
              'is_synced': 1,
            });
          }
          for (final re in remoteRoutineExercises) {
            await txn.insert('routine_exercises', {
              'id': re['id'] as int,
              'uuid': re['uuid'] as String?,
              'routine_id': re['routine_id'] as int,
              'name': re['name'] as String,
              'order_index': re['order_index'] as int,
              'is_synced': 1,
            });
          }
          for (final rs in remoteRoutineSets) {
            await txn.insert('routine_sets', {
              'id': rs['id'] as int,
              'uuid': rs['uuid'] as String?,
              'routine_exercise_id': rs['routine_exercise_id'] as int,
              'set_number': rs['set_number'] as int,
              'weight_kg': (rs['weight_kg'] as num).toDouble(),
              'reps': rs['reps'] as int,
              'is_warmup': (rs['is_warmup'] as bool? ?? false) ? 1 : 0,
              'is_synced': 1,
            });
          }
        }
      } catch (_) {
        // Routines table on Supabase might not exist yet; fallback silently
      }
    });
  }
}
