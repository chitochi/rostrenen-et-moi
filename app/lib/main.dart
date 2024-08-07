import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rostrenen_et_moi/app.dart';
import 'package:rostrenen_et_moi/router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final database = await openDatabase(
    "rostrenen_et_moi.db",
    version: 3,
    onCreate: (database, version) async {
      await database.execute('''CREATE TABLE drafts (
	  id INTEGER PRIMARY KEY AUTOINCREMENT,
	  address TEXT NOT NULL,
	  description TEXT NOT NULL,
	  full_name TEXT NOT NULL,
	  email TEXT NOT NULL,
	  phone_number TEXT NOT NULL
	)''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion <= 2) {
        var batch = db.batch();
        batch.execute("DROP TABLE drafts");
        batch.execute('''CREATE TABLE drafts (
	  id INTEGER PRIMARY KEY AUTOINCREMENT,
	  address TEXT NOT NULL,
	  description TEXT NOT NULL,
	  full_name TEXT NOT NULL,
	  email TEXT NOT NULL,
	  phone_number TEXT NOT NULL
	)''');
        await batch.commit();
      }
    },
  );

  final dio = Dio();

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  final router = createRouter(
    database: database,
    dio: dio,
  );

  runApp(App(
    database: database,
    dio: dio,
    router: router,
  ));
}
