import 'dart:core';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;
import 'dart:developer' as dev;

import '../db/activities_db.dart';
//import 'dummy_data.dart';

class TodayChart extends StatefulWidget {
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

class _TodayChartState extends State<TodayChart> {
  List<ActivityModel.Activity>? activities;

  bool isLoading = false;

  var _carbonRun = 0.0;
  var _carbonBike = 0.0;
  var _carbonCar = 0.0;
  var _carbonWalk = 0.0;
  var total = 0.0;

  List<Map<String, Object?>>? list;

  Future refreshPage() async {
    setState(() => isLoading = true);
    list = await ActivitiesDb.instance.getTotal();
    double totalYear = (list![0].values.first as double);
    // dev.log('Today $totalYear');
    this.activities = await ActivitiesDb.instance.readToday();
    setState(() {
      isLoading = false;
      for (var i = 0; i < activities!.length; i++) {
        switch (activities![i].type) {
          case 'Walk':
            {
              _carbonWalk += activities![i].carbon;
            }
            break;
          case 'Running':
            {
              _carbonRun += activities![i].carbon;
            }
            break;
          case 'Bicycle':
            {
              _carbonBike += activities![i].carbon;
            }
            break;
          case 'Car':
            {
              _carbonCar += activities![i].carbon;
            }
        }
      }

      total += (_carbonRun + _carbonBike + _carbonCar + _carbonWalk);
    });
  }

  @override
  void initState() {
    super.initState();
    refreshPage();
  }

  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = [
      ChartData('Walking', _carbonWalk, const Color.fromRGBO(230, 173, 185, 1)),
      ChartData('Car', _carbonCar, const Color.fromRGBO(104, 163, 173, 1)),
      ChartData('Bicycle', _carbonBike, const Color.fromRGBO(123, 165, 248, 1)),
      ChartData('Running', _carbonRun, const Color.fromRGBO(246, 178, 119, 1))
    ];
    return Column(
      children: [
        Container(
          alignment: AlignmentDirectional.topStart,
          padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
          child: Text(
            "You have emitted ${total.toStringAsFixed(3)} kg CO2 today.",
            style: const TextStyle(
                color: Colors.white,  fontSize: 17),
          ),
        ),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//      color: Color.fromRGBO(127, 225, 212, 0.65),
          elevation: 30,
          margin: const EdgeInsets.all(18),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                    style: TextStyle(fontSize: 18),
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
                          innerRadius: '65%',
                          radius: '110%')
                    ]),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                        height: 60,
                        child: Row(
                          children: [
                            MaterialButton(
                              minWidth: 30,
                              onPressed: () {},
                              color: const Color.fromRGBO(230, 173, 185, 1),
                              textColor: Colors.white,
                              padding: const EdgeInsets.all(3),
                              shape: const CircleBorder(),
                              child: const Icon(
                                Icons.directions_walk,
                                size: 20,
                              ),
                            ),
                            //width: 100,
                            Text(
                              '${_carbonWalk.toStringAsFixed(1)} kg',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            height: 50,
                            child: MaterialButton(
                              minWidth: 30,
                              onPressed: () {},
                              color: const Color.fromRGBO(104, 163, 173, 1),
                              textColor: Colors.white,
                              padding: const EdgeInsets.all(3),
                              shape: const CircleBorder(),
                              child: const Icon(
                                Icons.directions_car,
                                size: 20,
                              ),
                            ),
                          ),
                          //width: 100,
                          Text(
                            '${_carbonCar.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            height: 30,
                            child: MaterialButton(
                              minWidth: 30,
                              onPressed: () {},
                              color: const Color.fromRGBO(123, 165, 248, 1),
                              textColor: Colors.white,
                              padding: const EdgeInsets.all(1),
                              shape: const CircleBorder(),
                              child: const Icon(
                                Icons.directions_bike,
                                size: 20,
                              ),
                            ),
                          ),
                          //width: 100,
                          Text(
                            '${_carbonBike.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 47,
                        child: Row(
                          children: [
                            MaterialButton(
                              minWidth: 30,
                              onPressed: () {},
                              color: const Color.fromRGBO(246, 178, 119, 1),
                              textColor: Colors.white,
                              padding: const EdgeInsets.all(0),
                              shape: const CircleBorder(),
                              child: const Icon(
                                Icons.directions_run,
                                size: 20,
                              ),
                            ),
                            //width: 100,
                            Text(
                              '${_carbonRun.toStringAsFixed(1)} kg',
                              style: const TextStyle(fontSize: 18),
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
// children: [
// Text('•\t\tActivity (updated: $updatedDateTime)'),
// Text('content  $content'),
// Text('Start Location : $_startLocation'),
// Text('End Location : $_endLocation'),
// Text('Distance : $_distance'),
// Text('Maaaap DistanceType : $type_distance'),
//
//
// ],
