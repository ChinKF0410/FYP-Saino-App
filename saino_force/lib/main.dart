import 'package:flutter/material.dart';
import 'package:saino_force/constant/routes.dart';
import 'package:saino_force/services/auth/auth_service.dart';
import 'package:saino_force/views/login_view.dart';
import 'package:saino_force/views/notes_view.dart';
import 'package:saino_force/views/register_view.dart';
import 'package:saino_force/views/verifyEmail_view.dart';
import 'dart:developer' as devtools show log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        notesRoute: (context) => const NoteView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.mssql().initialize(),
      builder: (context, snapshot) {
        devtools.log("1");

        switch (snapshot.connectionState) {
          case ConnectionState.done:
            devtools.log("2");

            final user = AuthService.mssql().currentUser;
            if (user != null) {
              if (user.isEmailVerified) {
                devtools.log("3");
                return const NoteView();
              } else {
                devtools.log("4");
                return const VerifyEmailView();
              }
            } else {
              devtools.log("out");
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}
