import 'package:flutter/material.dart';

class termsAndCondition extends StatefulWidget {
  const termsAndCondition({super.key});

  @override
  State<termsAndCondition> createState() => _termsAndConditionState();
}

class _termsAndConditionState extends State<termsAndCondition> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to the previous screen
          },
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
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
