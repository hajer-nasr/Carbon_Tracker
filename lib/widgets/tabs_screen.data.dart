import 'package:carbon_tracker/screens/goals_screen.dart';
import 'package:carbon_tracker/screens/historic.dart';

import 'package:carbon_tracker/screens/home.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/activities_provider.dart';

class TabScreen extends StatefulWidget {
  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  late List<Map<String, Object>> _pages;

  int _selectedPageIndex = 0;

  @override
  void initState() {
    _pages = [
      {
        'page': Home(),
        'title': 'Track',
      },
      {
        'page': Historic(),
        'title': 'Historic',
      },
      // {
      //   'page': HistoricChart(),
      //   'title': 'Goals',
      // },
    ];
    super.initState();
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (BuildContext context) => Activities(),
      child: SafeArea(
        child: Scaffold(
          body: IndexedStack(
            index: _selectedPageIndex,
            children: [
              Home(), Historic(),
              //  GoalsScreen()
            ],
          ),
          //   _pages[_selectedPageIndex]['page'] as Widget,
          extendBody: true,
          backgroundColor: Colors.transparent,

          bottomNavigationBar: FloatingNavbar(
            margin: EdgeInsets.all(15),
            selectedBackgroundColor: Color.fromRGBO(9, 100, 103, 0.1),
            borderRadius: 30,
            onTap: _selectPage,
            backgroundColor: Colors.white,
            unselectedItemColor: Colors.grey,
            selectedItemColor: Color.fromRGBO(0, 150, 136, 1),
            currentIndex: _selectedPageIndex,
            itemBorderRadius: 30,
            elevation: 30,
            fontSize: 14,
            items: [
              FloatingNavbarItem(
                  icon: (Icons.donut_small_outlined), title: 'Track'),
              FloatingNavbarItem(
                  icon: (Icons.pending_actions_outlined), title: 'Historic'),
              // BottomNavigationBarItem(
              //     icon: Icon(Icons.track_changes), label: 'Goals'),
            ],
          ),
        ),
      ),
    );
  }
}
