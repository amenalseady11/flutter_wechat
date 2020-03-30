import 'dart:async';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
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
    String name = "sqflite";
    int version = 1;
    var basePath = await sqflite.getDatabasesPath();
    var dbPath = path.join(basePath, "$name.db");
//    File(dbPath).deleteSync();
    LogUtil.v("sqlflite 数据库地址：\n\t$dbPath", tag: "### SqfliteProvider ###");
    Completer<sqflite.Database> completer = Completer();
    this.database = completer.future;
    var database = await sqflite.openDatabase(dbPath, version: version,
        onCreate: (database, version) async {
      (await rootBundle.loadString("assets/data/sql/create.$version.sql"))
          .replaceAll("\n", "")
          .split(";")
          .forEach((sql) async {
        LogUtil.v("create: $sql", tag: "### SqfliteProvider ###");
        if (sql.isEmpty) return;
        await database.execute(sql);
      });
    });
    completer.complete(database);
    if (database?.isOpen ?? false) notifyListeners();
    return database;
  }

  Future<sqflite.Database> database;
}
