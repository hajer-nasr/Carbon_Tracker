import 'dart:async';
import 'dart:developer' as dev;
import 'package:carbon_tracker/providers/activities_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';

import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:carbon_tracker/db/activities_db.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;
import 'package:provider/provider.dart';
import 'dart:math' show cos, sqrt, asin;
import 'historic_chart.dart';

class HistoricScreen extends StatefulWidget {
  HistoricScreen({Key? key}) : super(key: key);

  @override
  State<HistoricScreen> createState() => _HistoricScreenState();
}

class _HistoricScreenState extends State<HistoricScreen> {
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

  // Future refreshPage() async {
  //   setState(() => isLoading = true);
  //   //dev.log('$_isInit');
  //   if (_isInit) {
  //     loadedActivities = await Provider.of<Activities>(context, listen: false)
  //         .MonthActivities(DateTime.now().month);
  //   }
  //
  //   setState(() {
  //     isLoading = false;
  //   });
  // }

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
        _distance = calculateDistance(
            _startLocation!.latitude!,
            _startLocation!.longitude!,
            _endLocation!.latitude!,
            _startLocation!.longitude!);
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
        if (_activityType != 'Still' && _distance != null) {
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
        lastId = await ActivitiesDb.instance.getLastIdWhereType(_activityType!);
        // Activity Does Not Exist
        if (lastId == null && lastActivity == null) {
          Provider.of<Activities>(context, listen: false).add(
              ActivityModel.Activity(
                  date: DateFormat('EEE d MMM ').format(_dateTime!),
                  time: DateFormat(' kk:mm').format(_dateTime!),
                  type: _activityType!,
                  carbon: _carbon!,
                  distance: _distance!,
                  dateTime: _dateTime.toString()));
          setState(() {
            _startLocation = _endLocation;
          });
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
          Provider.of<Activities>(context, listen: false)
              .update(updatedActivity!, lastId!);
          setState(() {
            _startLocation = _endLocation;
          });
        }
        // Activity Exists but too far
        else {
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
              _startLocation = _endLocation;
            });
          }
        }
      }
    }
  }

  void _handleError(dynamic error) {
    print('Catch Error >> $error');
  }

  @override
  void initState() {
    super.initState();
    // refreshPage();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        final activityRecognition = FlutterActivityRecognition.instance;
        _activityStreamSubscription = activityRecognition.activityStream
            .handleError(_handleError)
            .listen(_onActivityReceive);
      },
    );
  }

  // @override
  // void dispose() {
  //   _activityStreamController.close();
  //   _activityStreamSubscription?.cancel();
  //   super.dispose();
  // }

  String? distanceWalking;
  String? carbonWalking;

  String textWalkCarbon(double walkingcarb) {
    if (walkingcarb > 1000) {
      carbonWalking = '${(walkingcarb / 1000).toStringAsFixed(2)} kg ';
    } else {
      carbonWalking = '${walkingcarb.toStringAsFixed(2)} g ';
    }
    return carbonWalking!;
  }

  String textWalkDistance(double walkingdist) {
    if (walkingdist > 1000) {
      distanceWalking = '${(walkingdist / 1000).toStringAsFixed(1)} km';
    } else {
      distanceWalking = '${walkingdist.toStringAsFixed(1)} m';
    }
    return distanceWalking!;
  }

  void delete() async {
    //for (var i = 11; i <= 12; i++)
    ActivitiesDb.instance.deleteActivity(21);
  }

  void add() {
    DateTime _dateTime = DateTime.now();
    dev.log('add');
    Provider.of<Activities>(context, listen: false).add(ActivityModel.Activity(
        date: DateFormat('EEE d MMM ').format(_dateTime),
        time: DateFormat(' kk:mm').format(_dateTime),
        type: 'Walk',
        carbon: 50,
        distance: 30,
        dateTime: _dateTime.toString()));
  }

  String SelectedMonth = DateFormat('MMMM').format(DateTime.now());

  String getSelectedMonth(int nb) {
    switch (nb) {
      case 1:
        {
          SelectedMonth = 'January';
        }
        break;
      case 2:
        {
          SelectedMonth = 'February';
        }
        break;
      case 3:
        {
          SelectedMonth = 'March';
        }
        break;
      case 4:
        {
          SelectedMonth = 'April';
        }
        break;

      case 5:
        {
          SelectedMonth = 'May';
        }
        break;
      case 6:
        {
          SelectedMonth = 'June';
        }
        break;
      case 7:
        {
          SelectedMonth = 'July';
        }
        break;
      case 8:
        {
          SelectedMonth = "November";
        }
        break;

      case 9:
        {
          SelectedMonth = 'September';
        }
        break;
      case 10:
        {
          SelectedMonth = "October";
        }
        break;
      case 11:
        {
          SelectedMonth = "November";
        }
        break;
      case 12:
        {
          SelectedMonth = "December";
        }
        break;
    }
    return SelectedMonth;
  }

  bool isEmpty = false;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(
            padding: const EdgeInsets.only(bottom: 60),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Card(
            margin: EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30))),
            child: Column(
              children: [
                // ElevatedButton(
                //     onPressed: delete,
                //     child: Text('delete'),
                //     style: ElevatedButton.styleFrom(onPrimary: Colors.blue)),
                HistoricChart(),
                Provider.of<Activities>(context).activitiesMonth.isNotEmpty
                    ? Container(
                        padding: EdgeInsets.only(bottom: 5, top: 10),
                        child: Text(
                          '${DateFormat('yMMMM').format(DateTime.parse(Provider.of<Activities>(context).activitiesMonth[0].dateTime))}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            padding: EdgeInsets.only(bottom: 5, top: 10),

                            child: Text(
                              ' ${getSelectedMonth(Provider.of<Activities>(context).nbMonth)} ${DateTime.now().year}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Center(
                            child: Text(
                              'No activity detected in this month.',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromRGBO(3, 96, 99, 1),
                                  fontWeight: FontWeight.w500),
                            ),
                            heightFactor: 8,
                            widthFactor: 10,
                          ),
                        ],
                      ),

                Expanded(
                  child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) {
                        return Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          child: Divider(
                            color: Color.fromRGBO(224, 224, 224, 1),
                            height: 2,
                            thickness: 1.2,
                          ),
                        );
                      },
                      shrinkWrap: true,
                      itemCount: Provider.of<Activities>(context)
                          .activitiesMonth
                          .length,
                      itemBuilder: (ctx, index) {
                        return Row(
                          children: [
                            Expanded(
                              flex: 8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding:
                                        EdgeInsets.only(left: 10, right: 15),
                                    child: MaterialButton(
                                      minWidth: 40,
                                      elevation: 0,
                                      onPressed: () {},
                                      color: Color.fromRGBO(0, 150, 136, 0.1),
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
                                                Icons.directions_walk_outlined,
                                                color: Color.fromRGBO(
                                                    0, 150, 136, 1),
                                                size: 30,
                                              );
                                            }
                                          case 'Running':
                                            {
                                              return const Icon(
                                                Icons.directions_run_outlined,
                                                color: Color.fromRGBO(
                                                    0, 150, 136, 1),
                                                size: 30,
                                              );
                                            }
                                          case 'Bicycle':
                                            {
                                              return const Icon(
                                                Icons.directions_bike_outlined,
                                                color: Color.fromRGBO(
                                                    0, 150, 136, 1),
                                                size: 30,
                                              );
                                            }
                                          case 'Car':
                                            {
                                              return const Icon(
                                                Icons.directions_car_outlined,
                                                color: Color.fromRGBO(
                                                    0, 150, 136, 1),
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${Provider.of<Activities>(context).activitiesMonth[index].type}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 18),
                                      ),
                                      Text(
                                        '${Provider.of<Activities>(context).activitiesMonth[index].date}',

                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0XFF828282)),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Provider.of<Activities>(context)
                                                .activitiesMonth[index]
                                                .type ==
                                            'Walk'
                                        ? Text(
                                            '${textWalkDistance(Provider.of<Activities>(context).activitiesMonth[index].distance)}',
                                            textAlign: TextAlign.right,
                                            style:
                                                const TextStyle(fontSize: 15),
                                          )
                                        : Text(
                                            '${Provider.of<Activities>(context).activitiesMonth[index].distance.toStringAsFixed(1)} km',
                                            textAlign: TextAlign.right,
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                  ],
                                )),
                            Expanded(
                              flex: 5,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Provider.of<Activities>(context)
                                              .activitiesMonth[index]
                                              .type ==
                                          'Walk'
                                      ? Text(
                                          ' ${textWalkCarbon(Provider.of<Activities>(context).activitiesMonth[index].carbon)}',
                                          style: const TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromRGBO(0, 150, 136, 1),
                                          ),
                                        )
                                      : Text(
                                          ' ${Provider.of<Activities>(context).activitiesMonth[index].carbon.toStringAsFixed(2)} kg',
                                          style: const TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromRGBO(0, 150, 136, 1),
                                          ),
                                        ),
                                  Container(
                                    padding: EdgeInsets.only(right: 15),
                                    child: const Text(' CO²',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                ),
              ],
            ),
          );
  }
}
