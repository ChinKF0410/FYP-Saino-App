/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:saino_force/pages/scan.dart';
import 'package:saino_force/pages/search.dart';
import 'package:saino_force/pages/credential.dart';
import 'package:saino_force/pages/viewCredentials.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Saino365',
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Jura',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Hero Section
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  // gradient: LinearGradient(
                  //   colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  //   begin: Alignment.topLeft,
                  //   end: Alignment.bottomRight,
                  // ),
                ),
                child: const Column(
                  children: [
                    // Text(
                    //   'Welcome to Saino365',
                    //   style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    //   textAlign: TextAlign.center,
                    // ),
                    // SizedBox(height: 10),
                    Text(
                      'Scan, Search, and Manage Student Credentials Effortlessly',
                      style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Feature Highlights
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: <Widget>[
                    // Feature Card 1: Scan QR Code
                    _buildFeatureCard(
                      icon: Icons.qr_code_scanner,
                      title: 'Scan QR Code',
                      description: 'Easily scan student QR codes to view CVs.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Scan()), 
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Feature Card 2: Search CVs
                    _buildFeatureCard(
                      icon: Icons.search,
                      title: 'Search CVs',
                      description: 'Quickly search for students’ CVs based on skills and qualifications.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Search()),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Feature Card 3: Issue Credentials
                    _buildFeatureCard(
                      icon: Icons.verified_user,
                      title: 'Issue Credentials',
                      description: 'Issuers can easily issue credentials to students.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Credential()), 
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Feature Card 4: View Issued Credentials
                    _buildFeatureCard(
                      icon: Icons.assignment,
                      title: 'View Issued Credentials',
                      description: 'Manage and view all issued credentials effortlessly.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HolderListPage()), 
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Custom method to build feature cards
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                child: Icon(icon, size: 30, color: Colors.blueAccent),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}