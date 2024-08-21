import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as devtools show log;
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';
import 'package:saino_force/views/viewCV.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> with WidgetsBindingObserver {
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanQRCode(); // Start scanning when the widget is initialized
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isScanning) {
      devtools.log('App resumed, resuming scanning');
      _resumeScanning();
    } else if (state == AppLifecycleState.paused) {
      devtools.log('App paused, stopping scanning');
      _stopScanning();
    }
  }

  void _scanQRCode() {
    if (_isScanning) {
      _scannerController.start();
    }
  }

  void _stopScanning() {
    _scannerController.stop();
    setState(() {
      _isScanning = false;
    });
  }

  void _resumeScanning() {
    _scannerController.start();
    setState(() {
      _isScanning = true;
    });
  }

  void _uploadQRCodeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final qrCode = await _processQRCodeFromImage(pickedFile);
      if (qrCode != null) {
        _stopScanning();
        _sendQRCodeToAPI(qrCode);
      }
    }
  }

  Future<String?> _processQRCodeFromImage(XFile file) async {
    try {
      final qrCodeValue = await QrCodeToolsPlugin.decodeFrom(file.path);
      if (qrCodeValue != null) {
        devtools.log('QR Code value: $qrCodeValue');
        return qrCodeValue;
      } else {
        devtools.log('No QR Code found in the image.');
        return null;
      }
    } catch (e) {
      devtools.log('Error processing QR Code from image: $e');
      return null;
    }
  }

  void _sendQRCodeToAPI(String qrCode) {
    _authProvider.searchQRCode(qrCode).then((qrData) {
      if (qrData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewCV(data: qrData)),
        ).then((_) {
          // Resume scanning when returning from the ViewCV page
          _resumeScanning();
        });
      } else {
        _showErrorDialog('Invalid or Expired CV QR Code');
      }
    }).catchError((error) {
      _showErrorDialog('An error occurred while searching for the QR code.');
    });
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeScanning(); // Resume scanning after dismissing the dialog
              },
              child: const Text('OK'),
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
        title: const Text('Scan QR Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code Scanner Box
            SizedBox(
              height: 300,
              width: 300,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (BarcodeCapture capture) {
                  if (_isScanning) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? qrCode = barcode.rawValue;
                      if (qrCode != null) {
                        devtools.log('QR Code scanned: $qrCode');
                        _stopScanning(); // Stop scanning immediately
                        _sendQRCodeToAPI(qrCode); // Send the QR code to API
                        break; // Stop processing other barcodes
                      }
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadQRCodeImage,
              child: const Text('Upload QR Code Image'),
            ),
          ],
        ),
      ),
    );
  }
}
