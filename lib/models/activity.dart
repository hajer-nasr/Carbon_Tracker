import 'package:flutter/material.dart';

final String tableActivity = 'ActivityTable';

class ActivityFields {
  static final List<String> values = [
    id,
    date,
    //year,
    type,
    time,
    distance,
    carbon,
    dateTime
  ];

  static final String id = '_id';
  static final String date = 'date';

 // static final String year = 'year';
  static final String time = 'time';
  static final String type = 'type';
  static final String distance = 'distance';
  static final String carbon = 'carbon';
  static final String dateTime = 'dateTime';
}

class Activity {
  final String date;
  //final String year;
  final String time;

  final String type;

  final double distance;
  final double carbon;
  final String dateTime;

  const Activity({
    required this.date,
    required this.time,
    required this.type,
    required this.carbon,
    required this.distance,
    required this.dateTime,
    //required this.year,
  });

  Activity copy(
          {int? id,
          String? date,
          String? time,
        //  String? year,
          String? type,
          double? distance,
          double? carbon,
          String? dateTime}) =>
      Activity(
        date: this.date,
        time: this.time,
       // year: this.year,
        type: this.type,
        carbon: this.carbon,
        distance: this.distance,
        dateTime: this.dateTime,
      );

  static Activity fromJson(Map<String, Object?> json) => Activity(
        date: json[ActivityFields.date] as String,
        type: json[ActivityFields.type] as String,
      //  year: json[ActivityFields.year] as String,

        time: json[ActivityFields.time] as String,
        carbon: json[ActivityFields.carbon] as double,
        distance: json[ActivityFields.distance] as double,
        dateTime: json[ActivityFields.dateTime] as String,
      );

  Map<String, Object?> toJson() => {
        //ActivityFields.year: year,
        ActivityFields.date: date,
        ActivityFields.time: time,
        ActivityFields.type: type,
        ActivityFields.distance: distance,
        ActivityFields.carbon: carbon,
        ActivityFields.dateTime: dateTime,
      };
}
