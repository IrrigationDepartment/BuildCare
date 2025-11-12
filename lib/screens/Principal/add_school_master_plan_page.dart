import 'dart:convert'; // For jsonDecode
import 'dart:io'; // For File (needed for mobile Image.file)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:image_picker/image_picker.dart'; // For ImagePicker
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:flutter/foundation.dart' show kIsWeb; // For checking if on web

class AddMasterPlanScreen extends StatefulWidget {
  final String schoolName;

  const AddMasterPlanScreen({
    Key? key,
    required this.schoolName,
  }) : super(key: key);

  @override
  _AddMasterPlanScreenState createState() => _AddMasterPlanScreenState();
}

class _AddMasterPlanScreenState extends State<AddMasterPlanScreen> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // We store the XFile from the picker directly. It's cross-platform.
  XFile? _pickedFile;
  bool _isLoading = false;

  // 1. Method to pick an image
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        // Just store the XFile, don't convert it to a dart:io File
        _pickedFile = pickedFile;
      });
    }
  }

  // 2. Main method to upload and save data
  Future<void> _uploadAndSave() async {
    // --- Validation ---
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }
    if (_pickedFile == null) {
      _showErrorSnackBar("Please select an image to upload.");
      return; // No image selected
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --- STEP A: Upload Image to your PHP Server ---
      var uri = Uri.parse("http://buildcare.atigalle.x10.mx/index.php");
      var request = http.MultipartRequest("POST", uri);

      // Add text fields
      request.fields['description'] = _descriptionController.text;
      request.fields['schoolName'] = widget.schoolName;

      // --- This block is now cross-platform ---
      // It uses the methods from XFile to read the data
      if (kIsWeb) {
        // WEB UPLOAD
        var bytes = await _pickedFile!.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'master_plan_file',
          bytes,
          filename: _pickedFile!.name, // Use XFile.name
        );
        request.files.add(multipartFile);
      } else {
        // MOBILE UPLOAD
        var stream = _pickedFile!.openRead();
        var length = await _pickedFile!.length();
        var multipartFile = http.MultipartFile(
          'master_plan_file',
          stream,
          length,
          filename: _pickedFile!.name, // Use XFile.name
        );
        request.files.add(multipartFile);
      }
      // --- End of cross-platform block ---

      // Send request and get response
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      // Check PHP response
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['status'] == 'success') {
          // --- STEP B: Save URL to Firestore ---
          String imageUrlFromPHP = decodedResponse['masterPlanUrl'];

          await FirebaseFirestore.instance.collection('schoolMasterPlans').add({
            'schoolName': widget.schoolName,
            'description': _descriptionController.text,
            'masterPlanUrl': imageUrlFromPHP,
            'createdAt': Timestamp.now(),
          });

          _showSuccessSnackBar("Master plan added successfully!");
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          _showErrorSnackBar("Server error: ${decodedResponse['message']}");
        }
      } else {
        _showErrorSnackBar("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Helper snackbar methods ---
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // 3. Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Add School Master Plan",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Save Button
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _uploadAndSave, // This calls the upload function
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image Upload Box ---
              const Text(
                "Upload Master Plan (JPG/PNG)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  // Check the new _pickedFile variable
                  child: _pickedFile == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_search,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Upload school master plan",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          // This logic uses the XFile.path to display
                          child: kIsWeb
                              ? Image.network(
                                  _pickedFile!.path, // Web uses Image.network
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_pickedFile!
                                      .path), // Mobile must use Image.file
                                  fit: BoxFit.cover,
                                ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Description Box ---
              const Text(
                "Description",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "describe about school master plan",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a description";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
