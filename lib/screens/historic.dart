import 'package:carbon_tracker/screens/goals_screen.dart';
import 'package:carbon_tracker/widgets/historic_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:location_distance_calculator/location_distance_calculator.dart';
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
  ) async {
    final act = ActivityModel.Activity(
      //id: 132,
      date: date,
      time: time,
      type: type,
      distance: _distance,
      carbon: carbon,
      dateTime: dateTime,
    );
    await ActivitiesDb.instance.create(act);
  }

  // void _onActivityReceive(Activity activity) async {
  //   dev.log('Activity Detected >> ${activity.toJson()}');
  //   _activityStreamController.sink.add(activity);
  //   if (_startLocation == null) {
  //     var startLoc = await loc.Location().getLocation();
  //     setState(() {
  //       _startLocation = startLoc;
  //       dev.log('Start Location >> $_startLocation');
  //       _dateTime = DateTime.now();
  //     });
  //   }
  //   if (_startLocation != null) {
  //     var actType;
  //     var carb;
  //     _endLocation = await loc.Location().getLocation();
  //     try {
  //       _distance = await (LocationDistanceCalculator().distanceBetween(
  //           _startLocation!.latitude!,
  //           _startLocation!.longitude!,
  //           _endLocation!.latitude!,
  //           _endLocation!.longitude!));
  //       if (activity.toJson()['type'].toString().contains('.WALKING') ||
  //           activity.toJson()['type'].toString().contains('UNKNOWN')) {
  //         actType = 'Walk';
  //         carb = _distance! * 0.035;
  //       } else if (activity
  //           .toJson()['type']
  //           .toString()
  //           .contains('ON_BICYCLE')) {
  //         actType = 'Bicycle';
  //         carb = _distance! * 0.019;
  //       } else if (activity
  //           .toJson()['type']
  //           .toString()
  //           .contains('IN_VEHICLE')) {
  //         actType = 'Car';
  //         carb = _distance! * 0.17;
  //       } else if (activity.toJson()['type'].toString().contains('RUNNING')) {
  //         actType = 'Running';
  //         carb = _distance! * 0.012;
  //       } else if (activity.toJson()['type'].toString().contains('STILL')) {
  //         actType = 'Still';
  //       }
  //       dev.log('End Location >> $_endLocation');
  //     } on PlatformException {
  //       _distance = -1.0;
  //     }
  //     setState(() {
  //       _activityType = actType;
  //       if (_carbon != 0.0 && _distance != 0.0) {
  //         _carbon = carb / 1000;
  //         _distance = _distance! / 1000;
  //       }
  //     });
  //     if (_activityType != 'Still' && _distance! >= 0.1) {
  //       lastActivity = await ActivitiesDb.instance
  //           .getLastActivityWhereType(_activityType!);
  //       lastId = await ActivitiesDb.instance.getLastIdWhereType(_activityType!);
  //       // Activity Does Not Exist
  //       if (lastId == null && lastActivity == null) {
  //         addActivity(
  //             DateFormat('EEE d MMM ').format(_dateTime!),
  //             DateFormat(' kk:mm').format(_dateTime!),
  //             _activityType,
  //             _distance,
  //             _carbon,
  //             _dateTime.toString());
  //         refreshPage();
  //       }
  //       // Activity Exists before 10mins
  //       if (_dateTime!
  //               .difference(DateTime.parse(lastActivity!.dateTime))
  //               .inMinutes <=
  //           10) {
  //         double new_carbon = lastActivity!.carbon + _carbon!;
  //         double new_distance = lastActivity!.distance + _distance!;
  //         updatedActivity = ActivityModel.Activity(
  //             date: lastActivity!.date,
  //             time: lastActivity!.time,
  //             type: lastActivity!.type,
  //             carbon: new_carbon,
  //             distance: new_distance,
  //             dateTime: lastActivity!.dateTime);
  //         await ActivitiesDb.instance.update(updatedActivity!, lastId!);
  //         refreshPage();
  //       }
  //       // Activity Exists but too far
  //       else {
  //         addActivity(
  //             DateFormat('EEE d MMM ').format(_dateTime!),
  //             DateFormat(' kk:mm').format(_dateTime!),
  //             _activityType,
  //             _distance,
  //             _carbon,
  //             _dateTime.toString());
  //         refreshPage();
  //       }
  //     }
  //   }
  // }

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

    // WidgetsBinding.instance.addPostFrameCallback(
    //   (_) async {
    //     final activityRecognition = FlutterActivityRecognition.instance;
    //     _activityStreamSubscription = activityRecognition.activityStream
    //         .handleError(_handleError)
    //         .listen(_onActivityReceive);
    //   },
    // );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Color.fromRGBO(3, 96, 99, 1),
        child: Column(
          // mainAxisSize: MainAxisSize.min,
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
                //     mainAxisSize: MainAxisSize.min,
                children: [
                  //       HistoricChart(),
                  //   Expanded(child: GoalsScreen()),
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
