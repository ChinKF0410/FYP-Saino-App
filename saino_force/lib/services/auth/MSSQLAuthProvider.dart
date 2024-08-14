import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'auth_user.dart';
import 'auth_exception.dart';
import 'dart:developer' as devtools show log;
import 'package:shared_preferences/shared_preferences.dart';

class MSSQLAuthProvider implements AuthProvider {
  final String baseUrl = "http://10.0.2.2:3000/api";
  //final String baseUrl = "http://127.0.0.1:3000/api";

  AuthUser? _currentUser;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw GenericAuthException();
      }

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

      devtools
          .log('Login API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        _currentUser = AuthUser(
          id: responseData['id'],
          username: responseData['username'],
          email: email,
        );

        await _saveUserToPreferences(_currentUser!);
        return _currentUser!;
      } else if (response.statusCode == 404) {
        throw UserNotFoundAuthException();
      } else if (response.statusCode == 401) {
        throw WrongPasswordAuthException();
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log(email);
      devtools.log('Login Error: $e');
      throw GenericAuthException();
    }
  }

  Future<void> _saveUserToPreferences(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
  }

  @override
  Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
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

      devtools.log(
          'Register API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _currentUser = AuthUser(
          id: responseData['id'],
          username: responseData['username'],
          email: email,
        );
        await _saveUserToPreferences(_currentUser!);
        return _currentUser!;
      } else if (response.statusCode == 400) {
        throw EmailAlreadyInUseAuthException();
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Register Error: $e');
      throw GenericAuthException();
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await _clearUserFromPreferences();
  }

  Future<void> _clearUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<void> initialize() async {
    _currentUser = await _getUserFromPreferences();
  }

  Future<AuthUser?> _getUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final username = prefs.getString('username');
    final email = prefs.getString('email');

    if (userId != null && username != null && email != null) {
      return AuthUser(
        id: userId,
        username: username,
        email: email,
      );
    }
    return null;
  }

  Future<Map<String, dynamic>?> generateQRCode({
    required String userID,
    required String perID,
    required String eduBacID,
    required String cerID,
    required String intelID,
    required String workExpID,
  }) async {
    try {
      final qrData = {
        'userID': userID,
        'PerID': perID,
        'EduBacID': eduBacID,
        'CerID': cerID,
        'IntelID': intelID,
        'WorkExpID': workExpID,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/generate-qrcode'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(qrData),
      );

      devtools.log(
          'Generate QRCode API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        devtools.log('QR Code Hash: ${responseData['qrHash']}');
        devtools.log('QR Code Image Base64: ${responseData['qrCodeImage']}');
        return responseData;
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Generate QRCode Error: $e');
      throw GenericAuthException();
    }
  }

  Future<Map<String, dynamic>?> searchQRCode(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search-qrcode'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'qrHashCode': qrCode,
        }),
      );

      devtools.log(
          'Search QRCode API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Search QRCode Error: $e');
      throw GenericAuthException();
    }
  }
}
