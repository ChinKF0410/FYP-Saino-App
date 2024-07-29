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
      body: const Text('Hello World'),
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
