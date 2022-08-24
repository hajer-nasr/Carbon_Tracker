import 'dart:core';
import 'dart:async';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;
import 'dart:developer' as dev;

import '../db/activities_db.dart';
import '../providers/activities_provider.dart';

class HistoricChart extends StatefulWidget with ChangeNotifier {
  HistoricChart({Key? key}) : super(key: key);

  @override
  State<HistoricChart> createState() => _HistoricChartState();
}

class ChartData {
  ChartData(this.x, this.y);

  final String x;
  final double? y;
}

class _HistoricChartState extends State<HistoricChart> with ChangeNotifier {
  void _handleError(dynamic error) {
    dev.log('Catch Error >> $error');
  }

  @override
  void dispose() {
    _activityStreamController.close();

    _activityStreamSubscription?.cancel();
    super.dispose();
  }

  final _activityStreamController = StreamController<Activity>();
  StreamSubscription<Activity>? _activityStreamSubscription;

  void _onActivityReceive(Activity activity) async {
    refreshPage();
  }

  List<ActivityModel.Activity>? activities;
  List<Map<String, Object?>>? list;

  bool isLoading = false;

  var _totalJan = 0.0;
  var _totalFev = 0.0;
  var _totalMars = 0.0;
  var _totalAvr = 0.0;
  var _totalMay = 0.0;
  var _totalJun = 0.0;
  var _totalJul = 0.0;
  var _totalAout = 0.0;
  var _totalSep = 0.0;
  var _totalOct = 0.0;
  var _totalNov = 0.0;

  var _totalDec = 0.0;
  var totalYear = 0.0;

  double total_last_month = 0.0;
  double total_this_month = 0.0;
  double taux = 0.0;
  String? string_taux;
  String? sign;
  int monthNb = DateTime.now().month;

  Future refreshPage() async {
    setState(() => isLoading = false);
    _totalJan = 0.0;
    _totalFev = 0.0;
    _totalMars = 0.0;
    _totalAvr = 0.0;
    _totalMay = 0.0;
    _totalJun = 0.0;
    _totalJul = 0.0;
    _totalAout = 0.0;
    _totalSep = 0.0;
    _totalOct = 0.0;
    _totalNov = 0.0;
    _totalDec = 0.0;
    totalYear = 0.0;

    list = await ActivitiesDb.instance.getTotal();
    if (list![0].values.first != null) {
      totalYear = (list![0].values.first as double);
    }
    // dev.log('$totalYear');
    this.activities = await ActivitiesDb.instance.readAll();
    setState(() {
      for (int i = 0; i < activities!.length; i++) {
        DateTime activityDate = DateTime.parse(activities![i].dateTime);
        if (activityDate.month == DateTime.now().month - 1) {
          total_last_month += activities![i].carbon;
        }
        if (activityDate.month == DateTime.now().month) {
          total_this_month += activities![i].carbon;
        }
      }

      if (total_this_month != 0.0 && total_last_month != 0.0) {
        taux =
            (((total_this_month - total_last_month) / total_last_month) * 100);
      } else if (total_last_month == 0.0) {
        taux = total_this_month;
      }
      if (taux > 0) {
        sign = '+';
        var value = taux.toStringAsFixed(2);
        string_taux = sign! + value;
      } else if (taux < 0) {
        sign = '';
        var value = taux.toStringAsFixed(2);
        string_taux = sign! + value;
      } else if (taux == 0) {
        string_taux = null;
      }
      isLoading = false;

      for (var i = 0; i < activities!.length; i++) {
        switch (DateTime.parse(activities![i].dateTime).month) {
          case 1:
            {
              _totalJan += activities![i].carbon;
            }
            break;
          case 2:
            {
              _totalFev += activities![i].carbon;
            }
            break;
          case 3:
            {
              _totalMars += activities![i].carbon;
            }
            break;
          case 4:
            {
              _totalAvr += activities![i].carbon;
            }
            break;
          case 5:
            {
              _totalMay += activities![i].carbon;
            }
            break;
          case 6:
            {
              _totalJun += activities![i].carbon;
            }
            break;
          case 7:
            {
              _totalJul += activities![i].carbon;
            }
            break;
          case 8:
            {
              _totalAout += activities![i].carbon;
            }
            break;
          case 9:
            {
              _totalSep += activities![i].carbon;
            }
            break;
          case 10:
            {
              _totalOct += activities![i].carbon;
            }
            break;
          case 11:
            {
              _totalNov += activities![i].carbon;
            }
            break;
          case 12:
            {
              _totalDec += activities![i].carbon;
            }
            break;
        }
      }
    });
  }

