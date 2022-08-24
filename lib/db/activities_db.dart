import 'package:flutter/material.dart';
import 'package:carbon_tracker/models/activity.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as dev;

class ActivitiesDb with ChangeNotifier {
  static final ActivitiesDb instance = ActivitiesDb._init();
  static Database? _database;

  ActivitiesDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('activity.db');

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    //dev.log("init db");
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final numberType = 'REAL';
    final textType = 'TEXT';
    await db.execute('''
    CREATE TABLE $tableActivity (
        ${ActivityFields.id} $idType,
        ${ActivityFields.date} $textType,
        ${ActivityFields.time} $textType,
        ${ActivityFields.type} $textType,
        ${ActivityFields.distance} $numberType,
        ${ActivityFields.carbon} $numberType,
        ${ActivityFields.dateTime} $textType
        )
        ''');
  }

  Future<Activity> create(Activity activity) async {
    final db = await instance.database;
    final id = await db.insert(tableActivity, activity.toJson());

    return activity.copy(id: id);
  }

  Future<Activity> readActivity(int id) async {
    final db = await instance.database;
    final maps = await db.query(tableActivity,
        columns: ActivityFields.values,
        where: '${ActivityFields.id}= ? ',
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Activity.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<Activity?> getLastActivityWhereType(String type) async {
    int id;
    final db = await instance.database;
    final idR = await db
        .rawQuery('SELECT MAX(_id) FROM $tableActivity Where type= ?', [type]);
    if (idR.toList().first.values.first == null) {
      return null;
    }
    id = (idR.toList()[0].values.first as int);

    final maps = await db.query(tableActivity,
        columns: ActivityFields.values,
        where: '${ActivityFields.id}= ? ',
        whereArgs: [id]);

    return Activity.fromJson(maps.first);
  }

  Future<int?> getLastIdWhereType(String type) async {
    int id;
    final db = await instance.database;
    final idR = await db
        .rawQuery('SELECT MAX(_id) FROM $tableActivity Where type= ?', [type]);
    //dev.log('idR to List ${idR.toList().first.values.first}');
    if (idR.toList().first.values.first == null) {
      return null;
    } else {
      id = (idR.toList()[0].values.first as int);

      return id;
    }
  }

  Future<int> update(Activity actv, int id) async {
    final db = await instance.database;
    return db.update(
      tableActivity,
      actv.toJson(),
      where: '${ActivityFields.id} = ?',
      whereArgs: [id],
    );
  }

  void deleteActivity(int id) async {
    final db = await instance.database;
    var count =
        await db.rawDelete('DELETE FROM $tableActivity WHERE _id = ?', [id]);
    dev.log('$count');
  }

  void clean() async {
    final db = await instance.database;
    db.delete(tableActivity);

    //await db.execute("DROP TABLE IF EXISTS $tableActivity");
  }

  Future<List<Activity>> readAll() async {
    final db = await instance.database;

    final result = await db.query(tableActivity);
    return result.map((json) => Activity.fromJson(json)).toList();
  }

  Future<List<Map<String, Object?>>> getTotal() async {
    final db = await instance.database;
    final result =
        await db.rawQuery('SELECT SUM(Carbon) AS TOTAL FROM $tableActivity');

    //dev.log('${result.toList()}');
    return result.toList();
    //final result = await db.query(tableActivity);
  }

  Future<List<Activity>> readToday() async {
    final today_date = DateFormat('EEE d MMM ').format(DateTime.now());

    final db = await instance.database;
    final result = await db.query(tableActivity,
        columns: ActivityFields.values,
        where: '${ActivityFields.date}= ? ',
        whereArgs: [today_date]);

    return result.map((json) => Activity.fromJson(json)).toList();
  }

  Future close() async {
    final db = await instance.database;

    // db.close();
  }
}
