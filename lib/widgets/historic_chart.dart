import 'dart:core';
import 'dart:async';
import 'package:carbon_tracker/widgets/historic_screen.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  List<ActivityModel.Activity>? activities;
  List<Map<String, Object?>>? listTotal;
  List<Map<String, Object?>>? listWalk;

  bool isLoading = false;

  double taux = 0.0;
  String? string_taux;
  String? sign;
  int monthNb = DateTime.now().month;
  bool _isInit = false;
  String title = DateFormat('yMMMM').format(DateTime.now()).toString();

  @override
  void didChangeDependencies() async {
    setState(() {
      isLoading = true;
    });
    if (!_isInit) {
      var loadedActivities =
          await Provider.of<Activities>(context, listen: false).allActivities();
      taux = await Provider.of<Activities>(context, listen: false).tauxFunc();
      await Provider.of<Activities>(context, listen: false).totalMonths();

      activities = loadedActivities;
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
    }
    setState(() {
      isLoading = false;
      _isInit = true;
    });

    super.didChangeDependencies();
  }

  // Future refreshPage() async {
  //   setState(() => isLoading = false);
  //
  //   if (_isInit) {
  //     activities =
  //         await Provider.of<Activities>(context, listen: false).allActivities();
  //     taux = await Provider.of<Activities>(context, listen: false).tauxFunc();
  //     await Provider.of<Activities>(context, listen: false).totalMonths();
  //
  //     isLoading = false;
  //   }
  //   ;
  // }

  @override
  void initState() {
    _trackballBehavior = TrackballBehavior(
      shouldAlwaysShow: true,
        enable: true,
        tooltipSettings: const InteractiveTooltip(
            textStyle: TextStyle(color: Colors.transparent),
            color: Colors.transparent),
        activationMode: ActivationMode.singleTap,
        lineColor: Colors.transparent,
        markerSettings: TrackballMarkerSettings(
            color: Colors.transparent,
            markerVisibility: TrackballVisibilityMode.visible,
            borderColor: Colors.transparent));
    tooltipBehavior = TooltipBehavior(

      enable: true,
      shouldAlwaysShow: true,
    );
    super.initState();
  }

  TooltipBehavior? tooltipBehavior;
  TrackballBehavior? _trackballBehavior;

  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = <ChartData>[
      ChartData(
          'Jan', Provider.of<Activities>(context, listen: false).totalJan),
      ChartData(
          'Feb', Provider.of<Activities>(context, listen: false).totalFev),
      ChartData(
          'Mar', Provider.of<Activities>(context, listen: false).totalMar),
      ChartData(
          'Apr', Provider.of<Activities>(context, listen: false).totalAvr),
      ChartData(
          'May', Provider.of<Activities>(context, listen: false).totalMay),
      ChartData(
          'Jun', Provider.of<Activities>(context, listen: false).totalJun),
      ChartData(
          'Jul', Provider.of<Activities>(context, listen: false).totalJul),
      ChartData(
          'Aug', Provider.of<Activities>(context, listen: false).totalAout),
      ChartData(
          'Sep', Provider.of<Activities>(context, listen: false).totalSep),
      ChartData(
          'Oct', Provider.of<Activities>(context, listen: false).totalOct),
      ChartData(
          'Nov', Provider.of<Activities>(context, listen: false).totalNov),
      ChartData('Dec', Provider.of<Activities>(context, listen: false).totalDec)
    ];
    return isLoading
        ? Container(
            padding: const EdgeInsets.all(70),
            child: const Center(child: CircularProgressIndicator()),
          )
        : Card(
            color: Colors.teal,
            margin: EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25))),
            child: Container(
              child: Column(
                children: [
                  Container(
                    alignment: AlignmentDirectional.center,
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: const Text(
                      "My footprint ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    alignment: AlignmentDirectional.topStart,
                    padding: const EdgeInsets.fromLTRB(25, 0, 20, 10),
                    child: Row(
                      // ROW KBIIR LOUL
                      children: [
                        Expanded(
                          flex: 7,
                          child: Row(
                            // ROW TOTAL PER YEAR
                            children: [
                              Column(
                                children: [
                                  Text(
                                      "${Provider.of<Activities>(context).totalYear.toStringAsFixed(2)} ",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold)),
                                  Container(
                                    alignment: Alignment.topLeft,
                                    child: const Text('per year',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        )),
                                  ),
                                ],
                              ),
                              const Text('KG CO²',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  )),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 8,
                          child: Row(
                            // ROW TAUX VARIATION PER MONTH
                            children: [
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
                                child: Row(
                                  children: [
                                    Provider.of<Activities>(context,
                                                    listen: false)
                                                .taux !=
                                            0.0
                                        ? Provider.of<Activities>(context,
                                                        listen: false)
                                                    .taux >
                                                0
                                            ? SizedBox(
                                                width: 25,
                                                child: MaterialButton(
                                                  onPressed: () {},
                                                  color:
                                                      const Color(0xFF6BD35A),
                                                  textColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.all(3),
                                                  shape: const CircleBorder(),
                                                  child: const Icon(
                                                    Icons.trending_up,
                                                    size: 20,
                                                  ),
                                                ),
                                              )
                                            : SizedBox(
                                                width: 25,
                                                child: MaterialButton(
                                                  onPressed: () {},
                                                  color:
                                                      const Color(0xFF6BD35A),
                                                  textColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.all(3),
                                                  shape: const CircleBorder(),
                                                  child: const Icon(
                                                    Icons.trending_down,
                                                    size: 20,
                                                  ),
                                                ),
                                              )
                                        : Icon(Icons.trending_neutral_sharp,
                                            size: 0),
                                    (Provider.of<Activities>(context,
                                                    listen: false)
                                                .taux !=
                                            0.0
                                        ? Column(
                                            children: [
                                              Provider.of<Activities>(context, listen: false).taux ==
                                                      0.0
                                                  ? (Text("${Provider.of<Activities>(context, listen: false).taux.toStringAsFixed(1)}% ",
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.w500)))
                                                  : Provider.of<Activities>(context,
                                                                  listen: false)
                                                              .taux >
                                                          0
                                                      ? (Text(
                                                          " + ${Provider.of<Activities>(context, listen: false).taux.toStringAsFixed(1)}% ",
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500)))
                                                      : (Text(
                                                          "  ${Provider.of<Activities>(context, listen: false).taux.toStringAsFixed(1)}% ",
                                                          style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 26,
                                                              fontWeight: FontWeight.w500))),
                                              Container(
                                                alignment: Alignment.bottomLeft,
                                                child: const Text('per month',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    )),
                                              ),
                                            ],
                                          )
                                        : Text("No data found. ",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            )))
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Card(
                    margin: EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25))),
                    child: Column(
                      children: [
                        Card(
                          margin: EdgeInsets.all(10),
                          color: Color.fromRGBO(220, 232, 231, 1),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          child: Container(
                              height: 180,
                              child: SfCartesianChart(
                                  plotAreaBorderWidth: 0,
                                  trackballBehavior: _trackballBehavior,
                                  tooltipBehavior: TooltipBehavior(
                                    enable: true,
                                  ),
                                  onTrackballPositionChanging:
                                      (TrackballArgs args) =>
                                          trackball(args).toString(),
                                  plotAreaBackgroundColor: Colors.transparent,
                                  plotAreaBorderColor: Colors.transparent,
                                  borderColor: Colors.transparent,
                                  primaryXAxis: CategoryAxis(
                                    labelPlacement: LabelPlacement.betweenTicks,
                                    isVisible: true,
                                    majorGridLines:
                                        const MajorGridLines(width: 0),
                                    interval: 1,
                                    labelStyle: const TextStyle(
                                        color: Color.fromRGBO(0, 150, 136, 1),
                                        fontSize: 13),
                                  ),
                                  primaryYAxis: NumericAxis(
                                      minimum: -0.02,
                                      labelFormat: '{value} Kg',
                                      majorTickLines:
                                          const MajorTickLines(size: 0),
                                      labelStyle: const TextStyle(
                                          color: Colors.transparent,
                                          fontSize: 0),
                                      majorGridLines: const MajorGridLines(
                                          width: 0.5, dashArray: [3, 10]),
                                      axisLine: const AxisLine(width: 0)),
                                  series: <ChartSeries>[
                                    SplineSeries<ChartData, String>(
                                        dataSource: chartData,
                                        xValueMapper: (ChartData data, _) =>
                                            data.x,
                                        yValueMapper: (ChartData data, _) =>
                                            data.y,
                                        color: Color.fromRGBO(0, 150, 136, 1),
                                        name: "",
                                        enableTooltip: true,
                                        markerSettings: const MarkerSettings(
                                          isVisible: true,
                                          width: 7,
                                          height: 8,
                                          color:
                                              Color.fromRGBO(220, 232, 231, 1),
                                          borderColor:
                                              Color.fromRGBO(0, 150, 136, 1),
                                        ),
                                        width: 3)
                                  ])),
                        ),

                        //       Expanded(child: HistoricScreen()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
