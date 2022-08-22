// import 'dart:async';
// import 'dart:developer' as dev;
// import 'package:carbon_tracker/widgets/dummy_data.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:location/location.dart' as loc;
// import 'package:intl/intl.dart';
// import 'package:location_distance_calculator/location_distance_calculator.dart';
// import 'package:carbon_tracker/db/activities_db.dart';
// import 'package:carbon_tracker/models/activity.dart' as ActivityModel;
//
// class ExampleApp extends StatefulWidget {
//   ExampleApp({Key? key}) : super(key: key);
//
//   @override
//   State<ExampleApp> createState() => _ExampleAppState();
// }
//
// class _ExampleAppState extends State<ExampleApp> {
//   List<ActivityModel.Activity>? activities;
//
//   bool isLoading = false;
//
//   Future refreshPage() async {
//     setState(() => isLoading = true);
//     this.activities = await ActivitiesDb.instance.readToday();
//
//     setState(() => isLoading = false);
//   }
//
//   String? _activityType, _date, _time;
//
//   bool _activityPermission = false;
//   bool _locationPermission = false;
//   double? _distance;
//   String? _dist;
//   loc.LocationData? _startLocation, _endLocation;
//
//   Map<String, Map<double, String>> type_distance = {};
//
//   final _activityStreamController = StreamController<Activity>();
//   StreamSubscription<Activity>? _activityStreamSubscription;
//
//   Future addActivity(
//     date,
//     time,
//     type,
//     _distance,
//     carbon,
//       dateTime,
//   ) async {
//     final act = ActivityModel.Activity(
//       //id: 132,
//       date: date,
//       time: time,
//       type: type,
//       distance: _distance,
//       carbon: carbon,
//         dateTime:dateTime,
//     );
//     await ActivitiesDb.instance.create(act);
//   }
//
//   void _onActivityReceive(Activity activity) async {
//     dev.log('Activity Detected >> ${activity.toJson()}');
//     _activityStreamController.sink.add(activity);
//
//     if (_startLocation == null) {
//       var startLoc = await loc.Location().getLocation();
//
//       setState(() {
//         _startLocation = startLoc;
//         dev.log('Start Location >> $_startLocation');
//       });
//     }
//     if (_startLocation != null) {
//       var actType;
//       _endLocation = await loc.Location().getLocation();
//
//       try {
//         _distance = await LocationDistanceCalculator().distanceBetween(
//             _startLocation!.latitude!,
//             _startLocation!.longitude!,
//             _endLocation!.latitude!,
//             _endLocation!.longitude!);
//         if (activity.toJson()['type'].toString().contains('.WALKING') ||
//             activity.toJson()['type'].toString().contains('UNKNOWN')) {
//           actType = 'Walk';
//         } else if (activity
//             .toJson()['type']
//             .toString()
//             .contains('ON_BICYCLE')) {
//           actType = 'Bicycle';
//         } else if (activity
//             .toJson()['type']
//             .toString()
//             .contains('IN_VEHICLE')) {
//           actType = 'Car';
//         } else if (activity.toJson()['type'].toString().contains('RUNNING')) {
//           actType = 'Running';
//         } else if (activity.toJson()['type'].toString().contains('STILL')) {
//           actType = 'STILL';
//         }
//         dev.log('End Location >> $_endLocation');
//       } on PlatformException {
//         _distance = -1.0;
//       }
//       setState(() {
//         _date = DateFormat('EEE d MMM ').format(DateTime.now());
//         _time = DateFormat(' kk:mm').format(DateTime.now());
//         _activityType = actType;
//
//       });
//       if (_activityType != 'STILL') {
//         addActivity(_date, _time, _activityType, _distance, 0.0,DateTime.now());
//         refreshPage();
//       }
//       dev.log('Distance ${_distance.toString()}');
//       dev.log('Activity Type $_activityType');
//     }
//   }
//
//   void _handleError(dynamic error) {
//     dev.log('Catch Error >> $error');
//   }
//
//   void _getLocationPermission() async {
//     var status = await Permission.location.status;
//     if (await Permission.location.status.isGranted) {
//       setState(() {
//         _locationPermission = true;
//         print(_locationPermission);
//         print(_activityPermission);
//       });
//     } else if (await Permission.location.status.isDenied) {
//       Map<Permission, PermissionStatus> status =
//           await [Permission.location].request();
//       if (await Permission.location.status.isGranted) {
//         setState(() {
//           _locationPermission = true;
//         });
//       }
//       if (await Permission.location.isPermanentlyDenied) {
//         openAppSettings();
//         if (await Permission.location.status.isGranted) {
//           setState(() {
//             _locationPermission = true;
//           });
//         }
//       }
//     }
//   }
//
//   void _getActivityPermission() async {
//     if (await Permission.activityRecognition.isGranted) {
//       setState(() {
//         _activityPermission = true;
//       });
//     } else if (await Permission.activityRecognition.isDenied) {
//       Map<Permission, PermissionStatus> status =
//           await [Permission.activityRecognition].request();
//       if (await Permission.activityRecognition.status.isGranted) {
//         setState(() {
//           _activityPermission = true;
//         });
//       }
//
//       if (await Permission.activityRecognition.isPermanentlyDenied) {
//         openAppSettings();
//         if (await Permission.activityRecognition.status.isGranted) {
//           print("Location is Granted");
//           setState(() {
//             _activityPermission = true;
//           });
//         }
//       }
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     refreshPage();
//     _getLocationPermission();
//     _getActivityPermission();
//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) async {
//         final activityRecognition = FlutterActivityRecognition.instance;
//         _activityStreamSubscription = activityRecognition.activityStream
//             .handleError(_handleError)
//             .listen(_onActivityReceive);
//         //       print('Map Type $type_distance');
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _activityStreamController.close();
//
//     _activityStreamSubscription?.cancel();
//     super.dispose();
//   }
//
//   void delete() async {
//     ActivitiesDb.instance.clean();
//     refreshPage();
//   }
//
//   void add() async {
//     addActivity(DateFormat('EEE d MMM ').format(DateTime.now()),
//         DateFormat(' kk:mm:ss').format(DateTime.now()), 'Walk', 1.3, 0.0);
//     refreshPage();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return
//       isLoading
//           ? Center(child: CircularProgressIndicator())
//           :
//       Card(
//       //color: Color.fromRGBO(224, 255, 255, 1),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 30,
//       margin: const EdgeInsets.all(5),
//       child: Column(
//         children: [
//           Container(
//               height: 350,
//               width: double.infinity,
//               child: ListView.builder(
//                   itemCount: activities?.length,
//                   itemBuilder: (ctx, index) {
//                     return Card(
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(5)),
//                             elevation: 3,
//                             margin: const EdgeInsets.all(5),
//                             child: Row(
//                               //mainAxisAlignment: MainAxisAlignment.spaceAround,
//                               //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                               children: [
//                                 MaterialButton(
//                                   minWidth: 40,
//                                   onPressed: () {},
//                                   color: Colors.grey.shade200,
//                                   textColor: Colors.white,
//                                   padding: const EdgeInsets.all(5),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(5),
//                                   ),
//                                   child: ((() {
//                                     switch (activities?[index].type) {
//                                       case 'Walk':
//                                         {
//                                           return const Icon(
//                                             Icons.directions_walk,
//                                             color: Colors.black,
//                                             size: 30,
//                                           );
//                                         }
//                                       case 'Running':
//                                         {
//                                           return const Icon(
//                                             Icons.directions_run,
//                                             color: Colors.black,
//                                             size: 30,
//                                           );
//                                         }
//                                       case 'Bicycle':
//                                         {
//                                           return const Icon(
//                                             Icons.directions_bike,
//                                             color: Colors.black,
//                                             size: 30,
//                                           );
//                                         }
//                                       case 'Car':
//                                         {
//                                           return const Icon(
//                                             Icons.directions_car,
//                                             color: Colors.black,
//                                             size: 30,
//                                           );
//                                         }
//                                     }
//                                   }())),
//                                 ),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       ' Activity Type ${activities?[index].type}',
//                                       style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 16),
//                                     ),
//                                     Text(
//                                         'At ${activities?[index].time}  for ${activities?[index].distance.toStringAsFixed(3)} m.'),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           );
//                   })),
//           ElevatedButton(
//               onPressed: delete,
//               child: Text('Clean DataBase'),
//               style: ElevatedButton.styleFrom(primary: Colors.red)),
//           ElevatedButton(
//               onPressed: add,
//               child: Text('Add Static Daa'),
//               style: ElevatedButton.styleFrom(primary: Colors.cyan)),
//         ],
//       ),
//     );
//   }
// }
