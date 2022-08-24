import 'package:flutter/material.dart';
import 'package:carbon_tracker/models/activity.dart';
import 'dart:developer' as dev;

import '../db/activities_db.dart';

class Activities with ChangeNotifier {
  List<Activity> _monthActivities = [];
  List<Activity> _allActivities = [];
  List<Activity> _todayActivities = [];
  int nbMonth = DateTime.now().month;

  int setMonthActivities(int nb) {
    nbMonth = nb;
    MonthActivities(nb);
    return nbMonth;
  }

  List<Activity> get activitiesMonth {
    return [..._monthActivities];
  }

  Future<List<Activity>> get allActivities async {
    List<Activity> activities = await ActivitiesDb.instance.readAll();
    _allActivities = activities;
    return [..._allActivities];
  }

  Future<List<Activity>> get todayActivities async {
    List<Activity> activities = await ActivitiesDb.instance.readToday();
    _todayActivities = activities;
    return [..._todayActivities];
  }

  Future<List<Activity>> MonthActivities(int month) async {
    dev.log(month.toString());
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
