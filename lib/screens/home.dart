import 'package:carbon_tracker/screens/today_screen.dart';
import 'package:carbon_tracker/widgets/distanceTracking.dart';
import 'package:flutter/material.dart';
import 'package:carbon_tracker/widgets/today_chart.dart';

class Home extends StatefulWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
