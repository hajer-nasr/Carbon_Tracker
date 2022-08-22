import 'package:carbon_tracker/screens/goals_screen.dart';
import 'package:carbon_tracker/screens/historic.dart';

import 'package:carbon_tracker/screens/home.dart';
import 'package:carbon_tracker/widgets/historic_chart.dart';

import 'package:flutter/material.dart';

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
      {
        'page': HistoricChart(),
        'title': 'Goals',
      },
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
    return Scaffold(
      body:
          IndexedStack(index:_selectedPageIndex , children: [Home(), Historic()
          , GoalsScreen()
          ],),
   //   _pages[_selectedPageIndex]['page'] as Widget,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).primaryColor,
        currentIndex: _selectedPageIndex,
        selectedFontSize: 16,
        unselectedFontSize: 13,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Track'),
          BottomNavigationBarItem(
              icon: Icon(Icons.trending_down), label: 'Historic'),
          BottomNavigationBarItem(
              icon: Icon(Icons.track_changes), label: 'Goals'),
        ],
      ),
    );
  }
}
