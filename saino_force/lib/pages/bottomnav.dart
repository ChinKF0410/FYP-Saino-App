/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:saino_force/pages/account.dart';
import 'package:saino_force/pages/home.dart';
//import 'package:saino_force/pages/scan.dart';
//import 'package:saino_force/pages/search.dart';
import 'package:saino_force/pages/settings.dart';
import 'package:saino_force/pages/talentpage.dart';
//import 'package:saino_force/widgets/widget_support.dart';

class BottomNav extends StatefulWidget {
  final int initialIndex;

  const BottomNav({super.key, this.initialIndex = 0});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int currentTabIndex;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    currentTabIndex = widget.initialIndex;
    pages = const [
      Home(),
      TalentPage(),
      Account(),
      Settings(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Fixes shifting issue
        selectedItemColor: Colors.blue,      // Color when an item is selected
        unselectedItemColor: Colors.grey,    // Color when an item is not selected
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Talent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
