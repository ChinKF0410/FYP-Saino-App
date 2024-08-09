import 'package:flutter/material.dart';
import 'package:saino_force/widgets/widget_support.dart'; // Assuming this is where AppWidget is defined

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  // Controller for the TextField
  final TextEditingController _searchController = TextEditingController();

  // Define the custom icon data
  // ignore: constant_identifier_names
  static const IconData filter_alt_outlined = IconData(0xf068, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
          onPressed: () {
            // Navigate back to the previous screen or to a specific route
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        title: Text(
          "Search",
          style: AppWidget.boldTextFieldStyle(),
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Search bar with icons
            Row(
              children: <Widget>[
                // Search TextField
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Handle search text change
                    },
                  ),
                ),
                // Filter IconButton with custom icon
                IconButton(
                  icon: const Icon(filter_alt_outlined),
                  onPressed: () {
                    // Handle filter action
                  },
                ),
                // Sort IconButton
                IconButton(
                  icon: const Icon(Icons.sort_outlined),
                  onPressed: () {
                    // Handle sort action
                  },
                ),
              ],
            ),
            // Add other widgets or containers below the search bar
          ],
        ),
      ),
    );
  }
}