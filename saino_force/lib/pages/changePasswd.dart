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
//import 'package:saino_force/constant/routes.dart';
import 'dart:developer' as devtools show log;
import 'package:saino_force/widgets/widget_support.dart';

class ChangePasswdView extends StatefulWidget {
  const ChangePasswdView({super.key});

  @override
  State<ChangePasswdView> createState() => _ChangePasswdViewState();
}

class _ChangePasswdViewState extends State<ChangePasswdView> {
  late final TextEditingController _oldPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    super.initState();
    devtools.log("ChangePasswdView - initState called");
  }

  @override
  void dispose() {
    devtools.log("ChangePasswdView - dispose called");
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Function to validate password strength
  bool _isValidPassword(String password) {
    // Password must be at least 8 characters long
    if (password.length < 8) {
      return false;
    }

    // Regular expression for password validation
    // At least 1 uppercase, 1 lowercase, 1 digit, and 1 special character (@ or _)
    final RegExp passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[@_])(?=.*\d).{8,}$',
    );

    return passwordRegex.hasMatch(password);
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Check if new passwords match
    if (newPassword != confirmPassword) {
      await showErrorDialog(
        context,
        'New passwords do not match',
      );
      return;
    }

    // Validate new password
    if (!_isValidPassword(newPassword)) {
      await showErrorDialog(
        context,
        'Password must be at least 8 characters, contain a symbol (@ or _), one uppercase letter, and one lowercase letter',
      );
      return;
    }

    try {
      await _authProvider.initialize(); // Ensure initialization is completed

      final user = _authProvider.currentUser;
      if (user == null) {
        await showErrorDialog(
          context,
          'User not logged in',
        );
        return;
      }

      devtools.log("Attempting to change password for ${user.email}");

      // Verify old password
      final isValid = await _authProvider.verifyPassword(
        email: user.email,
        password: oldPassword,
      );

      if (!isValid) {
        devtools.log('Old password is incorrect');
        await showErrorDialog(
          context,
          'Old password is incorrect',
        );
        return;
      }

      // Save new password
      await _authProvider.changePassword(
        email: user.email,
        oldPassword: oldPassword, // Include oldPassword here
        newPassword: newPassword,
      );

      devtools.log('Password changed successfully');
      // Use showErrorDialog to display success message
      await showErrorDialog(
        context,
        'Password changed successfully',
      );

      // Go back to the previous page when the dialog is closed
      Navigator.of(context).pop();
    } on GenericAuthException {
      await showErrorDialog(
        context,
        'Password change failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    devtools.log("Building ChangePasswdView Widget");
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
            
          },
        ),
        title: Text(
          "Change Password",
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
                controller: _oldPasswordController,
                labelText: 'Old Password',
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: _isOldPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isOldPasswordVisible = !_isOldPasswordVisible;
                  });
                }),
            const SizedBox(height: 20.0),
            _buildTextField(
              controller: _newPasswordController,
              labelText: 'New Password',
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _isNewPasswordVisible,
              toggleVisibility: () {
                setState(() {
                  _isNewPasswordVisible = !_isNewPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 20.0),
            _buildTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _isConfirmPasswordVisible,
              toggleVisibility: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 20.0),
            _buildButton('Save', Icons.save_outlined, _changePassword),
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
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.visiblePassword,
        enableSuggestions: false,
        autocorrect: false,
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
