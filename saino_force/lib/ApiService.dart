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

  Future<bool> registerUser(
      String username, String email, String password) async {
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

  Future<Map<String, dynamic>?> generateQRCode(
      Map<String, String> qrData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-qrcode'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(qrData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        devtools
            .log("QR Code generated successfully: ${responseData['qrHash']}");
        return responseData;
      } else {
        devtools.log("Failed to generate QR Code: ${response.body}");
        return null;
      }
    } catch (e) {
      devtools.log('Caught error: $e');
      return null;
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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        devtools.log("QR Code data retrieved successfully");
        return responseData;
      } else {
        devtools.log("Failed to retrieve QR Code data: ${response.body}");
        return null;
      }
    } catch (e) {
      devtools.log('Caught error: $e');
      return null;
    }
  }

  // Updated function for searching talent
  Future<List<Map<String, dynamic>>> searchTalent({
    required String searchType, // "education" or "skills"
    required String searchQuery,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search-talent'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'searchType': searchType.toUpperCase(),
          'searchQuery': searchQuery.toUpperCase(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData != null && responseData.isNotEmpty) {
          return List<Map<String, dynamic>>.from(responseData);
        } else {
          return []; // No matching talent found
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Search Talent Error: $e');
      throw Exception('An error occurred while searching for talent.');
    }
  }

  // New function to fetch detailed information based on UserID
  Future<Map<String, dynamic>?> fetchTalentDetails(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/showDetails'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'userID': userId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        devtools.log("Talent details retrieved successfully");
        return responseData;
      } else {
        devtools.log("Failed to retrieve talent details: ${response.body}");
        return null;
      }
    } catch (e) {
      devtools.log('Caught error: $e');
      return null;
    }
  }
}
