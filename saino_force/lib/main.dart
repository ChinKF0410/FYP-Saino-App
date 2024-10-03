import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saino_force/admin/adminViewHome.dart';
import 'package:saino_force/constant/routes.dart';
import 'package:saino_force/pages/changePasswd.dart';
import 'package:saino_force/pages/scan.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart'; // Import MSSQLAuthProvider directly
import 'package:saino_force/views/login_view.dart';
// import 'package:saino_force/views/notes_view.dart';
import 'package:saino_force/views/register_view.dart';
import 'package:saino_force/pages/account.dart';
import 'package:saino_force/pages/bottomnav.dart';
import 'package:saino_force/pages/search.dart';
import 'package:saino_force/pages/settings.dart';
import 'package:saino_force/providers/credential_details.dart';
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
          // notesRoute: (context) => const NotesView(),
          searchRoute: (context) => const Search(),
          accountRoute: (context) => const Account(),
          settingsRoute: (context) => const Settings(),
          scanRoute: (context) => const Scan(),
          changePasswdRoute: (context) => const ChangePasswdView(),
          adminPageRoute: (context) => const AdminViewHomeContent(),
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final MSSQLAuthProvider authProvider =
        MSSQLAuthProvider(); // Directly use MSSQLAuthProvider

    return Scaffold(
      body: FutureBuilder(
        future:
            authProvider.initialize(), // Call initialize on MSSQLAuthProvider
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            final user = authProvider
                .currentUser; // Access currentUser from MSSQLAuthProvider

            if (user != null && user.email.isNotEmpty) {
              devtools.log(user.toString());
              if (user.roleID == 2) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    bottomNavRoute,
                    (route) => false,
                  );
                });
                return const SizedBox.shrink();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const AdminViewHome(),
                    ),
                    (Route<dynamic> route) =>
                        false, // This removes all previous routes
                  );
                });
                return const SizedBox.shrink();
              }
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (route) => false,
                );
              });
              return const SizedBox.shrink();
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
