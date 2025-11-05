import 'dart:convert'; // For jsonDecode
import 'package:flutter/foundation.dart'; // For kIsWeb and debugPrint

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // For XFile
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // For Uint8List

class AddIssueScreen extends StatefulWidget {
  final String userNic;
  const AddIssueScreen({super.key, required this.userNic});

  @override
  State<AddIssueScreen> createState() => _AddIssueScreenState();
}

class _AddIssueScreenState extends State<AddIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Form Controllers ---
  final _schoolNameController = TextEditingController();
  final _buildingNameController = TextEditingController();
  final _buildingAreaController = TextEditingController();
  final _numFloorsController = TextEditingController();
  final _numClassroomsController = TextEditingController();
  final _damageTypeController = TextEditingController();
  final _descriptionController = TextEditingController();

  // --- Date & Image State ---
  DateTime? _selectedDate;
  // --- MODIFIED: Use XFile instead of File ---
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kFieldColor = Color(0xFFF0F2F5);
  static const Color kTextColor = Color(0xFF333333);

  @override
  void dispose() {
    _schoolNameController.dispose();
    _buildingNameController.dispose();
    _buildingAreaController.dispose();
    _numFloorsController.dispose();
    _numClassroomsController.dispose();
    _damageTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- 1. Date Picker Function (Unchanged) ---
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- 2. Image Picker Function (MODIFIED) ---
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        // --- MODIFIED: Add XFile directly ---
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  // --- 3. Upload Images to Server Function (MODIFIED FOR CROSS-PLATFORM) ---
  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      return [];
    }

// --- REPLACE WITH YOUR NEW LINK ---
    var uri = Uri.parse("http://buildcare.atigalle.x10.mx/index.php");
    var request = http.MultipartRequest("POST", uri);

    // --- MODIFIED: Use .readAsBytes() and .fromBytes() ---
    for (var imageFile in _selectedImages) {
      // imageFile is now an XFile
      var fileBytes = await imageFile.readAsBytes();
      var file = http.MultipartFile.fromBytes(
        'images[]', // This key 'images[]' MUST match the PHP script
        fileBytes,
        filename: imageFile.name, // Add the filename, which is good practice
      );
      request.files.add(file);
    }
    // --- END MODIFICATION ---

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['status'] == 'success') {
          List<String> imageUrls =
              List<String>.from(decodedResponse['imageUrls']);
          return imageUrls;
        } else {
          debugPrint('Server error: ${decodedResponse['message']}');
          return [];
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('An error occurred during upload: $e');
      return [];
    }
  }

  // --- 4. Main Save Function (Unchanged) ---
  Future<void> _saveIssue() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a date of occurance.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Upload images
      List<String> uploadedImageUrls = await _uploadImages();

      if (_selectedImages.isNotEmpty && uploadedImageUrls.isEmpty) {
        throw Exception('Failed to upload images. Please try again.');
      }

      // Step 2: Prepare Data
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _buildingNameController.text.trim(),
        'buildingArea': _buildingAreaController.text.trim(),
        'numFloors': int.tryParse(_numFloorsController.text.trim()) ?? 0,
        'numClassrooms':
            int.tryParse(_numClassroomsController.text.trim()) ?? 0,
        'damageType': _damageTypeController.text.trim(),
        'issueTitle':
            '${_buildingNameController.text.trim()} - ${_damageTypeController.text.trim()}',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': uploadedImageUrls,
        'status': 'Pending',
        'addedByNic': widget.userNic,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Step 3: Save to Firestore
      await FirebaseFirestore.instance.collection('issues').add(issueData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save issue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 5. Number Validator Function (Unchanged) ---
  String? _validatePositiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < 0) {
      return 'Please enter a number zero or greater';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title:
            const Text('Add Issue Report', style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _saveIssue,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: 'School Name',
                  hint: 'Enter School Name',
                  controller: _schoolNameController,
                ),
                _buildTextField(
                  label: 'Select Damage Building',
                  hint: 'e.g., Science Lab, Main Hall',
                  controller: _buildingNameController,
                ),
                _buildTextField(
                  label: 'Building Area (sq. ft/m²)',
                  hint: 'e.g., 150ft',
                  controller: _buildingAreaController,
                ),
                _buildTextField(
                  label: 'Number of Floors',
                  hint: 'e.g., 3',
                  controller: _numFloorsController,
                  keyboardType: TextInputType.number,
                  validator: _validatePositiveNumber,
                ),
                _buildTextField(
                  label: 'Number of Classrooms',
                  hint: 'e.g., 10',
                  controller: _numClassroomsController,
                  keyboardType: TextInputType.number,
                  validator: _validatePositiveNumber,
                ),
                _buildTextField(
                  label: 'Type Of Damage',
                  hint: 'e.g., Roofing Damage, Floor Damage',
                  controller: _damageTypeController,
                ),
                _buildTextField(
                  label: 'Description of Issue',
                  hint: 'Describe the issue in detail',
                  controller: _descriptionController,
                  maxLines: 4,
                ),
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildImagePicker(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: _fieldDecoration(hint),
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Of Damage Occurance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            child: Container(
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kFieldColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null
                        ? 'Select a date'
                        : DateFormat('yyyy/MM/dd').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey.shade600
                          : kTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED FOR CROSS-PLATFORM ---
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Images(JPG/PNG)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 8),
        // --- Image Preview Grid ---
        if (_selectedImages.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                // --- MODIFIED: Use FutureBuilder and Image.memory ---
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // Use a FutureBuilder to read the image bytes asynchronously
                    child: FutureBuilder<Uint8List>(
                      future: _selectedImages[index].readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          // Display the image from memory
                          return Image.memory(
                            snapshot.data!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        }
                        // Show a loading spinner while reading the file
                        return const SizedBox(
                          width: 100,
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                );
                // --- END MODIFICATION ---
              },
            ),
          ),
        // --- Pick Images Button ---
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Add Images'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryBlue,
            side: BorderSide(color: kPrimaryBlue.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
  // --- END MODIFICATION ---

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: kFieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryBlue, width: 2.0),
      ),
    );
  }
}
