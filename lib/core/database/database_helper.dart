import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      final appData = Platform.environment['APPDATA'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      final dir = Directory(join(appData, 'weightlifting_tracker'));
      await dir.create(recursive: true);
      return join(dir.path, 'weightlifting.db');
    }
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '.';
      final dir = Directory(join(home, '.local', 'share', 'weightlifting_tracker'));
      await dir.create(recursive: true);
      return join(dir.path, 'weightlifting.db');
    }
    return join(await getDatabasesPath(), 'weightlifting.db');
  }

  static Future<Database> _open() async {
    return openDatabase(
      await _dbPath(),
      version: 6,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            name TEXT,
            created_at INTEGER NOT NULL,
            finished_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            order_index INTEGER NOT NULL,
            FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE sets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
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
            rep_max INTEGER NOT NULL DEFAULT 12
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE sessions ADD COLUMN name TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE sets ADD COLUMN is_warmup INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE sessions ADD COLUMN finished_at INTEGER');
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
            await db.execute('ALTER TABLE sessions ADD COLUMN finished_at INTEGER');
          } catch (_) {
            // Ignore if column already exists
          }
        }
      },
    );
  }
}
