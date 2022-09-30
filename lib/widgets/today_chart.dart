import 'dart:async';
import 'dart:core';

import 'package:carbon_tracker/providers/activities_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;
import 'dart:developer' as dev;
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/activities_db.dart';
import 'package:permission_handler/permission_handler.dart';

class TodayChart extends StatefulWidget with ChangeNotifier {
  TodayChart({Key? key}) : super(key: key);

  @override
  State<TodayChart> createState() => _TodayChartState();
}

class ChartData {
  ChartData(this.x, this.y, [this.color]);

  final String x;
  final double y;
  final Color? color;
}

class _TodayChartState extends State<TodayChart> with ChangeNotifier {
  bool _activityPermission = false;
  bool _locationPermission = false;

  Future<void> _getActivityPermission() async {
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

  Future<void> _getLocationPermission() async {
    var status = await Permission.location.status;
    if (await Permission.location.status.isGranted) {
      setState(() {
        _locationPermission = true;
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

  void askPermissions() async {
    await _getLocationPermission();
    await _getActivityPermission();
    print(_activityPermission);
    print(_locationPermission);
  }

  @override
  void initState() {
    super.initState();
    askPermissions();
  }

  List<ActivityModel.Activity>? activities;
  List<ActivityModel.Activity>? actv;

  bool isLoading = false;
  bool isInit = false;

  var total = 0.0;

  @override
  void didChangeDependencies() async {
    setState(() {
      isLoading = true;
    });

    if (!isInit) {
      Provider.of<Activities>(context).updateValues();
    }

    setState(() {
      isLoading = false;
      isInit = true;
    });

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = [
      ChartData('Walking', Provider.of<Activities>(context).carbonWalk,
          const Color.fromRGBO(32, 181, 186, 1)),
      ChartData('Car', Provider.of<Activities>(context).carbonCar,
          const Color.fromRGBO(26, 114, 133, 1)),
      ChartData('Bicycle', Provider.of<Activities>(context).carbonBike,
          const Color.fromRGBO(82, 219, 206, 1)),
      ChartData('Running', Provider.of<Activities>(context).carbonRun,
          const Color.fromRGBO(32, 130, 186, 1))
    ];
    return Column(
      children: [
        Container(
            alignment: AlignmentDirectional.topCenter,
            padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
            child: RichText(
              text: TextSpan(
                text: "You have emitted  ",
                style: const TextStyle(color: Colors.white, fontSize: 17),
                children: <TextSpan>[
                  TextSpan(
                      text:
                          '${Provider.of<Activities>(context).total.toStringAsFixed(3)} kg',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' CO2 today.'),
                ],
              ),
            )),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 10,
          margin: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 0, 0),
                  alignment: AlignmentDirectional.topStart,
                  child: const Text(
                    'FootPrint Per category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  )),
              Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 0, 0),
                  alignment: AlignmentDirectional.topStart,
                  child: const Text(
                    'Your daily emissions per category ',
                    style: TextStyle(fontSize: 14, color: Color(0XFF828282)),
                  )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 160,
                    height: 200,
                    padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                    child: SfCircularChart(series: <CircularSeries>[
                      // Renders doughnut chart
                      DoughnutSeries<ChartData, String>(
                          dataSource: chartData,
                          pointColorMapper: (ChartData data, _) => data.color,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          dataLabelMapper: (ChartData data, _) => data.x,
                          innerRadius: '60%',
                          radius: '100%')
                    ]),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                        height: 70,
                        child: SizedBox(
                          width: 130,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              SizedBox(
                                height: 50,
                                child: MaterialButton(
                                  minWidth: 38,
                                  height: 50,
                                  onPressed: () {},
                                  color: const Color(0xFF20B5BA),
                                  textColor: Colors.white,
                                  padding: const EdgeInsets.all(3),
                                  shape: const CircleBorder(),
                                  child: const Icon(
                                    Icons.directions_walk,
                                    size: 26,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Walk',
                                    style: TextStyle(
                                      color: Color(0xFF828282),
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${Provider.of<Activities>(context).carbonWalk.toStringAsFixed(1)} KG',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF20B5BA),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              height: 60,
                              child: MaterialButton(
                                minWidth: 38,
                                onPressed: () {},
                                color: const Color(0XFF1A7285),
                                textColor: Colors.white,
                                padding: const EdgeInsets.all(3),
                                shape: const CircleBorder(),
                                child: const Icon(
                                  Icons.directions_car,
                                  size: 26,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Drive',
                                  style: TextStyle(
                                    color: Color(0xFF828282),
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${Provider.of<Activities>(context).carbonCar.toStringAsFixed(1)} KG',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0XFF1A7285),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              height: 47,
                              child: MaterialButton(
                                minWidth: 38,
                                onPressed: () {},
                                color: const Color.fromRGBO(82, 219, 206, 1),
                                textColor: Colors.white,
                                padding: const EdgeInsets.all(3),
                                shape: const CircleBorder(),
                                child: const Icon(
                                  Icons.directions_bike,
                                  size: 26,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bicycle',
                                  style: TextStyle(
                                    color: Color(0xFF828282),
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${Provider.of<Activities>(context).carbonBike.toStringAsFixed(1)} KG',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        const Color.fromRGBO(82, 219, 206, 1),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              height: 55,
                              child: MaterialButton(
                                minWidth: 38,
                                onPressed: () {},
                                color: const Color.fromRGBO(32, 130, 186, 1),
                                textColor: Colors.white,
                                padding: const EdgeInsets.all(3),
                                shape: const CircleBorder(),
                                child: const Icon(
                                  Icons.directions_run,
                                  size: 26,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jogging',
                                  style: TextStyle(
                                    color: Color(0xFF828282),
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${Provider.of<Activities>(context).carbonRun.toStringAsFixed(1)} KG',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        const Color.fromRGBO(32, 130, 186, 1),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
