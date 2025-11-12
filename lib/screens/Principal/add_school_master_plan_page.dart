import 'dart:io'; // Required to work with File objects
import 'package:firebase_storage/firebase_storage.dart'; // For file uploads
import 'package:cloud_firestore/cloud_firestore.dart'; // For database
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// Primary color for UI consistency
const Color _primaryColor = Color(0xFF53BDFF);

class AddSchoolMasterPlanPage extends StatefulWidget {
  const AddSchoolMasterPlanPage({super.key});

  @override
  State<AddSchoolMasterPlanPage> createState() => _AddSchoolMasterPlanPageState();
}

class _AddSchoolMasterPlanPageState extends State<AddSchoolMasterPlanPage> {
  // Store the File object directly
  File? _masterPlanFile;
  File? _updatedPlanFile;
  
  // To show a loading indicator while uploading
  bool _isLoading = false; 
  
  // Text editing controllers
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _schoolNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 1. Pick Image Logic
  Future<void> _pickImage(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      setState(() {
        if (type == 'master') {
          _masterPlanFile = File(filePath); // Store as File
        } else if (type == 'updated') {
          _updatedPlanFile = File(filePath); // Store as File
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: $fileName')),
      );

    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File selection cancelled.')),
      );
    }
  }

  /// 2. Firebase Upload Logic
  
  /// Helper function to upload a file to Firebase Storage
  Future<String> _uploadFile(File file, String schoolName, String planType) async {
    try {
      // Create a unique file name
      String fileExtension = file.path.split('.').last;
      String fileName = '${planType}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      // Create a reference in Firebase Storage
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('school_plans') // Main folder
          .child(schoolName)      // Sub-folder for the school
          .child(fileName);       // File

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;

    } catch (e) {
      print("File Upload Error: $e");
      throw Exception('Failed to upload file.');
    }
  }

  /// Main function to save all data
  Future<void> _saveToFirebase() async {
    // Basic Validation
    if (_schoolNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter a school name.');
      return;
    }
    if (_masterPlanFile == null) {
      _showErrorSnackBar('Please upload the main master plan.');
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      String schoolName = _schoolNameController.text.trim();
      String? masterPlanUrl;
      String? updatedPlanUrl;

      // Upload Master Plan (Required)
      masterPlanUrl = await _uploadFile(_masterPlanFile!, schoolName, 'master');

      // Upload Updated Plan (Optional)
      if (_updatedPlanFile != null) {
        updatedPlanUrl = await _uploadFile(_updatedPlanFile!, schoolName, 'updated');
      }

      // Save all data to Cloud Firestore
      CollectionReference schools = FirebaseFirestore.instance.collection('schools');

      await schools.add({
        'schoolName': schoolName,
        'description': _descriptionController.text.trim(),
        'masterPlanUrl': masterPlanUrl, 
        'updatedPlanUrl': updatedPlanUrl, // Can be null if not provided
        'timestamp': FieldValue.serverTimestamp(), 
      });

      // Success
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School Plan saved successfully!')),
      );
      
      // Navigate back after success
      if (mounted) {
          Navigator.of(context).pop();
      }

    } catch (e) {
      // Handle Errors
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to save data: $e');
    }
  }
  
  // Helper for error messages
  void _showErrorSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }

  /// 3. Build Method (UI)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add School Master Plan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: _isLoading ? null : _saveToFirebase, // Disable when loading
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primaryColor, width: 1.5),
                foregroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                disabledForegroundColor: Colors.grey,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  SizedBox(height: 16),
                  Text("Uploading data..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School Name Field
                  _buildSectionTitle('School Name'),
                  _buildTextField(
                    controller: _schoolNameController,
                    hintText: 'Enter Your School name',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 30),

                  // Master Plan Upload Section
                  _buildSectionTitle('Upload Master Plan (JPG/PNG)'),
                  _buildFileUploadArea(
                    context,
                    'Upload school master plan',
                    _masterPlanFile, // Pass the File
                    onTap: () => _pickImage('master'), 
                  ),
                  const SizedBox(height: 30),

                  // Description Field
                  _buildSectionTitle('Description'),
                  _buildTextField(
                    controller: _descriptionController,
                    hintText: 'describe about school master plan',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 40),

                  // Updated Master Plan Note
                  _buildUpdatedPlanNote(),
                  const SizedBox(height: 10),

                  // Updated Master Plan Upload Section
                  _buildFileUploadArea(
                    context,
                    'Upload updated school master plan',
                    _updatedPlanFile, // Pass the File
                    onTap: () => _pickImage('updated'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: const EdgeInsets.all(15),
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  /// MODIFIED: This function now displays a small image preview when a file is selected.
  Widget _buildFileUploadArea(
      BuildContext context,
      String defaultText,
      File? file, // Changed from String? to File?
      {required VoidCallback onTap}) {
    
    final bool isSelected = file != null; 
    final String displayText = isSelected 
        ? file!.path.split('/').last // '!' operator added because isSelected ensures file is not null
        : defaultText;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row( 
          mainAxisAlignment: isSelected ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            // --- IMAGE PREVIEW ADDED HERE ---
            if (isSelected) 
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.file(
                    file!, // Use Image.file to display the selected File
                    width: 70, // Thumbnail width
                    height: 100, // Thumbnail height
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if the image fails to load 
                      return const Icon(Icons.insert_drive_file, size: 50, color: Colors.grey);
                    },
                  ),
                ),
              )
            else
              // Default upload icon when no file is selected
              const Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: Colors.grey,
              ),

            // --- File Name / Hint Text ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 0.0 : 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSelected ? 'File Selected:' : defaultText,
                    style: TextStyle(
                      fontSize: isSelected ? 12 : 16,
                      color: isSelected ? Colors.grey[600] : Colors.grey[600],
                    ),
                  ),
                  if (isSelected)
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 150, // Constrain text width
                      child: Text(
                        displayText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatedPlanNote() {
    return const Text(
      'If newly added building to school, principal should upload their new master plan(JPG/PNG)',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}