import 'package:flutter/material.dart';
import 'package:carbon_tracker/models/activity.dart';
import 'dart:developer' as dev;

import '../db/activities_db.dart';
import 'package:sqflite/sqflite.dart';

class Activities with ChangeNotifier {
  List<Activity> _monthActivities = [];
  List<Activity> _allActivities = [];
  List<Activity> _todayActivities = [];
  int nbMonth = DateTime.now().month;
  List<Activity> actv = [];
  var _carbonRun = 0.0;
  var _carbonBike = 0.0;
  var _carbonCar = 0.0;
  var _carbonWalk = 0.0;
  var _total = 0.0;
  var _totalYear = 0.0;
  var _totalJan = 0.0;
  var _totalFev = 0.0;
  var _totalMars = 0.0;
  var _totalAvr = 0.0;
  var _totalMay = 0.0;
  var _totalJun = 0.0;
  var _totalJul = 0.0;
  var _totalAout = 0.0;
  var _totalSep = 0.0;
  var _totalOct = 0.0;
  var _totalNov = 0.0;
  var _totalDec = 0.0;
  var total_this_month = 0.0;
  var total_last_month = 0.0;
  var taux = 0.0;

  double get totalJan {
    return _totalJan;
  }

  double get totalFev {
    return _totalFev;
  }

  double get totalMar {
    return _totalMars;
  }

  double get totalAvr {
    return _totalAvr;
  }

  double get totalMay {
    return _totalMay;
  }

  double get totalJun {
    return _totalJun;
  }

  double get totalJul {
    return _totalJul;
  }

  double get totalAout {
    return _totalAout;
  }

  double get totalSep {
    return _totalSep;
  }

  double get totalOct {
    return _totalOct;
  }

  double get totalNov {
    return _totalNov;
  }

  double get totalDec {
    return _totalDec;
  }

  int setMonthActivities(int nb) {
    nbMonth = nb;
    MonthActivities(nb);
    return nbMonth;
  }

  double get totalYear {
    return _totalYear;
  }

  double get carbonRun {
    return _carbonRun;
  }

  double get carbonBike {
    return _carbonBike;
  }

  double get carbonCar {
    return _carbonCar;
  }

  double get carbonWalk {
    if (_carbonWalk != 0.0)
      return _carbonWalk / 1000;
    else
      return _carbonWalk;
  }

  double get total {
    return _total;
  }

  double get tauxFu {
    return taux;
  }

  List<Activity> get activitiesMonth {
    return [..._monthActivities];
  }

  List<Activity> get activitiesAll {
    return [..._allActivities];
  }

  List<Activity> get activitiesToday {
    return [..._todayActivities];
  }

  Future<List<Activity>> allActivities() async {
    List<Activity> activities = await ActivitiesDb.instance.readAll();
    _allActivities = activities;
    notifyListeners();
    return _allActivities;
  }

  var totalCarbonWalk = 0.0;
  var totalWalk = 0.0;
  var totalDiffWalk = 0.0;
  var tx = 0.0;

  Future<double> tauxFunc() async {
    total_this_month = 0.0;
    total_last_month = 0.0;
    tx = 0.0;
    // taux=0.0;
    List<Activity> activities = await ActivitiesDb.instance.readAll();
    for (int i = 0; i < activities.length; i++) {
      DateTime activityDate = DateTime.parse(activities[i].dateTime);
      if (activityDate.month == DateTime.now().month - 1) {
        if (activities[i].type == 'Walk') {
          total_last_month += activities[i].carbon / 1000;
        } else {
          total_last_month += activities[i].carbon;
        }
      }
      if (activityDate.month == DateTime.now().month) {
        if (activities[i].type == 'Walk') {
          total_this_month += activities[i].carbon / 1000;
        } else {
          total_this_month += activities[i].carbon;
        }
      }
    }

    if (total_this_month != 0.0 && total_last_month != 0.0) {
      tx = (((total_this_month - total_last_month) / total_last_month) * 100);
    } else if (total_last_month == 0.0) {
      tx = total_this_month;
    }
    //dev.log('Last MONTH $total_last_month');
    //dev.log('THIS MONTH $total_this_month');
    taux = tx;
    // dev.log('TAUX $taux');
    return taux;
  }

