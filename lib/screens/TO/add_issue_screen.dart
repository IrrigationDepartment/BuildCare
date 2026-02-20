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
<<<<<<< HEAD
=======
  final String? issueId; // <-- ADDED: Nullable issueId for edit mode
  // Kept userNic parameter
  final String userNic;

  const AddIssueScreen({super.key, required this.userNic});
  final String userNic;
>>>>>>> main
  final String? issueId;

  const AddIssueScreen({
    super.key,
    required this.userNic,
<<<<<<< HEAD
=======
    this.issueId, // <-- ADDED
>>>>>>> main
    this.issueId,
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

<<<<<<< HEAD
=======
  // --- NEW: State for Edit Mode ---
  bool get _isEditMode => widget.issueId != null;
  bool _isLoading = false;
  bool _isPageLoading = false; // For loading data in edit mode

  // --- MODIFIED: Image lists for edit mode ---
  final List<XFile> _selectedImages = []; // New images to upload
  List<String> _existingImageUrls = []; // Existing images from server
  // Switched to XFile for cross-platform image handling
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false; // Added loading state

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

  // --- CONTENT FROM add_building_issues.dart ---
>>>>>>> main
  bool get _isEditMode => widget.issueId != null;
  bool _isLoading = false;
  bool _isPageLoading = false;

<<<<<<< HEAD
  final List<XFile> _selectedImages = []; 
  List<String> _existingImageUrls = []; 
=======
  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
>>>>>>> main
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

<<<<<<< HEAD
  final List<String> _buildingTypes = [
    'Academic Classroom', 'Office', 'Science Lab', 'Technology Lab', 'Library',
    'Hostel', 'Computer Lab', 'Dahampasala Lab', 'Store Room', 'Auditorium',
    'Main Hall', 'Changing Room', 'Security Room', 'Wash Room', 'Boundary Wall'
  ];

  final List<String> _damageTypes = [
    'Foundation & Wall Damage', 'Roofing Damage', 'Utility Damage (Electricity/Water)',
    'Floor Damage', 'Plumbing/Draining Structural Issue', 'Windows/Doors Frame Damage',
    'Staircase & Corridor Damage'
  ];
=======
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
  // --- END OF NEW CONTENT ---
>>>>>>> main

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

<<<<<<< HEAD
  Future<void> _loadIssueData() async {
    setState(() => _isPageLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('issues').doc(widget.issueId!).get();
=======
  // --- NEW: Load data for Edit Mode ---
  // --- Image Picker Function (MODIFIED for multi-select) ---
  Future<void> _pickImages() async {
    // Allows picking multiple images
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
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
>>>>>>> main
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _schoolNameController.text = data['schoolName'] ?? '';
        _floorsController.text = data['numFloors']?.toString() ?? '';
        _classroomsController.text = data['numClassrooms']?.toString() ?? '';
        _descriptionController.text = data['description'] ?? '';
<<<<<<< HEAD
=======

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
>>>>>>> main
        _selectedBuilding = data['buildingName'];
        _selectedDamageType = data['damageType'];
        if (data['dateOfOccurance'] != null) {
          _selectedDate = (data['dateOfOccurance'] as Timestamp).toDate();
<<<<<<< HEAD
          _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
=======
          _dateController.text =
              DateFormat('yyyy-MM-dd').format(_selectedDate!);
>>>>>>> main
        }
        _existingImageUrls = List<String>.from(data['imageUrls'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isPageLoading = false);
    }
  }

  Future<void> _pickImages() async {
<<<<<<< HEAD
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
=======
    final List<XFile> pickedFiles =
        await _picker.pickMultiImage(imageQuality: 70);
>>>>>>> main
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

<<<<<<< HEAD
  void _removeNewImage(int index) => setState(() => _selectedImages.removeAt(index));
  void _removeExistingImage(int index) => setState(() => _existingImageUrls.removeAt(index));
=======
  // --- MODIFIED: Image Remover Functions ---
  void _removeNewImage(int index) {
  // --- Image Remover Function ---
  void _removeImage(int index) {
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
    
  // --- 1. Upload Images to Server Function (From add_building_issues.dart) ---
  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      return [];
    }

    // --- USING THE NEW LINK ---
  void _removeNewImage(int index) =>
      setState(() => _selectedImages.removeAt(index));
  void _removeExistingImage(int index) =>
      setState(() => _existingImageUrls.removeAt(index));
>>>>>>> main

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    var uri = Uri.parse("https://buildcare.atigalle.x10.mx/");
    var request = http.MultipartRequest("POST", uri);

    for (var imageFile in _selectedImages) {
      var fileBytes = await imageFile.readAsBytes();
<<<<<<< HEAD
      request.files.add(http.MultipartFile.fromBytes('images[]', fileBytes, filename: imageFile.name));
=======
      var file = http.MultipartFile.fromBytes(
        'images[]',
        'images[]', // This key 'images[]' MUST match the PHP script
        fileBytes,
        filename: imageFile.name,
      );
      request.files.add(file);
    }
    try {
      var response = await request.send();

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['status'] == 'success') {
          return List<String>.from(decodedResponse['imageUrls']);
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
      request.files.add(http.MultipartFile.fromBytes('images[]', fileBytes,
          filename: imageFile.name));
>>>>>>> main
    }
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);
<<<<<<< HEAD
        return decodedResponse['status'] == 'success' ? List<String>.from(decodedResponse['imageUrls']) : [];
=======
        return decodedResponse['status'] == 'success'
            ? List<String>.from(decodedResponse['imageUrls'])
            : [];
>>>>>>> main
      }
      return [];
    } catch (e) {
      return [];
    }
  }

<<<<<<< HEAD
  Future<void> _handleSubmit() async {
    if (_isEditMode) { await _updateIssue(); } else { await _addNewIssue(); }
=======
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
  // --- 2. Main Save Function (NEW from add_building_issues.dart) ---
  Future<void> _saveIssue() async {
    // 1. Validation
    if (!_formKey.currentState!.validate()) {
      return;
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
        throw Exception(
            'Failed to upload images. Please check server connection.');
      }

      // Step 2: Prepare Data

      if (_selectedImages.isNotEmpty && uploadedImageUrls.isEmpty) {
        throw Exception('Failed to upload images. Please check server connection.');
      }

      // Step 2: Prepare Data (Using new dropdown fields)
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding, // From Dropdown
        'numFloors': int.tryParse(_floorsController.text.trim()) ?? 0,
        'numClassrooms': int.tryParse(_classroomsController.text.trim()) ?? 0,
        'damageType': _selectedDamageType, // From Dropdown
        'issueTitle': '$_selectedBuilding - $_selectedDamageType', // Generated Title
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': uploadedImageUrls,
        'status': 'Pending', // Default status
  Future<void> _handleSubmit() async {
    if (_isEditMode) {
      await _updateIssue();
    } else {
      await _addNewIssue();
    }
>>>>>>> main
  }

  Future<void> _addNewIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date.')));
=======
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a date.')));
>>>>>>> main
      return;
    }
    setState(() => _isLoading = true);
    try {
      List<String> uploadedImageUrls = await _uploadImages();
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

<<<<<<< HEAD
      DocumentReference issueRef = await FirebaseFirestore.instance.collection('issues').add(issueData);

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Building Issue Reported',
        'subtitle': '${_schoolNameController.text.trim()}: $_selectedDamageType',
=======
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
      // Step 5: Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report issue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Step 6: Reset loading state
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
  // Function to show the Date Picker
      DocumentReference issueRef =
          await FirebaseFirestore.instance.collection('issues').add(issueData);

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Building Issue Reported',
        'subtitle':
            '${_schoolNameController.text.trim()}: $_selectedDamageType',
>>>>>>> main
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'issue',
        'issueId': issueRef.id,
        'addedByNic': widget.userNic,
      });

      if (mounted) {
<<<<<<< HEAD
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported Successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
=======
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reported Successfully!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
>>>>>>> main
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateIssue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      List<String> newlyUploadedImageUrls = await _uploadImages();
<<<<<<< HEAD
      List<String> finalImageUrls = [..._existingImageUrls, ...newlyUploadedImageUrls];
=======
      List<String> finalImageUrls = [
        ..._existingImageUrls,
        ...newlyUploadedImageUrls
      ];
>>>>>>> main

      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'numFloors': int.tryParse(_floorsController.text.trim()) ?? 0,
        'numClassrooms': int.tryParse(_classroomsController.text.trim()) ?? 0,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
<<<<<<< HEAD
=======
        'imageUrls': finalImageUrls, // Use the combined list
        // Note: We might not want to reset the status on an edit
        // 'status': 'Pending', // Uncomment if status should be reset
        'lastUpdatedTimestamp': FieldValue.serverTimestamp(), // Add update time
      };

      // Step 4: Update Firestore document
>>>>>>> main
        'imageUrls': finalImageUrls,
        'lastUpdatedTimestamp': FieldValue.serverTimestamp(),
      };

<<<<<<< HEAD
      await FirebaseFirestore.instance.collection('issues').doc(widget.issueId!).update(issueData);
=======
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
>>>>>>> main
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Update Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
<<<<<<< HEAD
      context: context, initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime.now(),
=======
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
>>>>>>> main
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(_isEditMode ? "Edit Building Issue" : "Report Building Issue", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: _isLoading ? const Center(child: CircularProgressIndicator(strokeWidth: 2)) : OutlinedButton(
              onPressed: _handleSubmit,
              child: Text(_isEditMode ? "Update" : "Save"),
            ),
=======
    // --- USING THE NEW UI from add_building_issues.dart ---
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
        title: const Text(
          "Add your school building Issues",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
        title: Text(
            _isEditMode ? "Edit Building Issue" : "Report Building Issue",
            style:
                TextStyle(color: _primaryColor, fontWeight: FontWeight.w600)),
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
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor))
                : OutlinedButton(
                    onPressed: _saveIssue, // Calls the Firebase save function
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(color: _primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : OutlinedButton(
                    onPressed: _handleSubmit,
                    child: Text(_isEditMode ? "Update" : "Save"),
                  ),
>>>>>>> main
          ),
        ],
      ),
      body: SafeArea(
<<<<<<< HEAD
        child: _isPageLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
=======
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
        child: SingleChildScrollView(
>>>>>>> main
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
<<<<<<< HEAD
                _buildTextField("School Name", "Enter school name", _schoolNameController, isNumber: false),
                _buildDropdown("Damage Building", "Select building", _buildingTypes, _selectedBuilding, (val) => setState(() => _selectedBuilding = val)),
                _buildTextField("Floors", "Number of floors", _floorsController, isNumber: true),
                _buildTextField("Classrooms", "Number of rooms", _classroomsController, isNumber: true),
                _buildDropdown("Damage Type", "Select type", _damageTypes, _selectedDamageType, (val) => setState(() => _selectedDamageType = val)),
                _buildDescriptionField("Description", "Describe the issue", _descriptionController),
                _buildUploadImagesSection(),
                _buildDateField("Date", "Select date", _dateController, _selectDate),
=======
                _buildTextField("School Name", "Enter Your School name", _schoolNameController, isNumber: false),
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
                _buildTextField("Number of Floors", "Enter number of floors in building", _floorsController, isNumber: true),
                _buildTextField("Number of Classrooms", "Enter Number of rooms in building", _classroomsController, isNumber: true),
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
                _buildDescriptionField("Description of Issue", "Describe your School building Issue", _descriptionController),
                _buildUploadImagesSection(),
                _buildDateField("Date Of Damage Occurance", "Enter Date Of Damage Occurance", _dateController, _selectDate),
>>>>>>> main
              ],
            ),
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildTextField(String label, String hint, TextEditingController controller, {required bool isNumber}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
=======
  // --- Helper Widgets (From add_building_issues.dart) ---

  /// Reusable Text Field builder
  Widget _buildTextField(String label, String hint, TextEditingController controller, {required bool isNumber}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
  /// Reusable Dropdown Field builder
  Widget _buildDropdown(
      String label,
      String hint,
      List<String> items,
      String? currentValue,
      Function(String? value) onChanged) {
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
            initialValue: currentValue,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 14, bottom: 14),
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
            validator: (value) => value == null ? 'Please select $label' : null,
          ),
        ],
      ),
    );
  }

  /// Specific builder for the Description field (Multiline Text Field).
  Widget _buildDescriptionField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: 4,
            maxLines: 4, // Allow multiline input
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
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
          ),
        ],
      ),
    );
  }

  /// Builder for the Date Of Damage Occurance field.
  Widget _buildDateField(String label, String hint, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            readOnly: true, // Prevent manual typing
            onTap: onTap, // Open date picker on tap
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

              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              // Calendar icon at the end
              suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
            ),
            validator: (value) => value!.isEmpty ? 'Please select $label' : null,
          ),
        ],
      ),
    );
  }

  /// MODIFIED Builder for the Upload Images section (Uses XFile and Image.memory).
  Widget _buildUploadImagesSection() {
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
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),

          // --- Image Preview Grid (Uses FutureBuilder/Image.memory for XFile) ---
          if (_selectedImages.isNotEmpty)
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
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    // Use FutureBuilder to read the image bytes asynchronously
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<Uint8List>(
                              future: _selectedImages[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
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
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
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
            onTap: _pickImages, // Call the image picker function
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: _textFieldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasImages ? _primaryColor : Colors.transparent,
                  color: _selectedImages.isEmpty ? Colors.transparent : _primaryColor,
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
                  Icon(Icons.cloud_upload_outlined, size: 28, color: _selectedImages.isEmpty ? Colors.grey : _primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    _selectedImages.isEmpty
                        ? 'Tap to Upload Building Damage Photos'
                        : 'Tap to Add More Photos (${_selectedImages.length} selected)',
                    style: TextStyle(color: _selectedImages.isEmpty ? Colors.grey : Colors.black87, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
}
        child: _isPageLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField("School Name", "Enter school name",
                          _schoolNameController,
                          isNumber: false),
                      _buildDropdown(
                          "Damage Building",
                          "Select building",
                          _buildingTypes,
                          _selectedBuilding,
                          (val) => setState(() => _selectedBuilding = val)),
                      _buildTextField(
                          "Floors", "Number of floors", _floorsController,
                          isNumber: true),
                      _buildTextField("Classrooms", "Number of rooms",
                          _classroomsController,
                          isNumber: true),
                      _buildDropdown(
                          "Damage Type",
                          "Select type",
                          _damageTypes,
                          _selectedDamageType,
                          (val) => setState(() => _selectedDamageType = val)),
                      _buildDescriptionField("Description",
                          "Describe the issue", _descriptionController),
                      _buildUploadImagesSection(),
                      _buildDateField(
                          "Date", "Select date", _dateController, _selectDate),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {required bool isNumber}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
>>>>>>> main
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
<<<<<<< HEAD
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
=======
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: _textFieldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none)),
>>>>>>> main
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ]),
    );
  }

