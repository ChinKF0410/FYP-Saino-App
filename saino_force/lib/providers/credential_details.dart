import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as devtools show log;

import 'package:saino_force/models/credentialModel.dart';
import 'package:saino_force/models/holder.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';

class CredentialDetails with ChangeNotifier {
  List<Holder> _holders = [];
  List<Holder> get holders => _holders;

  CredentialModel? _credential;
  CredentialModel? get credential => _credential;
  void addHolder(Holder holder) {
    _holders.add(holder);
    notifyListeners();
  }

  void removeHolder(Holder holder) {
    devtools.log("Before Removing Holder:\n $_holders");
    _holders.remove(holder);
    devtools.log("After Removing Holder:\n $_holders");
    notifyListeners();
  }

  void addCredential(CredentialModel credential) {
    _credential = credential;
    notifyListeners();
  }

  void clearAll() {
    _holders.clear();
    _credential = null;
    notifyListeners(); // Notify listeners so the UI updates
  }

  Future<bool> sendHolders() async {
    final MSSQLAuthProvider authProvider = MSSQLAuthProvider();
    await authProvider.initialize(); //
    final user = authProvider.currentUser;
    devtools.log('Sending holders: $_holders');
    devtools.log('Sending credential: $_credential');
    devtools.log((user?.email).toString());
    if (holders.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://192.168.1.9:3011/api/createCredential'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user': user?.username,
          'holders': _holders
              .map((holder) => {
                    'name': holder.name,
                    'email': holder.email,
                    'phoneNo': holder.phoneNo,
                    'description': holder.description,
                    'did': holder.did,
                  })
              .toList(),
          'credential': {
            'credentialType': _credential?.credentialType,
            'issuancedate': _credential?.issuancedate,
          } //add token here
        }),
      );
      if (response.statusCode == 201) {
        _holders = [];
        _credential = null;
        final message = json.decode(response.body)['message'];
        devtools.log('Success: $message');
        return true;
      } else {
        final message = json.decode(response.body)['message'];
        devtools.log('Failed: $message');
        return false;
      }
    } else {
      const message = "No Holder To Send";
      devtools.log('Failed: $message');
      return false;
    }
  }
}
