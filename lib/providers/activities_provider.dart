import 'package:flutter/material.dart';
import 'package:carbon_tracker/models/activity.dart';

class Activities with ChangeNotifier {
  List<Activity> _items = [];

  List<Activity> get items {
    return [..._items];
  }

  void addProduct() {
    //_items.add(Activity(date: date, time: time, type: type, carbon: carbon, distance: distance, dateTime: dateTime));
    notifyListeners();
  }
}
