import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/auth_service.dart';
import 'package:saino_force/services/auth/auth_exception.dart';
import 'dart:developer' as devtools show log;
import 'package:saino_force/utilities/show_error_dialog.dart';
import 'package:saino_force/constant/routes.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
    devtools.log("ABC - initState called");
  }

  @override
  void dispose() {
    devtools.log("DEF - dispose called");
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text;
    final password = _password.text;
    devtools.log("Trying to log in with email: $email");

    try {
      await AuthService.mssql().login(
        email: email,
        password: password,
      );

      final user = AuthService.mssql().currentUser;
      devtools.log(user.toString());
      if (user != null) {
        if (user.isEmailVerified) {
          devtools.log('Login successful');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil(
            notesRoute, // replace 'notesRoute' with your actual route name for notes
            (route) => false, // Removes all previous routes
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            verifyEmailRoute,
            (route) => false,
            arguments: user.email, // Pass the email as argument
          );
        }
      } else {
        devtools.log('Login failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed')),
        );
      }
    } on UserNotFoundAuthException {
      devtools.log('User Not Found');
      await showErrorDialog(
        context,
        'User Not Found',
      );
    } on WrongPasswordAuthException {
      devtools.log('Wrong Password');
      await showErrorDialog(
        context,
        'Wrong Credentials',
      );
    } on GenericAuthException {
      await showErrorDialog(
        context,
        'Authentication Error.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    devtools.log("Building LoginView Widget");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color.fromARGB(255, 43, 42, 42),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            decoration: const InputDecoration(hintText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            enableSuggestions: false,
            autocorrect: false,
          ),
          TextField(
            controller: _password,
            decoration: const InputDecoration(hintText: 'Password'),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
          ),
          const SizedBox(
            height: 16,
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                registerRoute,
                (route) => false,
              );
            },
            child: const Text('Not Yet Registered?'),
          ),
        ],
      ),
    );
  }
}
