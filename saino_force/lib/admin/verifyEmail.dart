import 'package:flutter/material.dart';

class EmailTry extends StatefulWidget {
  const EmailTry({super.key});

  @override
  State<EmailTry> createState() => _EmailTryState();
}

class _EmailTryState extends State<EmailTry> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Home Page')),
    const Center(child: Text('Account Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
            255, 188, 203, 228), // Set the background color for the AppBar
        elevation: 0,
        title: const Text(
          "Email TRY PAGE",
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
    );
  }
}
