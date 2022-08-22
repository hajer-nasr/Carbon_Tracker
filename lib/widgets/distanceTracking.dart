// import 'dart:async';
// import 'dart:collection';
// import 'dart:developer' as dev;
// import 'package:carbon_tracker/widgets/dummy_data.dart';
// import 'package:carbon_tracker/widgets/today_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:location/location.dart' as loc;
// import 'package:intl/intl.dart';
// import 'package:location_distance_calculator/location_distance_calculator.dart';
//
// class DistanceTracking extends StatefulWidget {
//   DistanceTracking({Key? key}) : super(key: key);
//
//   @override
//   State<DistanceTracking> createState() => _DistanceTrackingState();
// }
//
// class _DistanceTrackingState extends State<DistanceTracking> {
//   String? _activityType, _dateTime;
//   bool _activityPermission = false;
//   bool _locationPermission = false;
//   double? _distance;
//
//   loc.LocationData? _startLocation, _endLocation;
//
//   Map<String, Map<double, String>> type_distance = {};
//
//   final _activityStreamController = StreamController<Activity>();
//   StreamSubscription<Activity>? _activityStreamSubscription;
//
//   void _onActivityReceive(Activity activity) {
//     dev.log('Activity Detected >> ${activity.toJson()}');
//     _activityStreamController.sink.add(activity);
//
//     if (_startLocation == null) {
//       setState(() async {
//         _startLocation = await loc.Location().getLocation();
//         dev.log('Start Location >> $_startLocation');
//       });
//     }
//     if (_startLocation != null) {
//       setState(() async {
//         _endLocation = await loc.Location().getLocation();
//         _dateTime = DateFormat('EEE d MMM kk:mm:ss').format(DateTime.now());
//         dev.log('End Location >> $_endLocation');
//         try {
//           _distance = await LocationDistanceCalculator().distanceBetween(
//               _startLocation!.latitude!,
//               _startLocation!.longitude!,
//               _endLocation!.latitude!,
//               _endLocation!.longitude!);
//           dev.log('Distance $_distance');
//           type_distance[_dateTime!] = {
//             _distance!: activity.toJson()['type'].toString()
//           };
//         } on PlatformException {
//           _distance = -1.0;
//         }
//       });
//     }
//
//     setState(() {
//       _activityType = activity.toJson()['type'].toString();
//     });
//     print(_activityType);
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
//   void initState()  {
//     super.initState();
//     _getLocationPermission();
//     _getActivityPermission();
//     // _tryMap();
//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) async {
//         final activityRecognition = FlutterActivityRecognition.instance;
//         _activityStreamSubscription = activityRecognition.activityStream
//             .handleError(_handleError)
//             .listen(_onActivityReceive);
//         print(type_distance);
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
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<Activity>(
//         stream: _activityStreamController.stream,
//         builder: (context, snapshot) {
//         //  final trackingData = DUMMY_Distance;
//           final updatedDateTime = DateTime.now();
//           final content = snapshot.data?.toJson().toString() ?? '';
//           return Card(
//             //color: Color.fromRGBO(224, 255, 255, 1),
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             elevation: 30,
//             margin: const EdgeInsets.all(5),
//
//               child: Container(
//                   height: 250,
//                   width: double.infinity,
//                   child: ListView.builder(
//                       itemCount: trackingData.length,
//                       itemBuilder: (ctx, index) {
//                         return Card(
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(5)),
//                           elevation: 3,
//                           margin: const EdgeInsets.all(5),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               MaterialButton(
//                                 minWidth: 40,
//                                 onPressed: () {},
//                                 color: Colors.grey.shade200,
//                                 textColor: Colors.white,
//                                 padding: const EdgeInsets.all(5),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(5),
//                                 ),
//                                 child: ((() {
//                                   switch (trackingData[index].type) {
//                                     case 'Walk':
//                                       {
//                                         return const Icon(
//                                           Icons.directions_walk,
//                                           color: Colors.black,
//                                           size: 30,
//                                         );
//                                       }
//                                     case 'Running':
//                                       {
//                                         return const Icon(
//                                           Icons.directions_run,
//                                           color: Colors.black,
//                                           size: 30,
//                                         );
//                                       }
//                                     case 'Bicycle':
//                                       {
//                                         return const Icon(
//                                           Icons.directions_bike,
//                                           color: Colors.black,
//                                           size: 30,
//                                         );
//                                       }
//                                     case 'Car':
//                                       {
//                                         return const Icon(
//                                           Icons.directions_car,
//                                           color: Colors.black,
//                                           size: 30,
//                                         );
//                                       }
//                                   }
//                                 }())),
//                               ),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     trackingData[index].type,
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 16),
//                                   ),
//                                   Text(
//                                       'At ${trackingData[index].time}  for ${trackingData[index].distance} km.'),
//                                 ],
//                               ),
//                               Container(
//                                 padding:
//                                     const EdgeInsets.only(top: 15, bottom: 15),
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Text(
//                                       ' ${trackingData[index].carbon.toString()} kg ',
//                                       style: const TextStyle(
//                                         fontSize: 18.0,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const Text('CO²  ',
//                                         style: TextStyle(
//                                           fontSize: 15.0,
//                                         )),
//                                   ],
//                                 ),
//                               ),
//
//                             ],
//                           ),
//                         );
//                       })),
//
//           );
//         });
//   }
// }
//
// // children: [
// // Text('•\t\tActivity (updated: $updatedDateTime)'),
// // Text('content  $content'),
// // Text('Start Location : $_startLocation'),
// // Text('End Location : $_endLocation'),
// // Text('Distance : $_distance'),
// // Text('Maaaap DistanceType : $type_distance'),
// //
// //
// // ],
