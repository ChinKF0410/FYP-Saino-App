import 'package:credentials/models/holder.dart';
import 'package:credentials/models/credentialModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CredentialDetails with ChangeNotifier {
  List<Holder> _holders = [];
  List<Holder> get holder => _holders;

  CredentialModel? _credential;
  CredentialModel? get credential => _credential;
  void addHolder(Holder holder) {
    final newHolder = Holder(
      name: holder.name,
      email: holder.email,
      phoneNo: holder.phoneNo,
      description: holder.description,
      address: holder.address,
    );
    _holders.add(newHolder);
    notifyListeners();
  }

  void addCredential(CredentialModel credential) {
    _credential = credential;
    notifyListeners();
  }

  Future<bool> sendHolders() async {
    print('Sending holders: $_holders');
    print('Sending credential: $_credential');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/holders/addHolderAndCredential'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'holders': _holders
            .map((holder) => {
                  'name': holder.name,
                  'email': holder.email,
                  'phoneNo': holder.phoneNo,
                  'description': holder.description,
                  'address': holder.address,
                })
            .toList(),
        'credential': {
          'credentialType': _credential?.credentialType,
          'issuancedate': _credential?.issuancedate,
        }
      }),
    );

    if (response.statusCode == 201) {
      _holders = [];
      _credential = null;
      final message = json.decode(response.body)['message'];
      print('Success: $message');
      return true;
    } else {
      final message = json.decode(response.body)['message'];
      print('Failed: $message');
      return false;
    }
  }
}
