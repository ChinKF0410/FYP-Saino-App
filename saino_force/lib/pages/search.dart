import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/mssqlauthprovider.dart'; // Assuming this is your correct import path

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
      final results = await _authProvider.searchTalent(
        searchType: searchType,
        searchQuery: searchQuery,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Dropdown for selecting search type
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
                // Search bar
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
                // Search button
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
                    return ListTile(
                      title: Text(
                        searchType == 'Education'
                            ? result['InstituteName']
                            : result['InteHighlight'],
                      ),
                      subtitle: Text(
                        searchType == 'Education'
                            ? result['FieldOfStudy']
                            : result['InteDescription'],
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
