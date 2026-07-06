import '../models/session.dart';
import 'database_helper.dart';

class SessionDao {
  Future<Session> insert(Session session) async {
    final db = await DatabaseHelper.database;
    final id = await db.insert('sessions', session.toMap());
    return session.copyWith(id: id);
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
    final db = await DatabaseHelper.database;
    await db.update('sessions', {'name': name}, where: 'id = ?', whereArgs: [id]);
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

    await db.update(
      'sessions',
      {'finished_at': null, 'created_at': newCreatedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> finishSession(int id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'sessions',
      {'finished_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the most recent session per distinct name (non-null names only).
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
    final db = await DatabaseHelper.database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}
