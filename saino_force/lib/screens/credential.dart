// ignore_for_file: library_private_types_in_public_api

import 'package:saino_force/models/credentialModel.dart';

import 'package:saino_force/models/holder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/credential_details.dart';
import '../widgets/holder_card.dart';
import 'package:intl/intl.dart';

class Credential extends StatefulWidget {
  const Credential({super.key});

  @override
  _CredentialState createState() => _CredentialState();
}

class _CredentialState extends State<Credential> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _credentialTypeController;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Credential Issue Screen')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _credentialTypeController,
                decoration: const InputDecoration(
                  labelText: 'Credential Type',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a credential type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10), // Add some spacing
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
                          'Credential Details',
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
              const SizedBox(height: 10), // Add some spacing
              Expanded(
                child: ListView.builder(
                  itemCount: holderProvider.holder.length,
                  itemBuilder: (ctx, index) =>
                      HolderCard(holderProvider.holder[index]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHolderDialog(context, holderProvider),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () async {
            DateTime now = DateTime.now();
            String formattedDate = DateFormat('yyyy-MM-dd').format(now);
            if (_formKey.currentState!.validate()) {
              holderProvider.addCredential(CredentialModel(
                credentialType: _credentialTypeController.text,
                issuancedate: formattedDate,
              ));

              bool success = await holderProvider.sendHolders();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Holders sent successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to send holders')),
                );
              }
            }
          },
          child: const Text('Send'),
        ),
      ),
    );
  }

  void _showAddHolderDialog(
      BuildContext context, CredentialDetails holderProvider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final descriptionController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Holder'),
        content: SingleChildScrollView(
          child: Container(
            constraints:
                const BoxConstraints(minWidth: 300), // Adjust min width as needed
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      errorStyle: TextStyle(color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter Holder's address";
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                holderProvider.addHolder(Holder(
                  name: nameController.text,
                  email: emailController.text,
                  phoneNo: phoneController.text,
                  description: descriptionController.text,
                  address: addressController.text,
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
