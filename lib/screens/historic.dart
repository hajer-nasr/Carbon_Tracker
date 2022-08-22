import 'package:carbon_tracker/widgets/historic_chart.dart';
import 'package:carbon_tracker/widgets/historic_screen.dart';
import 'package:flutter/material.dart';
import 'package:carbon_tracker/providers/activities_provider.dart';

class Historic extends StatefulWidget  {
   Historic({Key? key}) : super(key: key);

  @override
  State<Historic> createState() => _HistoricState();
}

class _HistoricState extends State<Historic> {
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
              mainAxisSize: MainAxisSize.min,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HistoricChart(),
                      //GoalsScreen(),
                      Expanded(child: HistoricScreen()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]));
  }
}
