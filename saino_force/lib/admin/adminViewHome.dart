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
  int _selectedIndex = 0; // Track the selected tab

  // Define the pages to switch between
  static final List<Widget> _pages = <Widget>[
    AdminViewHomeContent(), // Home content
    const AdminViewAccount(),
    const EmailVerify(), // Navigate to Account page
  ];

  // Define the titles for each page
  static final List<String> _titles = <String>[
    'Home', // Title for Home tab
    'Account', // Title for Account tab
  ];

  // Handle tab switching
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex], // Display the dynamic title
          style: AppWidget.boldTextFieldStyle(),
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: _pages[_selectedIndex], // Display the selected page content
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// The content for the home page, extracted to avoid recursion
class AdminViewHomeContent extends StatelessWidget {
  const AdminViewHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
// Get screen width
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildInfoBoxWithIcon(
              context,
              Icons.description, // Use a relevant built-in icon
              'Verify Email',
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EmailVerify()),
              ),
            ),
            const SizedBox(height: 20.0), // Space between boxes
          ],
        ),
      ),
    );
  }

  // Reusable box widget with icon, label, and navigation
  static Widget _buildInfoBoxWithIcon(
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
