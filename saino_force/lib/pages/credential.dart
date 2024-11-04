/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saino_force/models/credentialModel.dart';
import 'package:saino_force/models/holder.dart';
import '../providers/credential_details.dart';
import '../widgets/holder_card.dart';
import 'package:intl/intl.dart';
import 'package:saino_force/widgets/widget_support.dart';

class Credential extends StatefulWidget {
  const Credential({super.key});

  @override
  _CredentialState createState() => _CredentialState();
}

class _CredentialState extends State<Credential> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _credentialTypeController;
  bool _isLoading = false; // Track the loading state

  @override
  void initState() {
    super.initState();
    _credentialTypeController = TextEditingController();
  }

  @override
  void dispose() {
    _credentialTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holderProvider = Provider.of<CredentialDetails>(context);

    return PopScope(
      canPop: true, // Allow back navigation
      onPopInvoked: (bool didPop) {
        if (didPop) {
          // Clear all the holders and credentials when the back button is pressed
          holderProvider.clearAll(); // Method to clear all data
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Issue Certification",
            style: AppWidget.boldTextFieldStyle(),
          ),
          backgroundColor: const Color.fromARGB(255, 188, 203, 228),
          centerTitle: true,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _credentialTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Certification Type',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Certifications type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 4,
                        color: Colors.black,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.label, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Certification Details',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 4,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: holderProvider.holders.length,
                    itemBuilder: (ctx, index) {
                      final holder = holderProvider.holders[index];
                      return HolderCard(
                        holder: holder,
                        onDelete: () {
                          // Show confirmation dialog before deletion
                          _confirmDeleteHolder(context, holderProvider, holder);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddHolderDialog(context, holderProvider),
          child: Icon(Icons.add),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              minimumSize: const Size.fromHeight(56.0),
            ),
            onPressed: _isLoading
                ? null
                : () => _sendHolders(holderProvider), // Disable when loading
            child: _isLoading
                ? const CircularProgressIndicator(
                    // Show spinner when loading
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text('Send'), // Show 'Send' when not loading
          ),
        ),
      ),
    );
  }

  void _confirmDeleteHolder(
      BuildContext context, CredentialDetails holderProvider, Holder holder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Certification'),
        content: const Text(
            "Are you sure you want to delete this holder's Certification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Dismiss dialog
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                holderProvider.removeHolder(holder);
              });
              Navigator.of(ctx).pop(); // Close the dialog
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendHolders(CredentialDetails holderProvider) async {
    setState(() {
      _isLoading = true; // Set loading to true when the function starts
    });

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    if (_formKey.currentState!.validate()) {
      holderProvider.addCredential(CredentialModel(
        credentialType: _credentialTypeController.text,
        issuancedate: formattedDate,
      ));

      bool success = await holderProvider.sendHolders();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certification sent successfully')),
        );
// After sending successfully in the credential page
        Navigator.pop(context, true); // Pass true back to the account page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send Certification')),
        );
      }
    }

    setState(() {
      _isLoading = false; // Set loading to false when the function ends
    });
  }

  void _showAddHolderDialog(
      BuildContext context, CredentialDetails holderProvider) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _didController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New Holder'),
        content: SingleChildScrollView(
          child: Container(
            constraints:
                BoxConstraints(minWidth: 300), // Adjust min width as needed
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      errorStyle: TextStyle(color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter Holder's name";
                      }
                      final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
                      if (!nameRegex.hasMatch(value)) {
                        return 'Please enter valid Name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      errorStyle: TextStyle(color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter Holder's Email";
                      }
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone No',
                      errorStyle: TextStyle(color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter Holder's phone No";
                      }
                      final phoneregex = RegExp(r'^(\+6)?01[0-9]{8,9}$');
                      if (!phoneregex.hasMatch(value)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _didController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      errorStyle: TextStyle(color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter Title for Holder ";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      errorStyle: TextStyle(color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some description';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                holderProvider.addHolder(Holder(
                  name: _nameController.text,
                  email: _emailController.text,
                  phoneNo: _phoneController.text,
                  description: _descriptionController.text,
                  did: _didController.text,
                ));
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
