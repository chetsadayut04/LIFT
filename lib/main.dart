import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/db_factory.dart';
import 'core/providers/unit_provider.dart';
import 'app.dart';

const String _supabaseUrl = 'https://tscsqdhnkfqvqcadvkdx.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzY3NxZGhua2ZxdnFjYWR2a2R4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyODI3NTAsImV4cCI6MjEwMTg1ODc1MH0.Cck9mgHyZugIki8pM2wHE9BeZPVnT_um1Ue1ygDTva8';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseAnonKey,
  );

  initDatabaseFactory();
  final prefs = await SharedPreferences.getInstance();
  final isLbs = prefs.getBool('is_lbs') ?? false;
  runApp(
    ProviderScope(
      overrides: [unitInitProvider.overrideWithValue(isLbs)],
      child: const App(),
    ),
  );
}
