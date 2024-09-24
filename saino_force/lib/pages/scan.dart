import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as devtools show log;
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
  bool _isScannerDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController.stop();
      setState(() {
        _isScannerDisposed = true;
      });
    } else if (state == AppLifecycleState.resumed && _isScannerDisposed) {
      _scannerController.start();
      setState(() {
        _isScannerDisposed = false;
        _isScanning = true;
      });
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
      final imagePath = pickedFile.path;
      final barcodeCapture = await _scannerController.analyzeImage(imagePath);
      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final qrCode = barcodeCapture.barcodes.first.rawValue;
        devtools.log("\n\n QR Code: $qrCode\n\n");
        if (qrCode != null) {
          devtools.log('QR Code value: $qrCode');
          _sendQRCodeToAPI(qrCode);
        }
      } else {
        devtools.log('No QR Code found in the image.');
      }
    }
  }

  void _sendQRCodeToAPI(String qrCode) {
    _authProvider.searchQRCode(qrCode).then((qrData) {
      if (qrData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewCV(data: qrData)),
        ).then((_) {
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
                _resumeScanning();
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
                        _stopScanning();
                        _sendQRCodeToAPI(qrCode);
                        break;
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
