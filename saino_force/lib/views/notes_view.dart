import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;
import 'package:saino_force/constant/routes.dart';
import 'package:saino_force/enums/menu_action.dart';
import 'package:saino_force/services/auth/auth_service.dart';

class NoteView extends StatefulWidget {
  const NoteView({super.key});

  @override
  State<NoteView> createState() => _NoteViewState();
}

class _NoteViewState extends State<NoteView> {
  String qrCodeImageBase64 =
      "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";

  void _showQRCode() async {
    try {
      devtools.log("Decoding base64 string...");
      final decodedBytes = base64Decode(qrCodeImageBase64);
      devtools.log("Base64 string decoded successfully");

      if (decodedBytes.isEmpty) {
        throw Exception('Decoded image data is empty');
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('QR Code'),
            content: Image.memory(decodedBytes),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      devtools.log('Error displaying QR Code: $e');
      await showInvalidQRCodeDialog();
    }
  }

  Future<void> showInvalidQRCodeDialog() async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invalid QR Code'),
          content: const Text('The QR code image is invalid.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main UI'),
        backgroundColor: const Color.fromARGB(255, 43, 42, 42),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    await _logOut(); // Call the logOut method
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (_) => false,
                    );
                    showLogoutSuccessDialog(context);
                  }
                  devtools.log(shouldLogout.toString());
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem<MenuAction>(
                    value: MenuAction.logout, child: Text('Log Out')),
              ];
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showQRCode,
              child: const Text('Show QR Code'),
            ),
            const SizedBox(height: 20),
            const Text('Hello World'),
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

  Future<bool> showLogOutDialog(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are You Sure You Want To Sign Out?'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Log Out')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'))
            ],
          );
        }).then((value) => value ?? false);
  }

  void showLogoutSuccessDialog(BuildContext context) {
    Future.delayed(Duration.zero, () {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Logged Out'),
            content: const Text('You have successfully logged out.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }
}