/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as devtools show log;
import 'package:image/image.dart' as img; // Import image package
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';
import 'package:saino_force/utilities/show_error_dialog.dart';
import 'package:saino_force/widgets/widget_support.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();
  bool _isEditing = false;
  bool _isLoading = true; // Loading flag
  bool _isSaving = false; // Saving flag
  XFile? _imageFile;
  Uint8List? _tempImageBytes;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobilePhoneController = TextEditingController();
  int? _userID;

  @override
  void initState() {
    super.initState();
    _initializeAndFetchProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _surnameController.dispose();
    _lastnameController.dispose();
    _ageController.dispose();
    _mobilePhoneController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndFetchProfile() async {
    if (!mounted) return; // Ensure widget is still in the tree
    setState(() {
      _isLoading = true; // Start loading
    });

    await _authProvider.initialize();
    final user = _authProvider.currentUser;

    if (user != null) {
      _userID = user.id;

      final profileData = await _authProvider.getProfile(_userID!);

      if (profileData != null && mounted) {
        setState(() {
          _nicknameController.text = profileData['Nickname'] ?? '';
          _surnameController.text = profileData['Surname'] ?? '';
          _lastnameController.text = profileData['Lastname'] ?? '';
          _ageController.text = profileData['Age']?.toString() ?? '';
          _mobilePhoneController.text = profileData['MobilePhone'] ?? '';

          if (profileData['Photo'] != null && profileData['Photo'].isNotEmpty) {
            _tempImageBytes = base64Decode(profileData['Photo']);
          } else {
            _tempImageBytes = null;
          }
        });
      } else {
        devtools.log(
            'No profile data found for user $_userID. User can create a new profile.');
      }
    } else {
      devtools.log('UserID not found');
      if (mounted) {
        await showErrorDialog(context, 'User Not Found');
        Navigator.of(context).pop(); // Navigate back
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  Future<void> _saveProfileData() async {
    if (_userID == null) {
      devtools.log('Cannot save, userID is null');
      return;
    }

    String? phoneValidationError =
        _validatePhoneNumber(_mobilePhoneController.text.trim());
    if (phoneValidationError != null) {
      await showErrorDialog(context, phoneValidationError);
      return;
    }

    setState(() {
      _isSaving = true; // Start saving
    });

    Uint8List? imageBytes = _tempImageBytes;
    if (_imageFile != null) {
      // Read the selected image file
      final File imageFile = File(_imageFile!.path);
      final img.Image? originalImage =
          img.decodeImage(imageFile.readAsBytesSync());

      if (originalImage != null) {
        // Get the size of the original image
        int originalSizeBytes = imageFile.lengthSync();

        // If the image is larger than 2MB, compress it
        if (originalSizeBytes > 2 * 1024 * 1024) {
          devtools.log('Image size exceeds 2MB. Compressing...');
          const int targetSizeMB = 2;
          const int targetSizeBytes = targetSizeMB * 1024 * 1024;

          // Estimate resize factor based on the original size
          double resizeFactor = sqrt(targetSizeBytes / originalSizeBytes);

          // Resize the image based on the factor
          img.Image resizedImage = img.copyResize(
            originalImage,
            width: (originalImage.width * resizeFactor).toInt(),
          );

          int quality = 80;
          List<int> compressedImageBytes =
              img.encodeJpg(resizedImage, quality: quality);
          devtools.log(
              'Compressed image size: ${compressedImageBytes.length} bytes');

          // If compression is still large, reduce quality in steps
          while (
              compressedImageBytes.length > targetSizeBytes && quality > 10) {
            quality -= 10;
            compressedImageBytes =
                img.encodeJpg(resizedImage, quality: quality);
            devtools.log(
                'Reduced quality to $quality. New size: ${compressedImageBytes.length} bytes');
          }

          imageBytes = Uint8List.fromList(compressedImageBytes);
        } else {
          // If already under 2MB, no compression
          imageBytes = await imageFile.readAsBytes();
        }
      }
    }
    devtools.log('Final image size: ${imageBytes?.lengthInBytes ?? 0} bytes');

    final profileData = {
      'nickname': _nicknameController.text.trim(),
      'surname': _surnameController.text.trim(),
      'lastname': _lastnameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()),
      'mobilePhone': _mobilePhoneController.text.trim(),
      'photo': imageBytes != null ? base64Encode(imageBytes) : null,
    };

    // Call the middle-end function to save the profile
    final result = await _authProvider.saveProfile(_userID!, profileData);

    if (!result['success'] && mounted) {
      await showErrorDialog(
        context,
        result['message'] ?? 'Failed to save profile. Please try again.',
      );
    } else if (result['success'] && mounted) {
      setState(() {
        _isEditing = false;
        _tempImageBytes = imageBytes; // Set the new image after save
      });
      Navigator.pop(context, true);
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _showImagePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (mounted) {
                    setState(() {
                      _imageFile = pickedFile;
                      _tempImageBytes =
                          null; // Clear temp image for new selection
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (mounted) {
                    setState(() {
                      _imageFile = pickedFile;
                      _tempImageBytes =
                          null; // Clear temp image for new selection
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Profile",
          style: AppWidget.boldTextFieldStyle(),
        ),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loader while loading
          : Stack(
              children: [
                _buildProfileForm(),
                if (_isSaving)
                  const Center(
                      child:
                          CircularProgressIndicator()), // Show spinner during save
              ],
            ),
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: InkWell(
              onTap: _isEditing ? () => _showImagePicker(context) : null,
              child: CircleAvatar(
                radius: 80.0,
                backgroundImage: _imageFile != null
                    ? FileImage(File(_imageFile!.path))
                    : _tempImageBytes != null
                        ? MemoryImage(_tempImageBytes!)
                        : null,
                child: _imageFile == null && _tempImageBytes == null
                    ? const Icon(Icons.camera_alt, size: 80.0)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 30.0),
          _buildTextField("Nickname", _nicknameController, _isEditing),
          _buildTextField("Surname", _surnameController, _isEditing),
          _buildTextField("Last Name", _lastnameController, _isEditing),
          _buildTextField("Age", _ageController, _isEditing,
              keyboardType: TextInputType.number),
          _buildTextField("Mobile Phone", _mobilePhoneController, _isEditing),
          const SizedBox(height: 20.0),
          Center(
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_isEditing) {
                        _saveProfileData();
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 16.0),
                minimumSize: const Size.fromHeight(56.0),
              ),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold, // Make the text bold
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isEnabled,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10.0),
        TextField(
          controller: controller,
          enabled: isEnabled,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isEnabled ? Colors.black : Colors.grey,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 15.0,
            ),
            hintText: label == 'Mobile Phone' ? '01XXXXXXXX' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  String? _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return 'Mobile Phone cannot be empty';
    } else if (!RegExp(r'^01\d{8,9}$').hasMatch(phoneNumber)) {
      return 'Invalid Phone Number.';
    }
    return null;
  }
}
