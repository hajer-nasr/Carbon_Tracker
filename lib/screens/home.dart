import 'package:carbon_tracker/screens/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:carbon_tracker/widgets/today_chart.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _activityPermission = false;
  bool _locationPermission = false;

  void _getLocationPermission() async {
    var status = await Permission.location.status;
    if (await Permission.location.status.isGranted) {
      setState(() {
        _locationPermission = true;
        // print(_locationPermission);
        // print(_activityPermission);
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

  void _getActivityPermission() async {
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

  @override
  void initState() {
    super.initState();
    _getLocationPermission();
    _getActivityPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Carbon Tracker"),
          elevation: 0,
        ),
        body: ListView(children: [
          Container(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height,
                  alignment: Alignment.topLeft,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(3, 96, 99, 1),
                      Color.fromRGBO(3, 96, 99, 0.8)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomRight,
                    stops: [0, 0.8],
                  )),
                  //height: 2000,
                  child: Column(
                    children: [
                      TodayChart(),
                      Expanded(child: TodayScreen()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]));
  }
}
