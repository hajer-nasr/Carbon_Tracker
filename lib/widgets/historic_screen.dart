import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:location_distance_calculator/location_distance_calculator.dart';
import 'package:carbon_tracker/db/activities_db.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;

import 'historic_chart.dart';

class HistoricScreen extends StatefulWidget {
  HistoricScreen({Key? key}) : super(key: key);
  @override
  State<HistoricScreen> createState() => _HistoricScreenState();
}

class _HistoricScreenState extends State<HistoricScreen> {
  bool _activityPermission = false;
  bool _locationPermission = false;
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

  Future refreshPage() async {
    setState(() => isLoading = true);
    activities = await ActivitiesDb.instance.readAll();
    List<ActivityModel.Activity> transitoires = [];
    setState(() {
      isLoading = false;
      for (int i = 0; i < activities!.length; i++) {
        DateTime activityDate = DateTime.parse(activities![i].dateTime);
        if (activityDate.month == DateTime.now().month) {
          transitoires.add(activities![i]);
        }
      }
      for (int i = 0; i < transitoires.length; i++) {
        transitoires.sort((a, b) {
          return (b.dateTime.compareTo(a.dateTime));
        });
      }
      month_activities = transitoires;
    });
  }

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

  void _onActivityReceive(Activity activity) async {
    dev.log('Activity Detected >> ${activity.toJson()}');
    _activityStreamController.sink.add(activity);
    if (_startLocation == null) {
      var startLoc = await loc.Location().getLocation();
      setState(() {
        _startLocation = startLoc;
        dev.log('Start Location >> $_startLocation');
        _dateTime = DateTime.now();
      });
    }
    if (_startLocation != null) {
      var actType;
      var carb;
      _endLocation = await loc.Location().getLocation();
      try {
        _distance = await (LocationDistanceCalculator().distanceBetween(
            _startLocation!.latitude!,
            _startLocation!.longitude!,
            _endLocation!.latitude!,
            _endLocation!.longitude!));
        if (activity.toJson()['type'].toString().contains('.WALKING') ||
            activity.toJson()['type'].toString().contains('UNKNOWN')) {
          actType = 'Walk';
          carb = _distance! * 0.035;
        } else if (activity
            .toJson()['type']
            .toString()
            .contains('ON_BICYCLE')) {
          actType = 'Bicycle';
          carb = _distance! * 0.019;
        } else if (activity
            .toJson()['type']
            .toString()
            .contains('IN_VEHICLE')) {
          actType = 'Car';
          carb = _distance! * 0.17;
        } else if (activity.toJson()['type'].toString().contains('RUNNING')) {
          actType = 'Running';
          carb = _distance! * 0.012;
        } else if (activity.toJson()['type'].toString().contains('STILL')) {
          actType = 'Still';
        }
        dev.log('End Location >> $_endLocation');
      } on PlatformException {
        _distance = -1.0;
      }
      setState(() {
        _activityType = actType;
        if (_carbon != 0.0 && _distance != 0.0) {
          _carbon = carb / 1000;
          _distance = _distance! / 1000;
        }
      });
      if (_activityType != 'Still' && _distance! >= 0.1) {
        lastActivity = await ActivitiesDb.instance
            .getLastActivityWhereType(_activityType!);
        lastId = await ActivitiesDb.instance.getLastIdWhereType(_activityType!);
        // Activity Does Not Exist
        if (lastId == null && lastActivity == null) {
          addActivity(
              DateFormat('EEE d MMM ').format(_dateTime!),
              DateFormat(' kk:mm').format(_dateTime!),
              _activityType,
              _distance,
              _carbon,
              _dateTime.toString());
          refreshPage();
        }
        // Activity Exists before 10mins
        if (_dateTime!
                .difference(DateTime.parse(lastActivity!.dateTime))
                .inMinutes <=
            10) {
          double new_carbon = lastActivity!.carbon + _carbon!;
          double new_distance = lastActivity!.distance + _distance!;
          updatedActivity = ActivityModel.Activity(
              date: lastActivity!.date,
              time: lastActivity!.time,
              type: lastActivity!.type,
              carbon: new_carbon,
              distance: new_distance,
              dateTime: lastActivity!.dateTime);
          await ActivitiesDb.instance.update(updatedActivity!, lastId!);
          refreshPage();
        }
        // Activity Exists but too far
        else {
          addActivity(
              DateFormat('EEE d MMM ').format(_dateTime!),
              DateFormat(' kk:mm').format(_dateTime!),
              _activityType,
              _distance,
              _carbon,
              _dateTime.toString());
          refreshPage();
        }
      }
    }
  }

