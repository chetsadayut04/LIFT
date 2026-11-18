import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';

void initDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
  try {
    ImagePickerPlugin.registerWith(webPluginRegistrar);
  } catch (_) {}
}
