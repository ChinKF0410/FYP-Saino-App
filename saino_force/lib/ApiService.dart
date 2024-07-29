import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

class ApiService {
  final String baseUrl = "http://127.0.0.1:3000/api";

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        devtools.log("Login successful: ${responseData['userName']}");
        return responseData;
      } else {
        devtools.log("Failed to login: ${response.body}");
        return null;
      }
    } catch (e) {
      devtools.log('Caught error: $e');
      return null;
    }
  }

  Future<bool> registerUser(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        devtools.log("Registration successful");
        return true;
      } else {
        devtools.log("Failed to register: ${response.body}");
        return false;
      }
    } catch (e) {
      devtools.log('Caught error: $e');
      return false;
    }
  }

  Future<bool> sendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-verification-email'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        devtools.log("Verification email sent successfully");
        return true;
      } else {
        devtools.log("Failed to send verification email: ${response.body}");
        return false;
      }
    } catch (e) {
      devtools.log('Caught error: $e');
      return false;
    }
  }
}
