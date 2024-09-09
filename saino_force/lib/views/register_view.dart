import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart'; // Import MSSQLAuthProvider directly
import 'package:saino_force/services/auth/auth_exception.dart';
import 'dart:developer' as devtools show log;
import 'package:saino_force/utilities/show_error_dialog.dart';
import 'package:saino_force/constant/routes.dart';
import 'package:saino_force/widgets/widget_support.dart';

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
  late final TextEditingController _confirmPassword;
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider(); // Directly use MSSQLAuthProvider

  @override
  void initState() {
    _username = TextEditingController();
    _email = TextEditingController();
    _confirmEmail = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _confirmEmail.dispose();
    _password.dispose();
    _confirmPassword.dispose();
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
    final confirmPassword = _confirmPassword.text;

    if (email != confirmEmail) {
      await showErrorDialog(context, 'Email addresses do not match.');
      return;
    }

    if (password != confirmPassword) {
      await showErrorDialog(context, 'Passwords do not match.');
      return;
    }

    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      await showErrorDialog(context, passwordError);
      return;
    }

    try {
      await _authProvider.register(
        username: username,
        email: email,
        password: password,
      );

      Navigator.of(context).pushNamedAndRemoveUntil(
        homeRoute,
        (_) => false,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        title: Text(
          "Register",
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
            _buildTextField(
              controller: _username,
              labelText: 'Username',
              icon: Icons.person_outline,
              isPassword: false,
            ),
            const SizedBox(height: 20.0),
            _buildTextField(
              controller: _email,
              labelText: 'Email Address',
              icon: Icons.email_outlined,
              isPassword: false,
            ),
            const SizedBox(height: 20.0),
            _buildTextField(
              controller: _confirmEmail,
              labelText: 'Confirm Email',
              icon: Icons.email_outlined,
              isPassword: false,
            ),
            const SizedBox(height: 20.0),
            _buildTextField(
              controller: _password,
              labelText: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 20.0),
            _buildTextField(
              controller: _confirmPassword,
              labelText: 'Confirm Password',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 20.0),
            _buildButton('Register', Icons.app_registration_outlined, _register),
            const SizedBox(height: 15.0),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (_) => false,
                );
              },
              child: const Text(
                'Already Registered? Login Here.',
                style: TextStyle(fontSize: 14, color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required bool isPassword,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: isPassword
            ? TextInputType.visiblePassword
            : TextInputType.emailAddress,
        enableSuggestions: !isPassword,
        autocorrect: !isPassword,
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          minimumSize: const Size.fromHeight(56.0),
        ),
        onPressed: onPressed,
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
