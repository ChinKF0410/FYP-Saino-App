import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:saino_force/pages/account.dart';
import 'package:saino_force/pages/home.dart';
import 'package:saino_force/pages/scan.dart';
import 'package:saino_force/pages/search.dart';
import 'package:saino_force/pages/settings.dart';
import 'package:saino_force/widgets/widget_support.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentTabIndex = 0;

  late List<Widget> pages;
  late Home homepage;
  late Account account;
  late Scan scan;
  late Settings settings;
  late Search search;

  @override
  void initState() {
    super.initState();
    homepage = const Home();
    account = const Account();
    scan = const Scan();
    settings = const Settings();
    search = const Search();
    pages = [homepage, search, scan, account, settings];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        buttonBackgroundColor: const Color.fromARGB(255, 188, 203, 228),
        backgroundColor: Colors.white,
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        items: [
          CurvedNavigationBarItem(
            child: const Icon(Icons.home),
            label: 'Home',
            labelStyle: AppWidget.botnavStyle(),
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.search),
            label: 'Search',
            labelStyle: AppWidget.botnavStyle(),
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.qr_code_scanner),
            label: 'Scan',
            labelStyle: AppWidget.botnavStyle(),
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.account_circle),
            label: 'Account',
            labelStyle: AppWidget.botnavStyle(),
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.settings),
            label: 'Settings',
            labelStyle: AppWidget.botnavStyle(),
          ),
        ],
      ),
      body: pages[currentTabIndex],
    );
  }
}
