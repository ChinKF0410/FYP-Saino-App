import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/auth_service.dart';
import 'package:saino_force/widgets/widget_support.dart';
import 'package:saino_force/constant/routes.dart'; // Ensure this import for the loginRoute
import 'dart:developer' as devtools show log;

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        title: Text(
          "Settings",
          style: AppWidget.boldTextFieldStyle(),
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 20.0),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "General",
              style: AppWidget.boldTextFieldStyle(),
            ),
            const SizedBox(height: 20.0),
            _buildButton('Notifications', Icons.notifications_outlined),
            const SizedBox(height: 15.0),
            _buildButton('Feedback', Icons.feedback_outlined),
            const SizedBox(height: 15.0),
            _buildButton('Help & Support', Icons.help_outline),
            const SizedBox(height: 15.0),
            _buildButton('About Us', Icons.info_outline),
            const SizedBox(height: 20.0),
            Text(
              "Legal",
              style: AppWidget.boldTextFieldStyle(),
            ),
            const SizedBox(height: 20.0),
            _buildButton('Privacy & Policy', Icons.policy_outlined),
            const SizedBox(height: 15.0),
            _buildButton('Terms & Conditions', Icons.access_alarm),
            const SizedBox(height: 15.0),
            _buildButton('Logout', Icons.logout_outlined, _showLogoutConfirmationDialog),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, [VoidCallback? onPressed]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          minimumSize: const Size.fromHeight(56.0),
        ),
        onPressed: onPressed ?? () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: AppWidget.accountStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _logOut() async {
    try {
      await AuthService.mssql().logout();
      devtools.log('Logout successful');
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (_) => false,
                ); // Navigate to the login page
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
