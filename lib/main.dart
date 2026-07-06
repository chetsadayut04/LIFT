import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/db_factory.dart';
import 'core/providers/unit_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDatabaseFactory();
  final prefs = await SharedPreferences.getInstance();
  final isLbs = prefs.getBool('is_lbs') ?? false;
  runApp(ProviderScope(
    overrides: [unitInitProvider.overrideWithValue(isLbs)],
    child: const App(),
  ));
}
