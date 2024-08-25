import 'package:flutter/material.dart';
import 'package:saino_force/widgets/widget_support.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as devtools show log;


Future<void> createCredential(Map<String, String> credentialData) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/createCredential'), // Make sure this URL is correct
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(credentialData),
  );

  if (response.statusCode == 200) {
    devtools.log('Credential created successfully');
  } else {
    devtools.log('Failed to create credential');
  }
}

class CreateCredentialPage extends StatefulWidget {
  const CreateCredentialPage({super.key});

  @override
  State<CreateCredentialPage> createState() => _CreateCredentialPageState();
}

class _CreateCredentialPageState extends State<CreateCredentialPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the text fields
  final TextEditingController _issuerNameController = TextEditingController();
  final TextEditingController _credentialTypeController = TextEditingController();
  final TextEditingController _issuanceDateController = TextEditingController();
  final TextEditingController _issuanceDescriptionController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _walletAddressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Create Credentials',
          style: AppWidget.boldTextFieldStyle(),
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_issuerNameController, 'Issuer Name'),
              _buildTextField(_credentialTypeController, 'Credential Type'),
              _buildTextField(_issuanceDateController, 'Issuance Date'),
              _buildTextField(_issuanceDescriptionController, 'Issuance Description'),
              _buildTextField(_holderNameController, 'Holder Name'),
              _buildTextField(_idNumberController, 'ID Number'),
              _buildTextField(_emailController, 'Email'),
              _buildTextField(_phoneNumberController, 'Phone Number'),
              _buildTextField(_walletAddressController, 'Wallet Address'),
              
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // Handle form submission
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  textStyle: AppWidget.accountStyle(),
                ),
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $labelText';
          }
          return null;
        },
      ),
    );
  }
}