  void _handleError(dynamic error) {
    print('Catch Error >> $error');
  }

  void _getLocationPermission() async {
    var status = await Permission.location.status;
    if (await Permission.location.status.isGranted) {
      setState(() {
        _locationPermission = true;
        print(_locationPermission);
        print(_activityPermission);
      });
    } else if (await Permission.location.status.isDenied) {
      Map<Permission, PermissionStatus> status =
          await [Permission.location].request();
      if (await Permission.location.status.isGranted) {
        setState(() {
          _locationPermission = true;
        });
      }
      if (await Permission.location.isPermanentlyDenied) {
        openAppSettings();
        if (await Permission.location.status.isGranted) {
          setState(() {
            _locationPermission = true;
          });
        }
      }
    }
  }

  void _getActivityPermission() async {
    if (await Permission.activityRecognition.isGranted) {
      setState(() {
        _activityPermission = true;
      });
    } else if (await Permission.activityRecognition.isDenied) {
      Map<Permission, PermissionStatus> status =
          await [Permission.activityRecognition].request();
      if (await Permission.activityRecognition.status.isGranted) {
        setState(() {
          _activityPermission = true;
        });
      }

      if (await Permission.activityRecognition.isPermanentlyDenied) {
        openAppSettings();
        if (await Permission.activityRecognition.status.isGranted) {
          print("Location is Granted");
          setState(() {
            _activityPermission = true;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    refreshPage();
    _getLocationPermission();
    _getActivityPermission();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        final activityRecognition = FlutterActivityRecognition.instance;
        _activityStreamSubscription = activityRecognition.activityStream
            .handleError(_handleError)
            .listen(_onActivityReceive);
      },
    );
  }

  @override
  void dispose() {
    _activityStreamController.close();
    _activityStreamSubscription?.cancel();
    super.dispose();
  }

  void delete() async {
    ActivitiesDb.instance.clean();
    refreshPage();
  }

  void add() async {
    // double carb = 9.6;
    // double dist = 10.2;
    // String typeActv = 'Walk';
    // String _dateTime = DateTime.now().toString();
    //
    // this.lastActivity =
    //     await ActivitiesDb.instance.getLastActivityWhereType(typeActv);
    // this.lastId = await ActivitiesDb.instance.getLastIdWhereType(typeActv);
    // dev.log('lastId $lastId');
    // dev.log('last Activit $lastActivity');
    //dev.log('$lastId');
    // if (lastId == null && lastActivity == null) {
    //   dev.log("null fi null add");
    //   addActivity(
    //       DateFormat('EEE d MMM ').format(DateTime.now()),
    //       DateFormat(' kk:mm').format(DateTime.now()),
    //       typeActv,
    //       13.0,
    //       0.247,
    //       DateTime.now().toString());
    //   refreshPage();
    // }
    // if (DateTime.parse(_dateTime)
    //         .difference(DateTime.parse(lastActivity!.dateTime))
    //         .inMinutes <=
    //     10) {
    //   dev.log("UPDATE ");
    //   double new_carbon = lastActivity!.carbon + carb;
    //   double new_distance = lastActivity!.distance + dist;
    //   updatedActivity = ActivityModel.Activity(
    //       date: lastActivity!.date,
    //       time: lastActivity!.time,
    //       type: lastActivity!.type,
    //       carbon: new_carbon,
    //       distance: new_distance,
    //       dateTime: lastActivity!.dateTime);
    //   await ActivitiesDb.instance.update(updatedActivity!, lastId!);
    //   refreshPage();
    // } else {
    //   dev.log('add biiiida');
    //   addActivity(
    //       DateFormat('EEE d MMM ').format(DateTime.now()),
    //       DateFormat(' kk:mm').format(DateTime.now()),
    //       typeActv,
    //       13.0,
    //       0.247,
    //       DateTime.now().toString());
    //   refreshPage();
    // }

    addActivity(
        DateFormat('EEE d MMM ').format(DateTime.now()),
        DateFormat(' kk:mm').format(DateTime.now()),
        'Bicycle',
        13.0,
        0.247,
        DateTime.now().toString());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => refreshPage(),
      color: Colors.yellow,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 30,
        margin: const EdgeInsets.all(5),
        child: isLoading
            ? Container(
                padding: const EdgeInsets.only(bottom: 60),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                //  mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListView.builder(
                        itemCount: month_activities.length,
                        itemBuilder: (ctx, index) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              (month_activities[index].date ==
                                      DateFormat('EEE d MMM ')
                                          .format(DateTime.now())
                                          .toString())
                                  ? Container(
                                      alignment: Alignment.topLeft,
                                      padding: const EdgeInsets.only(
                                          top: 10, left: 20),
                                      child: const Text('Today',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)))
                                  : Container(
                                      alignment: Alignment.topLeft,
                                      padding: const EdgeInsets.only(
                                          top: 10, left: 20),
                                      child: Text(
                                          ' ${month_activities[index].date}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ))),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                elevation: 3,
                                margin: const EdgeInsets.all(5),
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                          EdgeInsets.only(left: 5, bottom: 5),
                                      child: MaterialButton(
                                        minWidth: 40,
                                        onPressed: () {},
                                        color: Colors.grey.shade200,
                                        textColor: Colors.white,
                                        padding: const EdgeInsets.all(6),
                                        // shape: RoundedRectangleBorder(
                                        //   borderRadius: BorderRadius.circular(5),
                                        // ),
                                        shape: const CircleBorder(),
                                        child: ((() {
                                          switch (
                                              month_activities[index].type) {
                                            case 'Walk':
                                              {
                                                return const Icon(
                                                  Icons.directions_walk,
                                                  color: Colors.black,
                                                  size: 30,
                                                );
                                              }
                                            case 'Running':
                                              {
                                                return const Icon(
                                                  Icons.directions_run,
                                                  color: Colors.black,
                                                  size: 30,
                                                );
                                              }
                                            case 'Bicycle':
                                              {
                                                return const Icon(
                                                  Icons.directions_bike,
                                                  color: Colors.black,
                                                  size: 30,
                                                );
                                              }
                                            case 'Car':
                                              {
                                                return const Icon(
                                                  Icons.directions_car,
                                                  color: Colors.black,
                                                  size: 30,
                                                );
                                              }
                                          }
                                        }())),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.only(
                                              left: 10, bottom: 5),
                                          child: Text(
                                            '${month_activities[index].type}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.only(
                                              left: 10, bottom: 5),
                                          child: Text(
                                            'At ${month_activities[index].time}  for ${month_activities[index].distance.toStringAsFixed(2)} km.',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.only(
                                          top: 15, bottom: 15, left: 25),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            ' ${month_activities[index].carbon.toStringAsFixed(2)} kg ',
                                            style: const TextStyle(
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text('CO²  ',
                                              style: TextStyle(
                                                fontSize: 13.0,
                                              )),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                  ),
                  // ElevatedButton(
                  //     onPressed: add,
                  //     child: Text('Add'),
                  //     style: ElevatedButton.styleFrom(onPrimary: Colors.blue)),
                  // ElevatedButton(
                  //     onPressed: delete,
                  //     child: Text('Delete'),
                  //     style: ElevatedButton.styleFrom(onPrimary: Colors.red)),
                ],
              ),
      ),
    );
  }
}
