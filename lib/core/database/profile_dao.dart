import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import 'database_helper.dart';

class ProfileDao {
  final _supabase = Supabase.instance.client;

  Future<Profile?> getProfile(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Profile.fromMap(maps.first);
  }

  Future<void> saveProfile(Profile profile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // Upsert into Supabase
    await _supabase.from('profiles').upsert({
      'id': profile.id,
      'height': profile.height,
      'updated_at': profile.updatedAt,
    });

    // Save to SQLite read cache
    final db = await DatabaseHelper.database;
    await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
