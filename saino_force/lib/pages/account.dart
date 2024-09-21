import 'package:flutter/material.dart';
import 'package:saino_force/views/showQRCode_view.dart';
import 'package:saino_force/widgets/widget_support.dart';
import '../services/auth/MSSQLAuthProvider.dart';
import 'createcredential.dart';
import 'viewprofile.dart';
import 'dart:developer' as devtools show log;

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();
  String _profilePictureUrl = 'https://via.placeholder.com/150';
  String _accountName = "User"; // Default username if not found

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    await _authProvider.initialize(); // Ensure initialization is completed

    final user = _authProvider.currentUser;

    if (user != null) {
      devtools.log("Username: ${user.username}");

      setState(() {
        _accountName = user.username;
        // Assuming you get the profile picture URL as part of the user data
        // _profilePictureUrl = user.profilePictureUrl ?? _profilePictureUrl;
      });
    } else {
      devtools.log("No user logged in or username is null.");
    }
  }

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
        padding: const EdgeInsets.only(top: 20.0),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: NetworkImage(_profilePictureUrl),
              maxRadius: 75,
            ),
            const SizedBox(height: 14.0),
            Text(
              _accountName,
              style: AppWidget.boldTextFieldStyle(),
            ),
            const SizedBox(height: 20.0),
            _buildButton('View Profile', Icons.person_outline),
            const SizedBox(height: 15.0),
            _buildButton('Change Details', Icons.edit),
            const SizedBox(height: 15.0),
            _buildButton('Change Password', Icons.lock_outline),
            const SizedBox(height: 15.0),
            _buildButton('Create Credentials', Icons.add),
            const SizedBox(height: 15.0),
            _buildButton('View Created Credentials', Icons.list_alt),
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
        onPressed: () {
          if (text == 'Create Credentials') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateCredentialPage()),
            );
          } else if (text == 'View Profile') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewProfilePage()),
            );
          } else if (text == 'View Created Credentials') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShowQRCodeView()),
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
