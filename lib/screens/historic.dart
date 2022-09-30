
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:location/location.dart' as loc;

import 'package:carbon_tracker/db/activities_db.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;

import '../widgets/historic_screen.dart';

class Historic extends StatefulWidget {
  Historic({Key? key}) : super(key: key);

  @override
  State<Historic> createState() => _HistoricState();
}

class _HistoricState extends State<Historic> {
  bool isLoading = false;

  List<ActivityModel.Activity>? activities;
  List<ActivityModel.Activity> month_activities = [];
  List<ActivityModel.Activity> transitoires = [];

  double? _distance, _carbon;
  loc.LocationData? _startLocation, _endLocation;

  ActivityModel.Activity? lastActivity;
  ActivityModel.Activity? updatedActivity;
  DateTime? _dateTime;
  int? lastId;
  String? _activityType;

  final _activityStreamController = StreamController<Activity>();
  StreamSubscription<Activity>? _activityStreamSubscription;

  Future addActivity(
    date,
    time,
    type,
    _distance,
    carbon,
    dateTime,
      year
  ) async {
    final act = ActivityModel.Activity(
      date: date,
      time: time,
      type: type,
      distance: _distance,
      carbon: carbon,
      dateTime: dateTime,
      // year:year
    );
    await ActivitiesDb.instance.create(act);
  }



  void _handleError(dynamic error) {
    print('Catch Error >> $error');
  }

  Future refreshPage() async {
    setState(() => isLoading = true);
    activities = await ActivitiesDb.instance.readAll();
    List<ActivityModel.Activity> transitoires = [];
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    refreshPage();

  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Color.fromRGBO(3, 96, 99, 1),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              child: Text(
                'Carbon Tracker',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.topLeft,
              color: Color.fromRGBO(3, 95, 99, 1),
              child: Column(
                children: [

                  Expanded(child: HistoricScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
