import 'package:flutter/material.dart';
import 'package:saino_force/widgets/widget_support.dart';

class privacyAndPolicy extends StatefulWidget {
  const privacyAndPolicy({super.key});

  @override
  State<privacyAndPolicy> createState() => _privacyAndPolicyState();
}

class _privacyAndPolicyState extends State<privacyAndPolicy> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Privacy and Policy', style: AppWidget.boldTextFieldStyle()),
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
