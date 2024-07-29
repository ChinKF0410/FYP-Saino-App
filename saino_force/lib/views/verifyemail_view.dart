import 'package:flutter/material.dart';
import 'package:saino_force/ApiService.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final String email = "user@example.com"; // This should be replaced with the actual user email from the currentUser object

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Email'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Text("We've sent an email verification to $email. Please check your inbox and click the link to verify."),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              bool result = await _apiService.sendVerificationEmail(email);
              if (result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Verification email sent successfully.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send verification email.')),
                );
              }
            },
            child: Text('Resend Verification Email'),
          ),
        ],
      ),
    );
  }
}
