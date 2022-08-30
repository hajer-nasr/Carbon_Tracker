import 'dart:async';
import 'dart:developer' as dev;
import 'package:carbon_tracker/providers/activities_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

import 'package:carbon_tracker/db/activities_db.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;
import 'package:provider/provider.dart';
import 'dart:math' show cos, sqrt, asin;

class GoalsScreen extends StatefulWidget {
  GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool isLoading = false;

  List<ActivityModel.Activity>? activities;
  List<ActivityModel.Activity> month_activities = [];
  List<ActivityModel.Activity> transitoires = [];
  List<ActivityModel.Activity>? loadedActivities;

  double? _distance, _carbon;
  loc.LocationData? _startLocation, _endLocation;

  ActivityModel.Activity? lastActivity;
  ActivityModel.Activity? updatedActivity;
  DateTime? _dateTime;
  int? lastId;
  String? _activityType;

  Future refreshPage() async {
    setState(() => isLoading = true);
    //dev.log('$_isInit');
    if (_isInit) {
      loadedActivities = await Provider.of<Activities>(context, listen: false)
          .MonthActivities(DateTime.now().month);
    }

    setState(() {
      isLoading = false;
    });
  }

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

  var _isInit = false;

  @override
  void didChangeDependencies() async {
    setState(() {
      isLoading = true;
    });
    if (!_isInit) {
      loadedActivities = await Provider.of<Activities>(context)
          .MonthActivities(DateTime.now().month);
      month_activities = loadedActivities!;
    }

    setState(() {
      isLoading = false;
      _isInit = true;
    });

    super.didChangeDependencies();
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return (12742 * asin(sqrt(a)) * 1000);
  }

  void _handleError(dynamic error) {
    print('Catch Error >> $error');
  }

  @override
  void initState() {
    super.initState();
    refreshPage();
  }

  // Future<void> GetAddressFromLatLong(Position position)async {
  //
  //   List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
  //   print(placemarks);
  //   Placemark place = placemarks[0];
  //   setState(()  {
  //   });
  // }

  void calcul() async {
    // _distance = calculateDistance(35.84597430514622, 10.616547641888713,
    //     35.832324436073044, 10.63681628606422);
    // dev.log('${_distance! / 1000} km ');
    //
    // dev.log(
    //     '${await placemarkFromCoordinates(35.832324436073044, 10.63681628606422)}');
  }

  double? startLat;

  double? startLong;
  double? endLat;
  double? endLong;

