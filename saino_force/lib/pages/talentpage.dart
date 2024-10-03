import 'package:flutter/material.dart';
import 'package:saino_force/pages/scan.dart';
import 'package:saino_force/pages/search.dart';
import 'package:saino_force/widgets/widget_support.dart';

class TalentPage extends StatelessWidget {
  const TalentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Talent Page', style: AppWidget.boldTextFieldStyle()),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0), // Add vertical padding to the body
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Scan QR Code Button
              _buildOptionButton(
                context,
                title: 'Scan QR Code',
                icon: Icons.qr_code_scanner,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Scan()),
                  );
                },
              ),
              const SizedBox(height: 20.0), // Space between buttons
              // Search Talent Button
              _buildOptionButton(
                context,
                title: 'Search CVs',
                icon: Icons.search,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Search()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    double screenWidth = MediaQuery.of(context).size.width; // Get screen width

    return Container(
      width: screenWidth * 0.9, // Set width to 90% of the screen width
      height: 90.0, // Set a fixed height
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2.0), // Border color and width
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
        color: Colors.transparent, // Background color
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0), // Padding for the icon
              child: Icon(
                icon,
                size: 40.0, // Larger icon size
                color: const Color(0xFF171B63), // Icon color
              ),
            ),
            const SizedBox(width: 20.0), // Space between icon and text
            Expanded( // Make text expand to fill remaining space
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20.0, // Font size for text
                  color: Color(0xFF171B63), // Text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
