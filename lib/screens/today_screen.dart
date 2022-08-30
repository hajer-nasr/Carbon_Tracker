import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:carbon_tracker/db/activities_db.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;
import 'package:provider/provider.dart';

import '../providers/activities_provider.dart';
import 'dart:math' show cos, sqrt, asin;

class TodayScreen extends StatefulWidget {
  TodayScreen({Key? key}) : super(key: key);

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool isLoading = false;

  List<ActivityModel.Activity>? activities;
  List<ActivityModel.Activity>? loadedActivities;

  double? _distance, _carbon;
  loc.LocationData? _startLocation, _endLocation;
  ActivityModel.Activity? lastActivity;
  ActivityModel.Activity? updatedActivity;
  DateTime? _dateTime;
  int? lastId;
  String? _activityType;
  bool _isInit = false;

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return (12742 * asin(sqrt(a)) * 1000);
  }

  Future refreshPage() async {
    setState(() => isLoading = true);
    if (_isInit) {
      activities = await Provider.of<Activities>(context, listen: false)
          .todayActivities();
    }
    this.activities = await ActivitiesDb.instance.readToday();
    setState(() {
      isLoading = false;
    });
  }

  Future addActivity(
    date,
    time,
    type,
    _distance,
    _carbon,
    dateTime,
  ) async {
    final act = ActivityModel.Activity(
      //id: 132,
      date: date,
      time: time,
      type: type,
      distance: _distance,
      carbon: _carbon,
      dateTime: dateTime,
    );
    await ActivitiesDb.instance.create(act);
  }

  final _activityStreamController = StreamController<Activity>();
  StreamSubscription<Activity>? _activityStreamSubscription;

  void _onActivityReceive(Activity activity) async {
    try {
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

              await Provider.of<Activities>(context, listen: false).add(
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
    } catch (e) {
      dev.log(e.toString());
    }
  }

  void _handleError(dynamic error) {
    dev.log('Catch Error >> $error');
  }

  @override
  void didChangeDependencies() async {
    setState(() {
      isLoading = true;
    });
    if (!_isInit) {
      loadedActivities =
          await Provider.of<Activities>(context).todayActivities();
      activities = loadedActivities!;
    }

    setState(() {
      isLoading = false;
      _isInit = true;
    });

    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    //  refreshPage();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        final activityRecognition = FlutterActivityRecognition.instance;
        _activityStreamSubscription = activityRecognition.activityStream
            .handleError(_handleError)
            .listen(_onActivityReceive);
      },
    );
  }

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

  // @override
  // void dispose() {
  //   _activityStreamController.close();
  //   _activityStreamSubscription?.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Card(
            margin: EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        padding: EdgeInsets.fromLTRB(20, 15, 15, 10),
                        child: Text('History',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w500))),
                    Container(
                        padding: EdgeInsets.fromLTRB(15, 15, 20, 10),
                        child: Text(
                          'See all',
                          style:
                              TextStyle(color: Color(0XFF828282), fontSize: 15),
                        ))
                  ],
                ),
                Provider.of<Activities>(context).activitiesToday.isEmpty
                    ? Center(
                        child: Text(
                          'No activity detected yet !',
                          style: TextStyle(
                              fontSize: 15,
                              color: Color.fromRGBO(3, 96, 99, 1),
                              fontWeight: FontWeight.w500),
                        ),
                        heightFactor: 5,
                        widthFactor: 10,
                      )
                    : Expanded(
                        child: ListView.separated(
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 5),
                                child: Divider(
                                  color: Color.fromRGBO(224, 224, 224, 1),
                                  height: 2,
                                  thickness: 1.2,
                                ),
                              );
                            },
                            shrinkWrap: true,
                            itemCount: Provider.of<Activities>(context)
                                .activitiesToday
                                .length,
                            itemBuilder: (ctx, index) {
                              return Row(
                                // ROW KBIIIIR
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Row(
                                      // ROW ICON AND TYPE
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(
                                              left: 10, right: 15),
                                          child: MaterialButton(
                                            minWidth: 40,
                                            elevation: 0,
                                            onPressed: () {},
                                            color: Color.fromRGBO(
                                                0, 150, 136, 0.1),
                                            textColor: Colors.white,
                                            padding: const EdgeInsets.all(6),
                                            shape: const CircleBorder(),
                                            child: ((() {
                                              switch (Provider.of<Activities>(
                                                      context)
                                                  .activitiesToday[index]
                                                  .type) {
                                                case 'Walk':
                                                  {
                                                    return const Icon(
                                                      Icons
                                                          .directions_walk_outlined,
                                                      color: Color.fromRGBO(
                                                          0, 150, 136, 1),
                                                      size: 30,
                                                    );
                                                  }
                                                case 'Running':
                                                  {
                                                    return const Icon(
                                                      Icons
                                                          .directions_run_outlined,
                                                      color: Color.fromRGBO(
                                                          0, 150, 136, 1),
                                                      size: 30,
                                                    );
                                                  }
                                                case 'Bicycle':
                                                  {
                                                    return const Icon(
                                                      Icons
                                                          .directions_bike_outlined,
                                                      color: Color.fromRGBO(
                                                          0, 150, 136, 1),
                                                      size: 30,
                                                    );
                                                  }
                                                case 'Car':
                                                  {
                                                    return const Icon(
                                                      Icons
                                                          .directions_car_outlined,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${Provider.of<Activities>(context).activitiesToday[index].type}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 18),
                                            ),
                                            Text(
                                              '${Provider.of<Activities>(context).activitiesToday[index].time} ',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0XFF828282)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Row(
                                      // ROW DISTANCE AND CARBON
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Provider.of<Activities>(context)
                                                    .activitiesToday[index]
                                                    .type ==
                                                'Walk'
                                            ? Text(
                                                '${textWalkDistance(Provider.of<Activities>(context).activitiesToday[index].distance)}',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                    fontSize: 15),
                                              )
                                            : Text(
                                                '${Provider.of<Activities>(context).activitiesToday[index].distance.toStringAsFixed(1)} km',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                    fontSize: 15),
                                              ),
                                        //     SizedBox(width: 10,),
                                        Expanded(
                                          flex: 4,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Provider.of<Activities>(context)
                                                          .activitiesToday[
                                                              index]
                                                          .type ==
                                                      'Walk'
                                                  ? Text(
                                                      ' ${textWalkCarbon(Provider.of<Activities>(context).activitiesToday[index].carbon)}',
                                                      style: const TextStyle(
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color.fromRGBO(
                                                            0, 150, 136, 1),
                                                      ),
                                                    )
                                                  : Text(
                                                      ' ${Provider.of<Activities>(context).activitiesToday[index].carbon.toStringAsFixed(2)} kg ',
                                                      style: const TextStyle(
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color.fromRGBO(
                                                            0, 150, 136, 1),
                                                      ),
                                                    ),
                                              Container(
                                                padding:
                                                    EdgeInsets.only(right: 15),
                                                child: const Text('CO²  ',
                                                    style: TextStyle(
                                                      fontSize: 14.0,
                                                    )),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.black,
                                    thickness: 10,
                                    height: 10,
                                  )
                                ],
                              );
                            }),
                      ),
              ],
            ),
          );
  }
}
