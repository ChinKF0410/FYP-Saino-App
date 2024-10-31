/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:saino_force/services/auth/MSSQLAuthProvider.dart';
import 'package:saino_force/utilities/show_error_dialog.dart'; // Import your showErrorDialog utility
import 'dart:developer' as devtools show log;
import 'package:saino_force/widgets/widget_support.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      // Ensure initialization is completed
      await _authProvider.initialize();

      // Get the current user info
      final user = _authProvider.currentUser;

      final title = _titleController.text;
      final description = _descriptionController.text;

      try {
        if (user != null) {
          devtools.log("calling MIDDLE END");
          devtools.log(title);
          devtools.log(description);
          devtools.log(user.id.toString());
          devtools.log(user.username);
          devtools.log(user.email);

          await _authProvider.storeFeedback(
            title,
            description,
            user.id, // Assuming you have these fields available
            user.username, // Replace according to your auth provider's structure
            user.email,
          );

          // Show success dialog
          await showErrorDialog(
            context,
            'Feedback submitted successfully.',
          );

          // Clear form after submission
          _titleController.clear();
          _descriptionController.clear();
        } else {
          // Show error dialog for missing user
          await showErrorDialog(
            context,
            'No User Found. Please log in.',
          );
        }
      } catch (error) {
        // Show error dialog for submission failure
        await showErrorDialog(
          context,
          'Failed to submit feedback. Please try again later.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Feedback', style: AppWidget.boldTextFieldStyle()),
        backgroundColor: const Color.fromARGB(255, 188, 203, 228),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 16.0),
                  minimumSize: const Size.fromHeight(56.0),
                ),
                onPressed: _submitFeedback,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
