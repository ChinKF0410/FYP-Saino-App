import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';

class EmailVerify extends StatefulWidget {
  const EmailVerify({super.key});

  @override
  State<EmailVerify> createState() => _EmailVerifyState();
}

class _EmailVerifyState extends State<EmailVerify> {
  List<dynamic> unverifiedUsers = [];
  bool isLoading = true;
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();

  @override
  void initState() {
    super.initState();
    _fetchUnverifiedUsers(); // Fetch unverified users when the screen loads
  }

  Future<void> _fetchUnverifiedUsers() async {
    setState(() {
      isLoading = true;
    });
    try {
      final users = await _authProvider.fetchUnverifiedUsers();
      setState(() {
        unverifiedUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }
  }

  Future<void> _updateVerificationStatus(int userId, int status) async {
    setState(() {
      isLoading = true;
    });
    try {
      await _authProvider.updateVerificationStatus(userId, status);
      // Refresh the user list after updating the status
      await _fetchUnverifiedUsers();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating verification status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        elevation: 0,
        title: const Text(
          "Email Verification",
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : unverifiedUsers.isEmpty
              ? const Center(
                  child: Text(
                    'No email verifications waiting at the moment.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: unverifiedUsers.length,
                  itemBuilder: (context, index) {
                    final user = unverifiedUsers[index];

                    return ListTile(
                      title: Text(user['Username']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user['Email']}'),
                          Text('Company: ${user['CompanyName']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Accept Button
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await _updateVerificationStatus(
                                  user['UserID'], 1);
                            },
                          ),
                          // Decline Button
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await _updateVerificationStatus(
                                  user['UserID'], 2);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
