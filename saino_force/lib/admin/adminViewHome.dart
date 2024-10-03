import 'package:flutter/material.dart';
import 'verifyEmail.dart';
import 'adminViewAccount.dart';
import 'package:saino_force/widgets/widget_support.dart';

class AdminViewHome extends StatefulWidget {
  const AdminViewHome({super.key});

  @override
  State<AdminViewHome> createState() => _AdminViewHomeState();
}

class _AdminViewHomeState extends State<AdminViewHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home",
          style: AppWidget.boldTextFieldStyle(),
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // First Box: View CV
              _buildInfoBoxWithIcon(
                context,
                Icons.description, // Use a relevant built-in icon
                'Verify Email',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AdminViewAccount()),
                ),
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
}
