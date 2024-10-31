/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:saino_force/constant/routes.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';
import 'dart:developer' as devtools show log;

class AdminViewAccount extends StatefulWidget {
  const AdminViewAccount({super.key});

  @override
  State<AdminViewAccount> createState() => _AdminViewAccountState();
}

class _AdminViewAccountState extends State<AdminViewAccount> {
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();

  // Add mounted check flag
  bool _isMounted = true;

  @override
  void dispose() {
    // Set the mounted flag to false when the widget is disposed
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // First Box: Logout
              Builder(
                builder: (BuildContext context) {
                  return _buildInfoBoxWithIcon(
                    context, // Pass BuildContext
                    Icons.logout_outlined, // IconData
                    'Logout', // Label
                    _showLogoutConfirmationDialog, // Callback
                  );
                },
              ),
              const SizedBox(height: 20.0), // Space between boxes
            ],
          ),
        ),
      ),
    );
  }

  // Reusable box widget with icon, label, and navigation
  Widget _buildInfoBoxWithIcon(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    double screenWidth = MediaQuery.of(context).size.width; // Get screen width

    return Container(
      width: screenWidth * 0.9, // Set width to 90% of screen width
      height: 90.0,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.transparent,
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(
                icon,
                size: 45.0, // Adjust size as needed
                color: const Color(0xFF171B63),
              ),
            ),
            const SizedBox(width: 20.0), // Space between icon and text
            Text(
              label,
              style: const TextStyle(
                fontSize: 20.0,
                color: Color(0xFF171B63),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logOut() async {
    try {
      await _authProvider.logout();
      devtools.log('Logout successful');

      // Ensure navigation only if the widget is still mounted
      if (_isMounted) {
        Navigator.of(context).pushReplacementNamed(
          loginRoute,
        );
      }
    } catch (e) {
      devtools.log('Logout Error: $e');
      throw Exception('Failed to log out');
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to Logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _logOut(); // Call the logOut method
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
