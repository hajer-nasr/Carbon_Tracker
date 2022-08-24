import 'package:carbon_tracker/screens/exampleApp.dart';
import 'package:carbon_tracker/screens/home.dart';
import 'package:carbon_tracker/widgets/tabs_screen.data.dart';
import 'package:flutter/material.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        initialRoute: "/",
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        routes: {
          "/": (BuildContext context) {
            //return (Home());
            //  return(DistanceTracking());
         //   return (ExampleApp());
            return(TabScreen());
          },
        });
  }
}