  Future<void> totalMonths() async {
    var jan = 0.0;
    var fev = 0.0;
    var mar = 0.0;
    var avr = 0.0;
    var may = 0.0;
    var jun = 0.0;
    var jul = 0.0;
    var aou = 0.0;
    var sep = 0.0;
    var oct = 0.0;
    var nov = 0.0;
    var dec = 0.0;
    List<Activity> activities = await ActivitiesDb.instance.readAll();
    for (var i = 0; i < activities.length; i++) {
      switch (DateTime.parse(activities[i].dateTime).month) {
        case 1:
          {
            if (activities[i].type == 'Walk') {
              jan += activities[i].carbon / 1000;
            } else {
              jan += activities[i].carbon;
            }
          }
          break;
        case 2:
          {
            if (activities[i].type == 'Walk') {
              fev += activities[i].carbon / 1000;
            } else {
              fev += activities[i].carbon;
            }
          }
          break;
        case 3:
          {
            if (activities[i].type == 'Walk') {
              mar += activities[i].carbon / 1000;
            } else {
              mar += activities[i].carbon;
            }
          }
          break;
        case 4:
          {
            if (activities[i].type == 'Walk') {
              avr += activities[i].carbon / 1000;
            } else {
              avr += activities[i].carbon;
            }
          }
          break;
        case 5:
          {
            if (activities[i].type == 'Walk') {
              may += activities[i].carbon / 1000;
            } else {
              may += activities[i].carbon;
            }
          }
          break;
        case 6:
          {
            if (activities[i].type == 'Walk') {
              jun += activities[i].carbon / 1000;
            } else {
              jun += activities[i].carbon;
            }
          }
          break;
        case 7:
          {
            if (activities[i].type == 'Walk') {
              jul += activities[i].carbon / 1000;
            } else {
              jul += activities[i].carbon;
            }
          }
          break;
        case 8:
          {
            if (activities[i].type == 'Walk') {
              aou += activities[i].carbon / 1000;
            } else {
              aou += activities[i].carbon;
            }
          }
          break;
        case 9:
          {
            if (activities[i].type == 'Walk') {
              sep += activities[i].carbon / 1000;
            } else {
              sep += activities[i].carbon;
            }
          }
          break;
        case 10:
          {
            if (activities[i].type == 'Walk') {
              oct += activities[i].carbon / 1000;
            } else {
              oct += activities[i].carbon;
            }
          }
          break;
        case 11:
          {
            if (activities[i].type == 'Walk') {
              nov += activities[i].carbon / 1000;
            } else {
              nov += activities[i].carbon;
            }
          }
          break;
        case 12:
          {
            if (activities[i].type == 'Walk') {
              dec += activities[i].carbon / 1000;
            } else {
              dec += activities[i].carbon;
            }
          }
          break;
      }
    }
    ;
    _totalJan = jan;
    _totalFev = fev;
    _totalMars = mar;
    _totalAvr = avr;
    _totalMay = may;
    _totalJun = jun;
    _totalJul = jul;
    _totalAout = aou;
    _totalSep = sep;
    _totalOct = oct;
    _totalNov = nov;
    _totalDec = dec;
  }

  void updateValues() async {
    totalDiffWalk = 0.0;
    totalWalk = 0.0;
    // _totalYear = 0.0;
    var tot = 0.0;
    List<Map<String, Object?>>? listTotalDiffWalk =
        await ActivitiesDb.instance.getTotal();
    List<Map<String, Object?>>? listWalk =
        await ActivitiesDb.instance.getTotalWalk();
    if (listTotalDiffWalk[0].values.first != null) {
      totalDiffWalk = (listTotalDiffWalk[0].values.first as double);
      tot += totalDiffWalk;
    }
    if (listWalk[0].values.first != null) {
      totalWalk = (listWalk[0].values.first as double) / 1000;
      tot += totalWalk;
    }
    _totalYear = tot;
    _carbonRun = 0.0;
    _carbonBike = 0.0;
    _carbonCar = 0.0;
    _carbonWalk = 0.0;
    _total = 0.0;
    dev.log('$_totalYear');
    actv = await todayActivities();
    for (var i = 0; i < actv.length; i++) {
      switch (actv[i].type) {
        case 'Walk':
          {
            _carbonWalk += actv[i].carbon;
          }
          break;
        case 'Running':
          {
            _carbonRun += actv[i].carbon;
          }
          break;
        case 'Bicycle':
          {
            _carbonBike += actv[i].carbon;
          }
          break;
        case 'Car':
          {
            _carbonCar += actv[i].carbon;
          }
      }
    }

    if (_carbonWalk != null) {
      totalCarbonWalk = _carbonWalk / 1000;
    } else {
      totalCarbonWalk = 0.0;
    }

    _total += (_carbonRun + _carbonBike + _carbonCar + totalCarbonWalk);
    notifyListeners();
  }

  Future<void> add(Activity activity) async {
    final db = await ActivitiesDb.instance.database;
    final id = await db.insert(tableActivity, activity.toJson());
    allActivities();
    todayActivities();
    MonthActivities(8);
    updateValues();
    tauxFunc();
    totalMonths();
    notifyListeners();
  }

  Future<int> update(Activity actv, int id) async {
    final db = await ActivitiesDb.instance.database;
    var result = db.update(
      tableActivity,
      actv.toJson(),
      where: '${ActivityFields.id} = ?',
      whereArgs: [id],
    );
    allActivities();
    todayActivities();
    MonthActivities(8);
    tauxFunc();
    totalMonths();
    updateValues();
    notifyListeners();

    return result;
  }

  Future<List<Activity>> todayActivities() async {
    List<Activity> activities = await ActivitiesDb.instance.readToday();

    _todayActivities = activities;
    // dev.log('$_todayActivities fel TodayActivities Provider');
    for (int i = 0; i < activities.length; i++) {
      activities.sort((a, b) {
        return (b.dateTime.compareTo(a.dateTime));
      });
    }
    notifyListeners();
    return _todayActivities;
  }

  Future<List<Activity>> MonthActivities(int month) async {
    List<Activity> activities = await ActivitiesDb.instance.readAll();
    List<Activity> aux = [];
    for (int i = 0; i < activities.length; i++) {
      DateTime activityDate = DateTime.parse(activities[i].dateTime);
      if (activityDate.month == month &&
          activityDate.year == DateTime.now().year) {
        aux.add(activities[i]);
      }
    }
    for (int i = 0; i < aux.length; i++) {
      aux.sort((a, b) {
        return (b.dateTime.compareTo(a.dateTime));
      });
    }
    _monthActivities = aux;
    notifyListeners();
    return _monthActivities;
  }
}
