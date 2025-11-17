import 'dart:convert'; // For jsonDecode
import 'package:flutter/foundation.dart'; // For debugPrint, Uint8List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // For XFile
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // For Uint8List

class AddIssueScreen extends StatefulWidget {
  final String userNic;
  final String? issueId; // <-- ADDED: Nullable issueId for edit mode

  const AddIssueScreen({
    super.key,
    required this.userNic,
    this.issueId, // <-- ADDED
  });

  @override
  State<AddIssueScreen> createState() => _AddIssueScreenState();
}

class _AddIssueScreenState extends State<AddIssueScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _classroomsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedBuilding;
  String? _selectedDamageType;
  DateTime? _selectedDate;

  // --- NEW: State for Edit Mode ---
  bool get _isEditMode => widget.issueId != null;
  bool _isLoading = false;
  bool _isPageLoading = false; // For loading data in edit mode

  // --- MODIFIED: Image lists for edit mode ---
  final List<XFile> _selectedImages = []; // New images to upload
  List<String> _existingImageUrls = []; // Existing images from server
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

  // --- CONTENT FROM add_building_issues.dart ---
  final List<String> _buildingTypes = [
    'Academic Classroom',
    'Office',
    'Science Lab',
    'Technology Lab',
    'Library',
    'Hostel',
    'Computer Lab',
    'Dahampasala Lab',
    'Store Room',
    'Auditorium',
    'Main Hall',
    'Changing Room',
    'Security Room',
    'Wash Room',
    'Boundary Wall'
  ];

  final List<String> _damageTypes = [
    'Foundation & Wall Damage',
    'Roofing Damage',
    'Utility Damage (Electricity/Water)',
    'Floor Damage',
    'Plumbing/Draining Structural Issue',
    'Windows/Doors Frame Damage',
    'Staircase & Corridor Damage'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadIssueData();
    }
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _floorsController.dispose();
    _classroomsController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- NEW: Load data for Edit Mode ---
  Future<void> _loadIssueData() async {
    setState(() => _isPageLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId!)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Populate controllers
        _schoolNameController.text = data['schoolName'] ?? '';
        _floorsController.text = data['numFloors']?.toString() ?? '';
        _classroomsController.text = data['numClassrooms']?.toString() ?? '';
        _descriptionController.text = data['description'] ?? '';

        // Populate dropdowns
        _selectedBuilding = data['buildingName'];
        _selectedDamageType = data['damageType'];

        // Populate date
        if (data['dateOfOccurance'] != null) {
          _selectedDate = (data['dateOfOccurance'] as Timestamp).toDate();
          _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        }

        // Populate existing images
        _existingImageUrls = List<String>.from(data['imageUrls'] ?? []);
      } else {
        // Handle doc not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Issue not found.'), backgroundColor: Colors.red),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading data: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPageLoading = false);
      }
    }
  }

  // --- Image Picker Function (MODIFIED for multi-select) ---
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles =
        await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  // --- MODIFIED: Image Remover Functions ---
  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  // --- 1. Upload Images to Server Function (Unchanged) ---
  Future<List<String>> _uploadImages() async {
    // This function only uploads NEW images from _selectedImages
    if (_selectedImages.isEmpty) {
      return [];
    }
    
    var uri = Uri.parse("https://buildcare.atigalle.x10.mx/");
    var request = http.MultipartRequest("POST", uri);

    for (var imageFile in _selectedImages) {
      var fileBytes = await imageFile.readAsBytes();
      var file = http.MultipartFile.fromBytes(
        'images[]',
        fileBytes,
        filename: imageFile.name,
      );
      request.files.add(file);
    }
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['status'] == 'success') {
          return List<String>.from(decodedResponse['imageUrls']);
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

  // --- NEW: Handle form submission (Save or Update) ---
  Future<void> _handleSubmit() async {
    if (_isEditMode) {
      await _updateIssue();
    } else {
      await _addNewIssue();
    }
  }

  // --- 2. Main Save Function (RENAMED from _saveIssue) ---
  Future<void> _addNewIssue() async {
    if (!_formKey.currentState!.validate()) return;
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
        throw Exception(
            'Failed to upload images. Please check server connection.');
      }

      // Step 2: Prepare Data
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'numFloors': int.tryParse(_floorsController.text.trim()) ?? 0,
        'numClassrooms': int.tryParse(_classroomsController.text.trim()) ?? 0,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': uploadedImageUrls,
        'status': 'Pending',
        'addedByNic': widget.userNic,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Step 3: Save to 'issues' collection
      await FirebaseFirestore.instance.collection('issues').add(issueData);

      // Step 4: Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Building Issue Reported Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report issue: $e'),
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

  // --- NEW: Function to Update an existing issue ---
  Future<void> _updateIssue() async {
    if (!_formKey.currentState!.validate()) return;
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
      // Step 1: Upload *only new* images
      List<String> newlyUploadedImageUrls = await _uploadImages();
      if (_selectedImages.isNotEmpty && newlyUploadedImageUrls.isEmpty) {
        throw Exception('Failed to upload new images.');
      }

      // Step 2: Combine existing and newly uploaded images
      List<String> finalImageUrls = [];
      finalImageUrls.addAll(_existingImageUrls); // Add remaining old images
      finalImageUrls.addAll(newlyUploadedImageUrls); // Add new images

      // Step 3: Prepare Data
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'numFloors': int.tryParse(_floorsController.text.trim()) ?? 0,
        'numClassrooms': int.tryParse(_classroomsController.text.trim()) ?? 0,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': finalImageUrls, // Use the combined list
        // Note: We might not want to reset the status on an edit
        // 'status': 'Pending', // Uncomment if status should be reset
        'lastUpdatedTimestamp': FieldValue.serverTimestamp(), // Add update time
      };

      // Step 4: Update Firestore document
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId!)
          .update(issueData);

      // Step 5: Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue Updated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back from edit screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update issue: $e'),
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

  // Function to show the Date Picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          // --- MODIFIED: Dynamic Title ---
          _isEditMode
              ? "Edit Building Issue"
              : "Add your school building Issues",
          style:
              const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _primaryColor))
                : OutlinedButton(
                    onPressed: _handleSubmit, // --- MODIFIED: Use new handler ---
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                    child: Text(
                      // --- MODIFIED: Dynamic Button Text ---
                      _isEditMode ? "Update" : "Save",
                      style: const TextStyle(
                          color: _primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isPageLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField("School Name", "Enter Your School name",
                          _schoolNameController,
                          isNumber: false),
                      _buildDropdown(
                        "Select Damage Building",
                        "select Type of Damage Building",
                        _buildingTypes,
                        _selectedBuilding,
                        (String? value) {
                          setState(() {
                            _selectedBuilding = value;
                          });
                        },
                      ),
                      _buildTextField(
                          "Number of Floors",
                          "Enter number of floors in building",
                          _floorsController,
                          isNumber: true),
                      _buildTextField(
                          "Number of Classrooms",
                          "Enter Number of rooms in building",
                          _classroomsController,
                          isNumber: true),
                      _buildDropdown(
                        "Type Of Damage",
                        "select Type of Damage",
                        _damageTypes,
                        _selectedDamageType,
                        (String? value) {
                          setState(() {
                            _selectedDamageType = value;
                          });
                        },
                      ),
                      _buildDescriptionField(
                          "Description of Issue",
                          "Describe your School building Issue",
                          _descriptionController),
                      _buildUploadImagesSection(), // --- MODIFIED: Handles edit mode
                      _buildDateField(
                          "Date Of Damage Occurance",
                          "Enter Date Of Damage Occurance",
                          _dateController,
                          _selectDate),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- Helper Widgets (Unchanged) ---
  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {required bool isNumber}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: _textFieldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter $label';
              }
              if (isNumber && int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items,
      String? currentValue, Function(String? value) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: _textFieldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12)
                      .copyWith(top: 14, bottom: 14),
            ),
            isExpanded: true,
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) =>
                value == null ? 'Please select $label' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(
      String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: _textFieldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter $label' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, String hint,
      TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: _textFieldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              suffixIcon:
                  const Icon(Icons.calendar_today_outlined, color: Colors.grey),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please select $label' : null,
          ),
        ],
      ),
    );
  }

  // --- HEAVILY MODIFIED: Builder for the Upload Images section ---
  Widget _buildUploadImagesSection() {
    bool hasImages =
        _existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Images (JPG/PNG)',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),

          // --- MODIFIED: Image Preview Grid ---
          if (hasImages)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 100, // Fixed height for the horizontal list
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  // Total count is existing + new
                  itemCount:
                      _existingImageUrls.length + _selectedImages.length,
                  itemBuilder: (context, index) {
                    // --- Part 1: Display Existing Images (from Network) ---
                    if (index < _existingImageUrls.length) {
                      final imageUrl = _existingImageUrls[index];
                      return _buildImagePreview(
                        onRemove: () => _removeExistingImage(index),
                        child: Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                            width: 100,
                            height: 100,
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      );
                    }

                    // --- Part 2: Display New Images (from Memory) ---
                    final newImageIndex = index - _existingImageUrls.length;
                    final imageFile = _selectedImages[newImageIndex];
                    return _buildImagePreview(
                      onRemove: () => _removeNewImage(newImageIndex),
                      child: FutureBuilder<Uint8List>(
                        future: imageFile.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done &&
                              snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            );
                          }
                          return const SizedBox(
                            width: 100,
                            height: 100,
                            child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

          // --- Upload Button ---
          InkWell(
            onTap: _pickImages,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: _textFieldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasImages ? _primaryColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 28,
                      color: hasImages ? _primaryColor : Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    !hasImages
                        ? 'Tap to Upload Building Damage Photos'
                        : 'Tap to Add More Photos (${_existingImageUrls.length + _selectedImages.length} selected)',
                    style: TextStyle(
                        color: hasImages ? Colors.black87 : Colors.grey,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Helper for image preview (to add the 'X' button) ---
  Widget _buildImagePreview({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}