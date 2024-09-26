import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as devtools show log;
import 'package:image/image.dart' as img;

import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';
import 'package:saino_force/utilities/show_error_dialog.dart';

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
            // Correctly decode and display the image from backend
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

    setState(() {
      _isSaving = true; // Start saving
    });

    Uint8List? imageBytes = _tempImageBytes;
    if (_imageFile != null) {
      // Read the selected image file and update imageBytes
      imageBytes = await File(_imageFile!.path).readAsBytes();
    }

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
      // If save operation failed, show an error dialog with the backend's error message
      await showErrorDialog(
        context,
        result['message'] ?? 'Failed to save profile. Please try again.',
      );
    } else if (result['success'] && mounted) {
      // If save operation succeeded, close the dialog or navigate back
      setState(() {
        _isEditing = false;
        _tempImageBytes = imageBytes; // Set the new image after save
      });
      Navigator.pop(context, true); // Optionally return 'true' to indicate success
    }

    if (mounted) {
      setState(() {
        _isSaving = false; // End saving
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
                      _tempImageBytes = null; // Clear temp image for new selection
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
                      _tempImageBytes = null; // Clear temp image for new selection
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
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
          const SizedBox(height: 30.0),
          _buildTextField("Nickname", _nicknameController, _isEditing),
          _buildTextField("Surname", _surnameController, _isEditing),
          _buildTextField("Last Name", _lastnameController, _isEditing),
          _buildTextField("Age", _ageController, _isEditing,
              keyboardType: TextInputType.number),
          _buildTextField("Mobile Phone", _mobilePhoneController, _isEditing),
          const SizedBox(height: 20.0),
          ElevatedButton(
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
              backgroundColor: const Color(0xFF171B63),
              padding: const EdgeInsets.symmetric(
                horizontal: 60.0,
                vertical: 15.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.0,
              ),
            ),
          ),
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
}