<<<<<<< HEAD
  Widget _buildDropdown(String label, String hint, List<String> items, String? val, Function(String?) onChanged) {
=======
  Widget _buildDropdown(String label, String hint, List<String> items,
      String? val, Function(String?) onChanged) {
>>>>>>> main
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
<<<<<<< HEAD
          value: val, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged, decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
=======
          value: val,
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: _textFieldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none)),
>>>>>>> main
          validator: (v) => v == null ? 'Required' : null,
        ),
      ]),
    );
  }

<<<<<<< HEAD
  Widget _buildDescriptionField(String label, String hint, TextEditingController controller) {
=======
  Widget _buildDescriptionField(
      String label, String hint, TextEditingController controller) {
>>>>>>> main
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
<<<<<<< HEAD
        TextFormField(controller: controller, maxLines: 4, decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
=======
        TextFormField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: _textFieldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none))),
>>>>>>> main
      ]),
    );
  }

  Widget _buildUploadImagesSection() {
<<<<<<< HEAD
    bool hasImages = _existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Upload Images', style: TextStyle(fontWeight: FontWeight.w600)),
=======
    bool hasImages =
        _existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Upload Images',
            style: TextStyle(fontWeight: FontWeight.w600)),
>>>>>>> main
        const SizedBox(height: 8),
        if (hasImages)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length + _selectedImages.length,
              itemBuilder: (context, index) {
                if (index < _existingImageUrls.length) {
<<<<<<< HEAD
                  return _buildImagePreview(onRemove: () => _removeExistingImage(index), child: Image.network(_existingImageUrls[index], width: 100, fit: BoxFit.cover));
=======
                  return _buildImagePreview(
                      onRemove: () => _removeExistingImage(index),
                      child: Image.network(_existingImageUrls[index],
                          width: 100, fit: BoxFit.cover));
>>>>>>> main
                }
                final newIdx = index - _existingImageUrls.length;
                return _buildImagePreview(
                  onRemove: () => _removeNewImage(newIdx),
                  child: FutureBuilder<Uint8List>(
                    future: _selectedImages[newIdx].readAsBytes(),
                    builder: (context, snapshot) {
<<<<<<< HEAD
                      if (snapshot.hasData) return Image.memory(snapshot.data!, width: 100, fit: BoxFit.cover);
                      return const SizedBox(width: 100, child: Center(child: CircularProgressIndicator()));
=======
                      if (snapshot.hasData)
                        return Image.memory(snapshot.data!,
                            width: 100, fit: BoxFit.cover);
                      return const SizedBox(
                          width: 100,
                          child: Center(child: CircularProgressIndicator()));
>>>>>>> main
                    },
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImages,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
<<<<<<< HEAD
            decoration: BoxDecoration(color: _textFieldBackgroundColor, borderRadius: BorderRadius.circular(10)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined), SizedBox(width: 10), Text('Tap to Upload Photos')]),
=======
            decoration: BoxDecoration(
                color: _textFieldBackgroundColor,
                borderRadius: BorderRadius.circular(10)),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined),
                  SizedBox(width: 10),
                  Text('Tap to Upload Photos')
                ]),
>>>>>>> main
          ),
        ),
      ]),
    );
  }

<<<<<<< HEAD
  Widget _buildImagePreview({required Widget child, required VoidCallback onRemove}) {
=======
  Widget _buildImagePreview(
      {required Widget child, required VoidCallback onRemove}) {
>>>>>>> main
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
<<<<<<< HEAD
        Positioned(right: 0, child: GestureDetector(onTap: onRemove, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 18, color: Colors.white)))),
=======
        Positioned(
            right: 0,
            child: GestureDetector(
                onTap: onRemove,
                child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 18, color: Colors.white)))),
>>>>>>> main
      ]),
    );
  }

<<<<<<< HEAD
  Widget _buildDateField(String label, String hint, TextEditingController controller, VoidCallback onTap) {
=======
  Widget _buildDateField(String label, String hint,
      TextEditingController controller, VoidCallback onTap) {
>>>>>>> main
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
<<<<<<< HEAD
        TextFormField(controller: controller, readOnly: true, onTap: onTap, decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), suffixIcon: const Icon(Icons.calendar_today))),
      ]),
    );
  }
}
=======
        TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: _textFieldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                suffixIcon: const Icon(Icons.calendar_today))),
      ]),
    );
  }
}
>>>>>>> main
