import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/db_factory.dart';
import 'core/providers/unit_provider.dart';
import 'app.dart';

// TODO: Replace with your actual Supabase URL and Anon Key
const String _supabaseUrl = 'YOUR_SUPABASE_URL';
const String _supabaseAnonKey = 'YOUR_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  initDatabaseFactory();
  final prefs = await SharedPreferences.getInstance();
  final isLbs = prefs.getBool('is_lbs') ?? false;
  runApp(ProviderScope(
    overrides: [unitInitProvider.overrideWithValue(isLbs)],
    child: const App(),
  ));
}
