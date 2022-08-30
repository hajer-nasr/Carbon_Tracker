import 'package:carbon_tracker/screens/home.dart';
import 'package:carbon_tracker/widgets/tabs_screen.data.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Color.fromRGBO(3, 96, 99, 1)
    ));
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        initialRoute: "/",
        theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch()
                .copyWith(primary: Color.fromRGBO(3, 96, 99, 1))),
        routes: {
          "/": (BuildContext context) {
            return (TabScreen());
          },
        });
  }
}
