import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/mssqlauthprovider.dart';
import 'package:saino_force/views/viewDetails.dart';
import 'dart:developer' as devtools show log;
import 'package:saino_force/widgets/widget_support.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();
  String searchType = 'Education';
  String searchQuery = '';
  List<Map<String, dynamic>> searchResults = [];
  String? errorMessage;

  final List<String> searchOptions = ['Education', 'Skills'];

  void _performSearch() async {
    try {
      devtools.log("Searching");
      final results = await _authProvider.searchTalent(
        searchType: searchType,
        searchQuery: searchQuery,
      );
      devtools.log((results.toString()));
      setState(() {
        searchResults = results;
        errorMessage = results.isEmpty ? 'No results found.' : null;
      });
    } catch (e) {
      _showErrorDialog('Server error occurred. Please try again later.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToDetails(int userId) async {
    try {
      final userDetails = await _authProvider.fetchTalentDetails(userId);
      if (userDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ViewDetails(data: userDetails)),
        );
      } else {
        _showErrorDialog('Failed to load user details.');
      }
    } catch (e) {
      _showErrorDialog('Error fetching user details.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: AppWidget.boldTextFieldStyle()),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: searchType,
                  onChanged: (String? newValue) {
                    setState(() {
                      searchType = newValue!;
                    });
                  },
                  items: searchOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      searchQuery = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Enter search term...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final result = searchResults[index];
                    return Card(
                      child: ListTile(
                        title: Text(result['profile']['Name'] ?? 'Unknown'),
                        subtitle: Text(
                          'Age: ${result['profile']['Age']}, Email: ${result['profile']['Email_Address']}',
                        ),
                        onTap: () {
                          devtools.log(result['UserID'].toString());
                          _navigateToDetails(result['UserID']);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
