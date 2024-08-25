import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';
import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'package:saino_force/services/auth/auth_service.dart';

class ShowQRCodeView extends StatefulWidget {
  const ShowQRCodeView({super.key});

  @override
  _ShowQRCodeViewState createState() => _ShowQRCodeViewState();
}

class _ShowQRCodeViewState extends State<ShowQRCodeView> {
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();
  List<Map<String, dynamic>> qrCodes = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQRCodes();
  }

  Future<void> _fetchQRCodes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get the current user
      final user = AuthService.mssql().currentUser;

      if (user != null) {
        devtools.log('Fetching QR Codes for UserID: ${user.id}');
        final qrCodeData = await _authProvider.fetchQRCodesByUserId(user.id);

        setState(() {
          qrCodes = qrCodeData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'User not logged in.';
          isLoading = false;
        });
      }
    } catch (e) {
      devtools.log('Error fetching QR Codes: $e');
      setState(() {
        errorMessage = 'Failed to load QR Codes. Please try again later.';
        isLoading = false;
      });
    }
  }

  void _showQRCodeImage(String qrCodeImage) {
    final qrCodeImageBytes = base64Decode(qrCodeImage);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code'),
          content: Image.memory(qrCodeImageBytes),
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
        title: const Text('Your QR Codes'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : qrCodes.isEmpty
                  ? const Center(child: Text('No QR Codes found.'))
                  : ListView.builder(
                      itemCount: qrCodes.length,
                      itemBuilder: (context, index) {
                        final qrCode = qrCodes[index];
                        if(qrCode['expireDate'] == null){
                          devtools.log("NULL");
                        }
                        final expireDate = DateTime.parse(qrCode['expireDate']);
                        final formattedDate =
                            '${expireDate.day}/${expireDate.month}/${expireDate.year}';

                        return ListTile(
                          title: Text('QR Code ${index + 1}'),
                          subtitle: Text('Expires on: $formattedDate'),
                          onTap: () => _showQRCodeImage(qrCode['qrCodeImage']),
                        );
                      },
                    ),
    );
  }
}
