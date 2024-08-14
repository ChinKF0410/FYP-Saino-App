import 'package:flutter/material.dart';
import 'package:saino_force/constant/routes.dart';
import 'package:saino_force/views/showQRCode_view.dart';
import 'package:saino_force/widgets/widget_support.dart';
import 'createcredential.dart';
import 'viewprofile.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  // You can replace the placeholder image URL with the actual profile picture URL
  final String _profilePictureUrl = 'https://via.placeholder.com/150';
  final String _accountName = 'John Doe'; // Replace with the actual account name

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
          "Account",
          style: AppWidget.boldTextFieldStyle(),
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        // Add padding to the Container to create space between the header and the profile picture
        padding: const EdgeInsets.only(top: 20.0), // Adjust the top padding as needed
        // Align the content to the top center of the screen
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Occupies minimum vertical space
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Profile picture
            CircleAvatar(
              backgroundImage: NetworkImage(_profilePictureUrl),
              maxRadius: 75, // Adjust the size of the profile picture
            ),
            const SizedBox(height: 14.0), // Space between profile picture and account name
            // Account name
            Text(
              _accountName,
              style: AppWidget.boldTextFieldStyle(),
            ),
            const SizedBox(height: 20.0), // Space between account name and buttons
            // Buttons
            _buildButton('View Profile', Icons.person_outline),
            const SizedBox(height: 15.0), // Space between buttons
            _buildButton('Change Details', Icons.edit),
            const SizedBox(height: 15.0), // Space between buttons
            _buildButton('Change Password', Icons.lock_outline),
            const SizedBox(height: 15.0), // Space between buttons
            _buildButton('Create Credentials', Icons.add),
            const SizedBox(height: 15.0), // Space between buttons
            _buildButton('View Created Credentials', Icons.list_alt),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add padding around the button
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          minimumSize: const Size.fromHeight(56.0), // Adjust the height of the button
        ),
        onPressed: () {
          // Handle button action
          if (text == 'Create Credentials') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateCredentialPage()),
            );
          }
          else if (text == 'View Profile') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewProfilePage()),
            );
          }
          else if (text == 'View Created Credential'){
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShowQRCodeView()),
            );
          }
          // Add other conditions for other buttons if necessary
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space between icon and text
          children: <Widget>[
            Icon(icon),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center, // Center the text within the available space
                style: AppWidget.accountStyle(), // Apply the font style to the button text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
