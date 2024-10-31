/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart'; // Import MSSQLAuthProvider directly
import 'package:saino_force/services/auth/auth_exception.dart';
import 'package:saino_force/utilities/show_error_dialog.dart';
import 'package:saino_force/constant/routes.dart';
import 'dart:developer' as devtools show log;
import 'package:saino_force/widgets/widget_support.dart';
import 'package:saino_force/admin/adminViewHome.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();

    // Automatically log out when this page is initialized (i.e., when user lands on the login page)
    _logoutUser();

    super.initState();
    devtools.log("LoginView - initState called");
  }

  Future<void> _logoutUser() async {
    // Log out user to reset any previous session
    await _authProvider.logout();
    devtools.log("User automatically logged out when accessing login page");
  }

  @override
  void dispose() {
    devtools.log("LoginView - dispose called");
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _login() async {
    final email = _email.text;
    final password = _password.text;
    devtools.log("Trying to log in with email: $email");

    try {
      int response = await _authProvider.login(
        email: email,
        password: password,
      );
      if (!mounted) return;

      await _authProvider.initialize();
      if (!mounted) return;
      final user = _authProvider.currentUser;

      devtools.log(user.toString());
      devtools.log("Response Status Code: $response");

      if (response == 402) {
        // Email not verified
        devtools.log('Email not verified');
        showErrorDialog(
            context,
            "Email Hasn't Been Verified, Please Contact Us: \n"
            "- Email to sainocs@sainoforce.com\n"
            "- WhatsApp to 011-12345678");
        return;
      } else if (response == 403) {
        // Registration rejected
        devtools.log('Account registration rejected');
        showErrorDialog(
            context,
            "Account Registration Was Rejected. Please Contact Us: \n"
            "- Email to sainocs@sainoforce.com\n"
            "- WhatsApp to 011-12345678");
        return;
      } 
      devtools.log(user!.roleID.toString());
      if (user?.roleID == 1) {
        // Admin login
        devtools.log('Admin login successful');
        showErrorDialog(
          context,
          "Logged in as admin successfully. Welcome to the Admin Dashboard.",
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminViewHome(),
          ),
          (Route<dynamic> route) => false, // Removes all previous routes
        );
        return;
      } else if (user?.roleID == 2) {
        // Regular user login
        devtools.log('User login successful');
        Navigator.of(context).pushNamedAndRemoveUntil(
          bottomNavRoute,
          (route) => false,
        );
        return;
      }

      // If the response status doesn't match any of the expected ones, handle as failed login
      devtools.log('Login failed with unexpected status code');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
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
        'Invalid Email or Password.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    devtools.log("Building LoginView Widget");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Login",
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
              controller: _email,
              labelText: 'Email Address',
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
            _buildButton('Login', Icons.login_outlined, _login),
            const SizedBox(height: 15.0),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  registerRoute,
                  (_) => false,
                );
              },
              child: const Text(
                'Not Yet Registered? Register Here.',
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
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                )
              : null,
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
