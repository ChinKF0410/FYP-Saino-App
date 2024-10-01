import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';

class Holder {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String description;
  final String did;
  final String status;

  Holder({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.description,
    required this.did,
    required this.status,
  });

  factory Holder.fromJson(Map<String, dynamic> json) {
    return Holder(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
      did: json['did'] ?? '',
      status: json['status'] ?? 'Unknown',
    );
  }
}

class HolderListPage extends StatefulWidget {
  @override
  _HolderListPageState createState() => _HolderListPageState();
}

class _HolderListPageState extends State<HolderListPage> {
  List<Holder> _holders = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isEmpty = false; // Flag to check for empty data

  @override
  void initState() {
    super.initState();
    _fetchHolders();
  }

  Future<void> _fetchHolders() async {
    final MSSQLAuthProvider authProvider = MSSQLAuthProvider();
    await authProvider.initialize(); // Initialize the authentication provider
    final user = authProvider.currentUser; // Get the current user

    try {
      final response = await http.post(
        Uri.parse('http://172.16.20.168:3010/api/ViewCredential'),
        headers: {'Content-Type': 'application/json'}, // Set content type
        body: json.encode({
          'username': user?.username, // Pass 'username' to the backend
        }),
      );

      if (response.statusCode == 200) {
        devtools.log(response.body);

        final List<dynamic> data = json.decode(response.body);

        if (mounted) {
          if (data.isEmpty) {
            // If the response body is empty, show a message
            setState(() {
              _isEmpty = true; // Set the empty flag
              _isLoading = false;
            });
          } else {
            setState(() {
              _holders = data.map((json) => Holder.fromJson(json)).toList();
              _isLoading = false;
              _isEmpty = false; // Reset the empty flag if there is data
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Holder Credentials'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Loading spinner
          : _hasError
              ? Center(child: Text('Failed to load holders')) // Error message
              : _isEmpty
                  ? Center(
                      child:
                          Text('No credentials created')) // Empty data message
                  : ListView.builder(
                      padding: EdgeInsets.all(8.0),
                      itemCount: _holders.length,
                      itemBuilder: (context, index) {
                        final holder = _holders[index];
                        return HolderCard(holder: holder);
                      },
                    ),
    );
  }
}

// Widget to display individual Holder details
class HolderCard extends StatelessWidget {
  final Holder holder;

  HolderCard({required this.holder});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              holder.name,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text('Email: ${holder.email}', style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 5.0),
            Text('Phone: ${holder.phone}', style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 5.0),
            Text('Description: ${holder.description}',
                style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 5.0),
            
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HolderListPage(),
  ));
}
