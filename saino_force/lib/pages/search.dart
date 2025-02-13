/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

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
  String sortOption = '';
  List<Map<String, dynamic>> searchResults = [];
  String? errorMessage;
  bool isLoading = false;
  int currentPage = 1; // for pagination
  int totalPages = 1; // for pagination
  final List<String> searchOptions = ['Education', 'Skills'];
  final List<String> educationSortOptions = [
    'Graduated Date (Near to Far)',
    'Graduated Date (Far to Near)'
  ];
  final List<String> skillsSortOptions = [
    'Level (Beginner to Master)',
    'Level (Master to Beginner)'
  ];

  void _searchNewQuery() {
    if (searchQuery.isEmpty) {
      _showErrorDialog('Search Query Cannot Be Empty.');
      return;
    }

    setState(() {
      currentPage = 1; // Reset to first page for a new search
      isLoading = true;
      searchResults = [];
      errorMessage = null;
    });

    _performSearch();
  }

  void _performSearch() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      devtools.log("Searching");
      devtools.log(searchType);
      devtools.log(searchQuery);
      devtools.log(sortOption);
      devtools.log(currentPage.toString());

      final results = await _authProvider.searchTalent(
        searchType: searchType,
        searchQuery: searchQuery,
        sortOption: sortOption,
        page: currentPage,
      );
      if (!mounted) return;
      devtools.log(results.toString());
      setState(() {
        searchResults = List<Map<String, dynamic>>.from(results['results']);
        totalPages = results['totalPages'];
        errorMessage = searchResults.isEmpty ? 'No results found.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Server error occurred.\nPlease try again later. $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper function to map SoftLevel to a descriptive string
  String getSoftLevelDescription(int? level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Unknown';
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

  // Pagination controls
  void _goToNextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      _performSearch();
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _performSearch();
    }
  }

  // ignore: non_constant_identifier_names
  void _navigateToDetails(int StudentAccID) async {
    try {
      final userDetails = await _authProvider.fetchTalentDetails(StudentAccID);
      if (userDetails != null) {
        if (!mounted) return;
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
            // First row - Search bar and Search button
            Row(
              children: [
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
                  onPressed: isLoading ? null : _searchNewQuery,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Second row - Search Type Dropdown and Sort Options Dropdown
            Row(
              children: [
                DropdownButton<String>(
                  value: searchType,
                  onChanged: (String? newValue) {
                    setState(() {
                      searchType = newValue!;
                      sortOption =
                          ''; // Reset sort option on search type change
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
                  child: DropdownButton<String>(
                    value: sortOption.isEmpty ? null : sortOption,
                    hint: const Text('Sort By'),
                    onChanged: (String? newValue) {
                      setState(() {
                        sortOption = newValue!;
                      });
                    },
                    items: (searchType == 'Education'
                            ? educationSortOptions
                            : skillsSortOptions)
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            if (searchResults.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final result = searchResults[index];
                          return Card(
                            child: ListTile(
                              title:
                                  Text(result['profile']['Name'] ?? 'Unknown'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Age: ${result['profile']['Age']}'),
                                  Text(
                                      'Email: ${result['profile']['Email_Address']}'),
                                  if (result['SoftLevel'] !=
                                      null) // Check if SoftLevel exists
                                    Text(
                                        'Level: ${getSoftLevelDescription(result['SoftLevel'])}'), // Convert SoftLevel to description
                                ],
                              ),
                              onTap: () {
                                devtools.log(result['StudentAccID'].toString());
                                _navigateToDetails(result['StudentAccID']);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _goToPreviousPage,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Text('$currentPage / $totalPages'),
                        IconButton(
                          onPressed: _goToNextPage,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