  @override
  void initState() {
    refreshPage();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        final activityRecognition = FlutterActivityRecognition.instance;
        _activityStreamSubscription = activityRecognition.activityStream
            .handleError(_handleError)
            .listen(_onActivityReceive);
      },
    );
    _trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipSettings: const InteractiveTooltip(
          textStyle: TextStyle(color: Colors.transparent),
          color: Colors.transparent),
      activationMode: ActivationMode.singleTap,
      lineColor: Colors.transparent,
    );
    tooltipBehavior = TooltipBehavior(
        enable: true,
        color: Colors.red,
        shouldAlwaysShow: true,
        borderColor: Colors.yellow);
    super.initState();
  }

  TooltipBehavior? tooltipBehavior;
  TrackballBehavior? _trackballBehavior;

  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = <ChartData>[
      ChartData('Jan', _totalJan),
      ChartData('Feb', _totalFev),
      ChartData('Mar', _totalMars),
      ChartData('Apr', _totalAvr),
      ChartData('May', _totalMay),
      ChartData('Jun', _totalJun),
      ChartData('Jul', _totalJul),
      ChartData('Aug', _totalAout),
      ChartData('Sep', _totalSep),
      ChartData('Oct', _totalOct),
      ChartData('Nov', _totalNov),
      ChartData('Dec', _totalDec)
    ];
    return isLoading
        ? Container(
            padding: const EdgeInsets.all(70),
            child: const Center(child: CircularProgressIndicator()),
          )
        : Column(
            children: [
              Container(
                alignment: AlignmentDirectional.topStart,
                padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
                child: const Text(
                  "My  footprint ",
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
              Container(
                alignment: AlignmentDirectional.topStart,
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 10),
                child: Row(
                  children: [
                    Text("${totalYear.toStringAsFixed(3)} ",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 45,
                            fontWeight: FontWeight.bold)),
                    const Text('kg CO²/ year.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        )),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.fromLTRB(25, 0, 0, 10),
                child: Row(
                  children: [
                    string_taux != null
                        ? sign == '+'
                            ? const Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 20,
                              )
                            : const Icon(
                                Icons.trending_down,
                                color: Colors.white,
                                size: 20,
                              )
                        : Icon(Icons.trending_neutral_sharp,size:0),
                    (string_taux != null
                        ? Text("  $string_taux% per month",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ))
                        : Text("No data found. ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            )))
                  ],
                ),
              ),
              Container(
                  height: 200,
                  child: SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      trackballBehavior: _trackballBehavior,
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                      ),
                      onTrackballPositionChanging: (TrackballArgs args) =>
                          trackball(args).toString(),
                      plotAreaBackgroundColor: Colors.transparent,
                      plotAreaBorderColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      primaryXAxis: CategoryAxis(
                        labelPlacement: LabelPlacement.onTicks,
                        edgeLabelPlacement: EdgeLabelPlacement.shift,
                        isVisible: true,
                        majorGridLines: const MajorGridLines(width: 0),
                        interval: 1.2,
                        labelStyle:
                            const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      primaryYAxis: NumericAxis(
                          minimum: -2,
                          labelFormat: '{value} Kg',
                          majorTickLines: const MajorTickLines(size: 0),
                          labelStyle: const TextStyle(
                              color: Colors.transparent, fontSize: 0),
                          //  isVisible: false,
                          majorGridLines: const MajorGridLines(
                              width: 0.5, dashArray: [3, 10]),
                          axisLine: const AxisLine(width: 0)),
                      series: <ChartSeries>[
                        SplineSeries<ChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (ChartData data, _) => data.x,
                            yValueMapper: (ChartData data, _) => data.y,
                            color: Colors.white,
                            name: "",
                            enableTooltip: true,
                            markerSettings: const MarkerSettings(
                              isVisible: true,
                              width: 6,
                              color: Colors.tealAccent,
                              borderColor: Colors.tealAccent,
                            ),
                            width: 3)
                      ])),
            ],
          );
  }

  trackball(TrackballArgs args) {
    String? trackPosition = args.chartPointInfo.header;
    switch (trackPosition!) {
      case 'Jan':
        {
          monthNb = 1;
        }
        break;
      case 'Feb':
        {
          monthNb = 2;
        }
        break;
      case 'Mar':
        {
          monthNb = 3;
        }
        break;
      case 'Apr':
        {
          monthNb = 4;
        }
        break;

      case 'May':
        {
          monthNb = 5;
        }
        break;
      case 'Jun':
        {
          monthNb = 6;
        }
        break;
      case 'Jul':
        {
          monthNb = 7;
        }
        break;
      case 'Aug':
        {
          monthNb = 8;
        }
        break;

      case 'Sep':
        {
          monthNb = 9;
        }
        break;
      case 'Oct':
        {
          monthNb = 10;
        }
        break;
      case 'Nov':
        {
          monthNb = 11;
        }
        break;
      case 'Dec':
        {
          monthNb = 12;
        }
        break;
    }
    Provider.of<Activities>(context, listen: false).setMonthActivities(monthNb);
  }
}
