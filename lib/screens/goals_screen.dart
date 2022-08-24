import 'dart:async';
import 'dart:developer' as dev;
import 'package:carbon_tracker/providers/activities_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:location_distance_calculator/location_distance_calculator.dart';
import 'package:carbon_tracker/db/activities_db.dart';
import 'package:carbon_tracker/models/activity.dart' as ActivityModel;
import 'package:provider/provider.dart';

class GoalsScreen extends StatefulWidget with ChangeNotifier {
  GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool isLoading = false;

  ActivityModel.Activity? lastActivity;
  ActivityModel.Activity? updatedActivity;
  List<ActivityModel.Activity>? month_activities;
  List<ActivityModel.Activity>? loadedActivities;

  int? lastId;

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
      loadedActivities =
          await Provider.of<Activities>(context).MonthActivities(DateTime.now().month);
    //  dev.log('${loadedActivities}');
      month_activities = loadedActivities;
    }

    setState(() {
      isLoading = false;
      _isInit = true;
    });

    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(
            padding: const EdgeInsets.only(bottom: 60),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Column(
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
                                      padding: const EdgeInsets.only(
                                          left: 10, bottom: 5),
                                      child: Text(
                                        '${Provider.of<Activities>(context).activitiesMonth[index].type}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.only(
                                          left: 10, bottom: 5),
                                      child: Text(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        ' ${Provider.of<Activities>(context).activitiesMonth[index].carbon.toStringAsFixed(2)} kg ',
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
                          ],
                        ),
                      );
                    }),
              ),

            ],
          );
  }
}
