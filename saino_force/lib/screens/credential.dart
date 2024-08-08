import 'package:saino_force/models/credentialModel.dart';

import 'package:saino_force/models/holder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/credential_details.dart';
import '../widgets/holder_card.dart';
import 'package:intl/intl.dart';

class Credential extends StatefulWidget {
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
              SizedBox(height: 10), // Add some spacing
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
              SizedBox(height: 10), // Add some spacing
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
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () async {
            DateTime now = DateTime.now();
            String formattedDate = DateFormat('yyyy-MM-dd').format(now);
            ;
            if (_formKey.currentState!.validate()) {
              holderProvider.addCredential(CredentialModel(
                credentialType: _credentialTypeController.text,
                issuancedate: formattedDate,
              ));

              bool success = await holderProvider.sendHolders();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Holders sent successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send holders')),
                );
              }
            }
          },
          child: Text('Send'),
        ),
      ),
    );
  }

  void _showAddHolderDialog(
      BuildContext context, CredentialDetails holderProvider) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _addressController = TextEditingController();

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
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _addressController,
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
                  address: _addressController.text,
                ));
                Navigator.of(ctx).pop();
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
