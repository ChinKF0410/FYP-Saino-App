/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:saino_force/widgets/widget_support.dart';

class helpAndSupport extends StatefulWidget {
  const helpAndSupport({super.key});

  @override
  _helpAndSupportState createState() => _helpAndSupportState();
}

class _helpAndSupportState extends State<helpAndSupport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help and Support', style: AppWidget.boldTextFieldStyle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to the previous screen
          },
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'This is an empty page',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
