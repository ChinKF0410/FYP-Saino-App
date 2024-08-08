import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/auth_service.dart';
import 'package:saino_force/services/auth/auth_exception.dart';
import 'dart:developer' as devtools show log;
import 'package:saino_force/utilities/show_error_dialog.dart';
import 'package:saino_force/constant/routes.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _confirmEmail;
  late final TextEditingController _password;

  @override
  void initState() {
    _username = TextEditingController();
    _email = TextEditingController();
    _confirmEmail = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _confirmEmail.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])').hasMatch(password)) {
      return 'Password must contain at least one uppercase and one lowercase letter';
    }
    return null;
  }

  Future<void> _register() async {
    final username = _username.text;
    final email = _email.text;
    final confirmEmail = _confirmEmail.text;
    final password = _password.text;

    if (email != confirmEmail) {
      await showErrorDialog(context, 'Email addresses do not match.');
      return;
    }

    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      await showErrorDialog(context, passwordError);
      return;
    }

    try {
      await AuthService.mssql().register(
        username: username,
        email: email,
        password: password,
      );


    } on WeakPasswordAuthException {
      devtools.log('Weak password');
      await showErrorDialog(context, 'Weak password');
    } on EmailAlreadyInUseAuthException {
      devtools.log('Email already in use');
      await showErrorDialog(context, 'Email already in use');
    } on GenericAuthException {
      await showErrorDialog(context, 'Registration Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: const Color.fromARGB(255, 43, 42, 42),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Username:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextField(
                controller: _username,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextField(
                controller: _email,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirm Email:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextField(
                controller: _confirmEmail,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Password:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextField(
                controller: _password,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute,
                    (_) => false,
                  );
                },
                child: const Text('Already Registered? Login Here.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