  void add(String typeActivity, double lat, double long) async {
    // setState(() {
    //   startLat = null;
    //   startLong = null;
    //   endLat = null;
    //   endLong = null;
    //   return;
    // });
    // return ;
    dev.log(
        'Awel medkhal lel add , StartLocation:  $startLat $startLong  EndLocation: $endLat $endLong');
    try {
      if (startLat == null && startLong == null) {
        setState(() {
          _dateTime = DateTime.now();
          startLat = lat;
          startLong = long;
          dev.log('Start Location >> $startLat $startLong');
        });
      }
      if (startLat != null && startLong != null) {
        var carb;
        setState(() {
          _dateTime = DateTime.now();
          endLat = lat;
          endLong = long;
          dev.log('End Location  $endLat $endLong');
        });
        try {
          _distance = calculateDistance(startLat, startLong, endLat, endLong);
          dev.log("DISTANCEE  ${_distance! / 1000}");
          carb = _distance! * 0.035;
          dev.log("CARB  $carb");
        } on PlatformException {
          _distance = -1.0;
        }
        setState(() {
          _activityType = typeActivity;
          if (_activityType != 'Still') {
            if (_activityType != 'Walk') {
              _distance = _distance! / 1000;
              _carbon = carb / 1000;
            }
            if (_activityType == 'Walk') {
              _distance = _distance!;
              _carbon = carb;
            }
          }
        });
        if (_activityType != 'Still' && _distance != null) {
          lastActivity = await ActivitiesDb.instance
              .getLastActivityWhereType(_activityType!);
          lastId =
              await ActivitiesDb.instance.getLastIdWhereType(_activityType!);
          // Activity Does Not Exist
          if (lastId == null && lastActivity == null) {
            dev.log("Activity Does Not Exist");
            await Provider.of<Activities>(context, listen: false).add(
                ActivityModel.Activity(
                    date: DateFormat('EEE d MMM ').format(_dateTime!),
                    time: DateFormat(' kk:mm').format(_dateTime!),
                    type: _activityType!,
                    carbon: _carbon!,
                    distance: _distance!,
                    dateTime: _dateTime.toString()));
            setState(() {
              startLat = endLat;
              startLong = endLong;
            });
          }
          // Activity Exists before 10mins
          if (_dateTime!
                  .difference(DateTime.parse(lastActivity!.dateTime))
                  .inMinutes <=
              10) {
            dev.log("Activity Exists before 10mins");
            dev.log('$startLat $startLong START POINT FEL UPDATE');
            dev.log('$endLat $endLong END POINT FEL UPDATE');

            dev.log('${lastActivity!.distance} DISTANCE LAST ACTIVITY');
            double new_carbon = lastActivity!.carbon + _carbon!;
            double new_distance = lastActivity!.distance + _distance!;
            dev.log('${_distance!} DISTANCE ACTIVITY JDIDA');
            dev.log('${new_distance} NEW DISTANCE ');

            updatedActivity = ActivityModel.Activity(
                date: lastActivity!.date,
                time: lastActivity!.time,
                type: lastActivity!.type,
                carbon: new_carbon,
                distance: new_distance,
                dateTime: lastActivity!.dateTime);
            Provider.of<Activities>(context, listen: false)
                .update(updatedActivity!, lastId!);
            setState(() {
              startLat = endLat;
              startLong = endLong;
            });
          } else {
            dev.log("Activity Exists but too far");

            if (_distance != null) {
              Provider.of<Activities>(context, listen: false).add(
                  ActivityModel.Activity(
                      date: DateFormat('EEE d MMM ').format(_dateTime!),
                      time: DateFormat(' kk:mm').format(_dateTime!),
                      type: _activityType!,
                      carbon: _carbon!,
                      distance: _distance!,
                      dateTime: _dateTime.toString()));
              setState(() {
                startLat = endLat;
                startLong = endLong;
              });
            }
          }
        }
      }
    } catch (e) {
      dev.log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: Provider.of<Activities>(context)
                  .activitiesMonth
                  .length, // month_activities?.length,
              itemBuilder: (ctx, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  elevation: 3,
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      (Provider.of<Activities>(context)
                                  .activitiesMonth[index]
                                  .date ==
                              DateFormat('EEE d MMM ')
                                  .format(DateTime.now())
                                  .toString())
                          ? Container(
                              alignment: Alignment.topLeft,
                              padding: const EdgeInsets.only(
                                  top: 5, left: 20, bottom: 5),
                              child: const Text('Today',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)))
                          : Container(
                              alignment: Alignment.topLeft,
                              padding: const EdgeInsets.only(
                                  top: 5, left: 20, bottom: 5),
                              child: Text(
                                  ' ${Provider.of<Activities>(context).activitiesMonth[index].date}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ))),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.only(left: 5, bottom: 5),
                            child: MaterialButton(
                              minWidth: 40,
                              onPressed: () {},
                              color: Colors.grey.shade200,
                              textColor: Colors.white,
                              padding: const EdgeInsets.all(6),
                              shape: const CircleBorder(),
                              child: ((() {
                                switch (Provider.of<Activities>(context)
                                    .activitiesMonth[index]
                                    .type) {
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.only(left: 10, bottom: 5),
                                child: Text(
                                  '${Provider.of<Activities>(context).activitiesMonth[index].type}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.only(left: 10, bottom: 5),
                                child: Provider.of<Activities>(context)
                                            .activitiesMonth[index]
                                            .type ==
                                        'Walk'
                                    ? Text(
                                        'At ${Provider.of<Activities>(context).activitiesMonth[index].time}  for ${Provider.of<Activities>(context).activitiesMonth[index].distance.toStringAsFixed(2)} m.',
                                        style: const TextStyle(fontSize: 13),
                                      )
                                    : Text(
                                        'At ${Provider.of<Activities>(context).activitiesMonth[index].time}  for ${Provider.of<Activities>(context).activitiesMonth[index].distance.toStringAsFixed(2)} km.',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.only(
                                top: 15, bottom: 15, left: 25),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Provider.of<Activities>(context)
                                            .activitiesMonth[index]
                                            .type ==
                                        'Walk'
                                    ? Text(
                                        ' ${Provider.of<Activities>(context).activitiesMonth[index].carbon.toStringAsFixed(2)} g ',
                                        style: const TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        ' ${Provider.of<Activities>(context).activitiesMonth[index].carbon.toStringAsFixed(2)} kg ',
                                        style: const TextStyle(
                                          fontSize: 13.0,
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
                    ],
                  ),
                );
              }),
        ),
        ElevatedButton(
            onPressed: () =>
                add('Walk', 36.8320093663, 11.69964638939339),
            child: Text('Add'),
            style: ElevatedButton.styleFrom(onPrimary: Colors.blue)),
      ],
    );
  }
}

// Satoripop :35.83209721093663, 10.63664638939339
// Monoprix : 35.84686065852373, 10.61115271593139
// Home : 35.84492457545383, 10.615619667598152
//home =>monoprix
