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



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Color.fromRGBO(3, 96, 99, 1),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              child: Text(
                'Carbon Tracker',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.topLeft,
              color: Color.fromRGBO(0, 150, 136, 1),
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
    );
  }
}
