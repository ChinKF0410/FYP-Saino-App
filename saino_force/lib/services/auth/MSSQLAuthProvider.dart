import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saino_force/models/auth_user.dart';
import 'auth_provider.dart';
import 'auth_exception.dart';
import 'dart:developer' as devtools show log;
import 'package:shared_preferences/shared_preferences.dart';

class MSSQLAuthProvider implements AuthProvider {
  final String baseUrl = "http://192.168.1.9:3011/api";
  final String toWalletDB = "http://192.168.1.9:4000/api";

  AuthUser? _currentUser;

  @override
  Future<int> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw GenericAuthException();
      }
      devtools.log("Anything");
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
      devtools.log(response.statusCode.toString());
      devtools
          .log('Login API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _currentUser = AuthUser(
          id: responseData['id'],
          username: responseData['username'],
          email: email,
          roleID: 2,
        );

        await _saveUserToPreferences(_currentUser!);
      } else if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _currentUser = AuthUser(
          id: responseData['id'],
          username: responseData['username'],
          email: email,
          roleID: 1,
        );

        await _saveUserToPreferences(_currentUser!);
        return response.statusCode;
      } else if (response.statusCode == 402 || response.statusCode == 403) {
        return response.statusCode;
      } else if (response.statusCode == 404) {
        throw UserNotFoundAuthException();
      } else if (response.statusCode == 401) {
        throw WrongPasswordAuthException();
      } else {
        throw GenericAuthException();
      }
      throw GenericAuthException();
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
    await prefs.setInt('roleID', user.roleID);
  }

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String companyname,
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
          'companyname': companyname,
        }),
      );

      devtools.log(
          'Register API Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 201) {

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
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt('userId');
    devtools.log("Backend Working");
    devtools.log(userId.toString());
    _currentUser = await _getUserFromPreferences();
  }

  Future<AuthUser?> _getUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final username = prefs.getString('username');
    final email = prefs.getString('email');
    final roleID = prefs.getInt('roleID');

    if (userId != null && username != null && email != null && roleID != null) {
      return AuthUser(
        id: userId,
        username: username,
        email: email,
        roleID: roleID,
      );
    }
    return null;
  }

  Future<Map<String, dynamic>?> searchQRCode(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$toWalletDB/search-qrcode'),
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
        // Explicitly cast responseData to Map<String, dynamic>
        final Map<String, dynamic> responseData =
            jsonDecode(response.body) as Map<String, dynamic>;
        devtools.log(responseData.toString());
        return responseData;
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Search QRCode Error: $e');
      throw GenericAuthException();
    }
  }

  Future<Map<String, dynamic>> searchTalent({
    required String searchType, // "education" or "skills"
    required String searchQuery,
    required String sortOption, // Sorting option based on education or skills
    required int page, // Page number for pagination
    int limit = 10, // Limit for pagination (default to 10 results per page)
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search-talent'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'searchType': searchType.toUpperCase(),
          'searchQuery': searchQuery.toUpperCase(),
          'sortOption': sortOption,
          'page': page,
          'limit': limit,
        }),
      );
      devtools.log(response.body);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData != null) {
          return responseData; // Return the full response containing results and totalPages
        } else {
          return {'results': [], 'totalPages': 1}; // No matching talent found
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
  Future<Map<String, dynamic>?> fetchTalentDetails(int StudentAccID) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/showDetails'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'StudentAccID': StudentAccID,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        devtools.log(
            'Fetch Talent Details API Response: ${response.statusCode} ${response.body}');
        return responseData;
      } else {
        devtools.log("Fail to Fetch Talent");
        throw Exception('Failed to retrieve talent details: ${response.body}');
      }
    } catch (e) {
      devtools.log('Fetch Talent Details Error: $e');
      throw Exception('An error occurred while fetching talent details.');
    }
  }

  Future<bool> verifyPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verifyPassword'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      devtools.log(
          'Verify Password API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        return false;
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Verify Password Error: $e');
      throw GenericAuthException();
    }
  }

  // Change Password
  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      if (newPassword.isEmpty || oldPassword.isEmpty) {
        throw GenericAuthException();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/changePassword'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      devtools.log(
          'Change Password API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw WrongPasswordAuthException();
        } else if (response.statusCode == 404) {
          throw UserNotFoundAuthException();
        } else {
          throw GenericAuthException();
        }
      }
    } catch (e) {
      devtools.log('Change Password Error: $e');
      throw GenericAuthException();
    }
  }

