import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../models/session.dart';
import 'database_helper.dart';

class SessionDao {
  final _supabase = Supabase.instance.client;

  Future<Session> insert(Session session) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final response = await _supabase.from('sessions').insert({
      'user_id': user.id,
      'date': session.date,
      'name': session.name,
      'created_at': session.createdAt,
      'finished_at': session.finishedAt,
    }).select().single();

    final inserted = Session.fromMap(response);

    // Save to SQLite read cache
    final db = await DatabaseHelper.database;
    await db.insert('sessions', {
      'id': inserted.id,
      'date': inserted.date,
      'name': inserted.name,
      'created_at': inserted.createdAt,
      'finished_at': inserted.finishedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return inserted;
  }

  Future<List<Session>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('sessions', orderBy: 'date DESC');
    return maps.map(Session.fromMap).toList();
  }

  Future<Session?> getByDate(String date) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('sessions', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<Session?> getById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('sessions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<List<Session>> getByDateRange(String from, String to) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'sessions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [from, to],
    );
    return maps.map(Session.fromMap).toList();
  }

  Future<Set<String>> getAllDates() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('sessions', columns: ['date']);
    return maps.map((m) => m['date'] as String).toSet();
  }

  Future<Set<String>> getFinishedDates() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('sessions', columns: ['date'],
        where: 'finished_at IS NOT NULL');
    return maps.map((m) => m['date'] as String).toSet();
  }

  Future<void> updateName(int id, String name) async {
    // 1. Update on Supabase
    await _supabase.from('sessions').update({'name': name}).eq('id', id);

    // 2. Update SQLite Read Cache
    final db = await DatabaseHelper.database;
    await db.update(
      'sessions',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Session>> getStaleActiveSessions(String beforeDate) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('sessions',
        where: 'date < ? AND finished_at IS NULL', whereArgs: [beforeDate]);
    return maps.map(Session.fromMap).toList();
  }

  Future<void> reopenSession(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return;
    final session = Session.fromMap(maps.first);
    if (session.finishedAt == null) return;

    final elapsed = session.finishedAt! - session.createdAt;
    final newCreatedAt = DateTime.now().millisecondsSinceEpoch - elapsed;

    // 1. Update on Supabase
    await _supabase.from('sessions').update({
      'finished_at': null,
      'created_at': newCreatedAt,
    }).eq('id', id);

    // 2. Update SQLite Read Cache
    await db.update(
      'sessions',
      {'finished_at': null, 'created_at': newCreatedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> finishSession(int id) async {
    final finishedAt = DateTime.now().millisecondsSinceEpoch;

    // 1. Update on Supabase
    await _supabase.from('sessions').update({'finished_at': finishedAt}).eq('id', id);

    // 2. Update SQLite Read Cache
    final db = await DatabaseHelper.database;
    await db.update(
      'sessions',
      {'finished_at': finishedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Session>> getRecentNamedSessions({int limit = 8}) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM sessions s
      INNER JOIN (
        SELECT name, MAX(date) AS max_date
        FROM sessions
        WHERE name IS NOT NULL AND name != ''
        GROUP BY name
      ) latest ON s.name = latest.name AND s.date = latest.max_date
      ORDER BY s.date DESC
      LIMIT ?
    ''', [limit]);
    return maps.map(Session.fromMap).toList();
  }

  Future<void> delete(int id) async {
    // 1. Delete from Supabase
    await _supabase.from('sessions').delete().eq('id', id);

    // 2. Delete from SQLite (cascade deletions will handle exercises and sets locally)
    final db = await DatabaseHelper.database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}
