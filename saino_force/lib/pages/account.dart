/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:saino_force/pages/changePasswd.dart';
import 'package:saino_force/pages/credential.dart';
import 'package:saino_force/widgets/widget_support.dart';
import '../services/auth/MSSQLAuthProvider.dart';
import 'viewCredentials.dart';
import 'viewprofile.dart';
import 'dart:developer' as devtools show log;

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();
  String _accountName = "User"; // Default username if not found
  Uint8List? _profilePictureBytes; // Store profile picture as bytes

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    await _authProvider.initialize(); // Ensure initialization is completed
    final user = _authProvider.currentUser;

    if (user != null) {
      final profileData = await _authProvider.getProfile(user.id);
      if (!mounted) return;
      devtools.log("Username: ${user.username}");

      if (profileData != null) {
        if (!mounted) return;

        setState(() {
          _accountName = profileData['Nickname'];
          // Check if the profile picture exists and is not empty
          if (profileData['Photo'] != null && profileData['Photo'].isNotEmpty) {
            devtools.log('Profile picture exists, decoding...');
            _accountName = profileData['Nickname'];

            _profilePictureBytes = base64Decode(profileData['Photo']);
            _accountName = profileData['Nickname'];
          } else {
            devtools.log('No profile picture available.');
            _profilePictureBytes = null;
          }
        });
      } else {
        devtools.log("Failed to fetch profile data.");
      }
    } else {
      devtools.log("No user logged in or username is null.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Removed the leading property to remove the back button
        title: Text(
          "Account",
          style: AppWidget.boldTextFieldStyle(),
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 40.0),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: _profilePictureBytes != null
                  ? MemoryImage(_profilePictureBytes!)
                  : const NetworkImage('https://via.placeholder.com/150'),
              maxRadius: 75,
            ),
            const SizedBox(height: 14.0),
            Text(
              _accountName,
              style: AppWidget.boldTextFieldStyle(),
            ),
            const SizedBox(height: 55.0),
            _buildButton('View Profile', Icons.person_outline),
            const SizedBox(height: 20.0),
            _buildButton('Change Password', Icons.lock_outline),
            const SizedBox(height: 20.0),
            _buildButton('Create Certification', Icons.add),
            const SizedBox(height: 20.0),
            _buildButton('View Created Certifications', Icons.list_alt),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          minimumSize: const Size.fromHeight(56.0),
        ),
        onPressed: () async {
          if (text == 'Create Certification') {
            // Wait for result from Credential page
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Credential()),
            );

            // If credential was created, reinitialize the account page
            if (result == true) {
              _loadCurrentUser(); // Re-fetch user data after creating credential
            }
          } else if (text == 'View Profile') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewProfilePage()),
            );
            if (result == true) {
              _loadCurrentUser(); // Refresh user data
            }
          } else if (text == 'View Created Certifications') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HolderListPage()),
            );
          } else if (text == 'Change Password') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangePasswdView()),
            );
          }
        },
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
}