// Fetch profile data using POST and send userID in the body
  Future<Map<String, dynamic>?> getProfile(int userID) async {
    try {
      // Use POST instead of GET and pass userID in the body
      final response = await http.post(
        Uri.parse('$baseUrl/getProfile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'userID': userID,
        }),
      );

      if (response.statusCode == 200) {
        devtools.log('Profile fetched successfully for userID: $userID');
        return jsonDecode(response.body); // Return profile data
      } else {
        devtools.log(
            'Failed to fetch profile for userID $userID: ${response.statusCode}');
        devtools.log(response.body); // Log response for debugging
        return null;
      }
    } catch (e) {
      devtools.log('Error fetching profile for userID $userID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> saveProfile(
      int userID, Map<String, dynamic> profileData) async {
    profileData['userID'] = userID; // Include the userID in the profile data

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/saveProfile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        devtools.log('Profile saved successfully for userID: $userID');
        return {'success': true, 'message': 'Profile saved successfully'};
      } else {
        // Try to parse the message from the backend response
        final responseJson = jsonDecode(response.body);
        String errorMessage =
            responseJson['message'] ?? 'Unknown error occurred';

        devtools.log(
            'Failed to save profile for userID $userID: ${response.statusCode}, $errorMessage');
        return {
          'success': false,
          'message': errorMessage
        }; // Return only the 'message'
      }
    } catch (e) {
      devtools.log('Error saving profile for userID $userID: $e');
      return {
        'success': false,
        'message': 'An error occurred while saving the profile'
      };
    }
  }

  Future<void> storeFeedback(String title, String description, int userId,
      String username, String userEmail) async {
    final url =
        Uri.parse('$baseUrl/saveFeedback'); // Replace with your actual API URL
    devtools.log("calling backend");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'userID': userId,
        'username': username,
        'userEmail': userEmail,
        'title': title,
        'description': description,
      }),
    );
    devtools.log("Call Success");

    if (response.statusCode != 200) {
      throw Exception('Failed to store feedback');
    }
  }

  Future<List<dynamic>> fetchUnverifiedUsers() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-unverified-users'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load unverified users');
      }
    } catch (e) {
      throw Exception('Error fetching unverified users: $e');
    }
  }

  Future<void> updateVerificationStatus(int userId, int status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id': userId,
          'VerifiedStatus': status,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update verification status');
      }
    } catch (e) {
      throw Exception('Error updating verification status: $e');
    }
  }

  Future<Map<String, dynamic>> registerVonNetwork({
    required int userId,
  }) async {
    try {
      // Step 1: Fetch user's email and password based on UserID
      final fetchResponse = await http.post(
        Uri.parse('$baseUrl/fetchUserAcc'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'UserID': userId,
        }),
      );

      devtools.log(
          'Fetch User Account API Response: ${fetchResponse.statusCode} ${fetchResponse.body}');

      if (fetchResponse.statusCode != 200) {
        throw Exception(
            'Failed to fetch user account details: ${fetchResponse.body}');
      }

      // Parse the fetched user data (assuming it's a Map<String, dynamic>)
      final userData = jsonDecode(fetchResponse.body) as Map<String, dynamic>;
      final String email = userData['email'];
      final String password = userData['password'];

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email or password is missing for UserID $userId');
      }

      // Step 2: Send the email and password to the VON Network API
      final vonResponse = await http.post(
        Uri.parse('$baseUrl/createWalletandDID'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email, // Send the email to the VON network
          'password': password, // Send the password to the VON network
        }),
      );

      devtools.log(
          'VON Network Register API Response: ${vonResponse.statusCode} ${vonResponse.body}');

      if (vonResponse.statusCode == 200 || vonResponse.statusCode == 201) {
        final responseData =
            jsonDecode(vonResponse.body) as Map<String, dynamic>;
        return responseData; // Return the parsed response data
      } else {
        throw Exception(
            'Failed to register on VON Network: ${vonResponse.body}');
      }
    } catch (e) {
      devtools.log('Error registering on VON Network for UserID $userId: $e');
      throw Exception('Error registering on VON Network: $e');
    }
  }
}
