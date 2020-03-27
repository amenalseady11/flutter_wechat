import 'dart:async';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class SqfliteProvider extends ChangeNotifier {
  static SqfliteProvider _sqflite = SqfliteProvider._();
  factory SqfliteProvider() => _sqflite;
  SqfliteProvider._();

  static SqfliteProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<SqfliteProvider>(context, listen: listen);
  }

  Future<sqflite.Database> connect() async {
    if ((await this.database)?.isOpen ?? false) return this.database;
//    sqflite.Sqflite.setDebugModeOn(global.isDebug);
    String name = "sqflite";
    int version = 1;
    var basePath = await sqflite.getDatabasesPath();
    var dbPath = path.join(basePath, "$name.db");
    LogUtil.v("sqlflite 数据库地址：\n\t$dbPath");
    Completer<sqflite.Database> completer = Completer();
    this.database = completer.future;
    var database = await sqflite.openDatabase(
      dbPath,
      version: version,
      onCreate: (database, version) async {
        (await rootBundle.loadString("assets/data/sql/create.$version.sql"))
            .split(";")
            .forEach((sql) async {
          if (sql.isEmpty) return;
          await database.execute(sql);
        });
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        String sql = await rootBundle
            .loadString("assets/data/sql/upgrade.$newVersion.$oldVersion.sql");
        await database.execute(sql);
      },
    );
    completer.complete(database);
    if (database?.isOpen ?? false) notifyListeners();
    return database;
  }

  Future<sqflite.Database> database;
}
