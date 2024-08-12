import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saino_force/constant/routes.dart';
import 'package:saino_force/services/auth/auth_service.dart';
import 'package:saino_force/views/login_view.dart';
import 'package:saino_force/views/notes_view.dart';
import 'package:saino_force/views/register_view.dart';
import 'package:saino_force/pages/account.dart';
import 'package:saino_force/pages/bottomnav.dart';
import 'package:saino_force/pages/search.dart';
import 'package:saino_force/pages/settings.dart';
import 'package:saino_force/providers/credential_details.dart';
import 'package:saino_force/screens/credential.dart';
import 'dart:developer' as devtools show log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CredentialDetails(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: homeRoute,
        routes: {
          homeRoute: (context) => const HomePage(),
          bottomNavRoute: (context) => const BottomNav(),
          loginRoute: (context) => const LoginView(),
          registerRoute: (context) => const RegisterView(),
          notesRoute: (context) => const NoteView(),
          searchRoute: (context) => const Search(),
          accountRoute: (context) => const Account(),
          settingsRoute: (context) => const Settings(),
          credentialRoute: (context) => const Credential(), // New Credential route
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: AuthService.mssql().initialize(),
        builder: (context, snapshot) {
          devtools.log("1");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            devtools.log("2");

            final user = AuthService.mssql().currentUser;
            if (user != null && user.email.isNotEmpty) {
              devtools.log(user.username);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  bottomNavRoute,
                  (route) => false,
                );
              });
              return const SizedBox.shrink(); // Return an empty widget as the navigation is in progress
            } else {
              devtools.log("out");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (route) => false,
                );
              });
              return const SizedBox.shrink(); // Return an empty widget as the navigation is in progress
            }
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Error initializing the app'),
            );
          } else {
            return const Center(
              child: Text('Something went wrong!'),
            );
          }
        },
      ),
    );
  }
}
