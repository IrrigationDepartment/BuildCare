import 'dart:convert'; // For jsonDecode
import 'package:flutter/foundation.dart'; // For debugPrint, Uint8List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // For XFile
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // For Uint8List, though imported via foundation above, good for clarity

// --- REMOVED dart:io as we use XFile/Uint8List for cross-platform support ---

class AddBuildingIssuesPage extends StatefulWidget {
  // Added userNic parameter, consistent with add_issue_screen.dart
  final String userNic;
  // Optional parameters for editing
  final String? issueId;
  final Map<String, dynamic>? issueData;

  const AddBuildingIssuesPage({
    super.key,
    required this.userNic,
    this.issueId,
    this.issueData,
  });

  @override
  State<AddBuildingIssuesPage> createState() => _AddBuildingIssuesPageState();
}

class _AddBuildingIssuesPageState extends State<AddBuildingIssuesPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _classroomsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedBuilding;
  String? _selectedDamageType;
  DateTime? _selectedDate;

  // Switched to XFile for cross-platform image handling
  final List<XFile> _selectedNewImages =
      []; //  Renamed for clarity: new images picked
  final List<String> _existingImageUrls =
      []; //  NEW: For images already in Firebase
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false; // Added loading state

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

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
    // If editing, populate the fields with existing data
    if (widget.issueId != null && widget.issueData != null) {
      _schoolNameController.text = widget.issueData!['schoolName'] ?? '';
      _floorsController.text = (widget.issueData!['numFloors'] ?? 0).toString();
      _classroomsController.text =
          (widget.issueData!['numClassrooms'] ?? 0).toString();
      _descriptionController.text = widget.issueData!['description'] ?? '';
      _selectedBuilding = widget.issueData!['buildingName'];
      _selectedDamageType = widget.issueData!['damageType'];

      // Handle date
      if (widget.issueData!['dateOfOccurance'] != null) {
        final Timestamp timestamp = widget.issueData!['dateOfOccurance'];
        _selectedDate = timestamp.toDate();
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }

      // Populate existing image URLs
      if (widget.issueData!['imageUrls'] is List) {
        _existingImageUrls
            .addAll(List<String>.from(widget.issueData!['imageUrls']));
      }
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

  // --- Image Picker Function (MODIFIED for multi-select) ---
  Future<void> _pickImages() async {
    // Allows picking multiple images
    final List<XFile> pickedFiles =
        await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedNewImages.addAll(pickedFiles); // Add to new images list
      });
    }
  }

  // --- Image Remover Function for NEWLY selected images ---
  void _removeNewImage(int index) {
    setState(() {
      _selectedNewImages.removeAt(index);
    });
  }

  //  NEW: Image Remover Function for EXISTING network images ---
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
    // NOTE: The actual deletion from storage (e.g., Firebase Storage)
    // would typically happen when you save/update the issue, not immediately here,
    // to allow the user to cancel changes. For now, it just removes from the list.
  }

  // --- 1. Upload Images to Server Function (Copied from add_issue_screen.dart) ---
  Future<List<String>> _uploadNewImages() async {
    //  Renamed to reflect it uploads NEW images
    if (_selectedNewImages.isEmpty) {
      return [];
    }

    // --- REPLACE WITH YOUR NEW LINK ---
    var uri = Uri.parse("https://buildcare.atigalle.x10.mx/index.php");
    var request = http.MultipartRequest("POST", uri);

    for (var imageFile in _selectedNewImages) {
      var fileBytes = await imageFile.readAsBytes();
      var file = http.MultipartFile.fromBytes(
        'images[]', // This key 'images[]' MUST match the PHP script
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

  // --- 2. Main Save Function (UPDATED to support editing) ---
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
      // Step 1: Upload NEW images (only if new images are selected)
      List<String> newlyUploadedImageUrls = [];
      if (_selectedNewImages.isNotEmpty) {
        newlyUploadedImageUrls = await _uploadNewImages();
        if (newlyUploadedImageUrls.isEmpty && _selectedNewImages.isNotEmpty) {
          // Only throw if there were new images but none uploaded successfully
          throw Exception(
              'Failed to upload new images. Please check server connection.');
        }
      }

      //  Combine existing and newly uploaded image URLs
      List<String> allImageUrls =
          List.from(_existingImageUrls); // Start with existing
      allImageUrls.addAll(newlyUploadedImageUrls); // Add newly uploaded

      // Step 2: Prepare Data
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding, // From Dropdown
        'numFloors': int.tryParse(_floorsController.text.trim()) ?? 0,
        'numClassrooms': int.tryParse(_classroomsController.text.trim()) ?? 0,
        'damageType': _selectedDamageType, // From Dropdown
        'issueTitle':
            '$_selectedBuilding - $_selectedDamageType', // Generated Title
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'addedByNic': widget.userNic,
        'timestamp': FieldValue.serverTimestamp(), // Update timestamp on save
        'imageUrls': allImageUrls, //  Save ALL current image URLs
      };

      // If editing, preserve status; if creating new, set to Pending
      if (widget.issueId == null) {
        issueData['status'] = 'Pending'; // Default status for new issues
      } else {
        // When editing, keep the original status unless changed by an admin later
        issueData['status'] = widget.issueData!['status'] ?? 'Pending';
      }

      // Step 3: Save or Update to 'issues' collection
      if (widget.issueId != null) {
        // UPDATE existing issue
        await FirebaseFirestore.instance
            .collection('issues')
            .doc(widget.issueId)
            .update(issueData);
      } else {
        // CREATE new issue
        await FirebaseFirestore.instance.collection('issues').add(issueData);
      }

      // Step 4: Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.issueId != null
                ? 'Issue Updated Successfully!'
                : 'Building Issue Reported Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        //  Pass true back to indicate a change, prompting dashboard to refresh
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Step 5: Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.issueId != null
                ? 'Failed to update issue: $e'
                : 'Failed to report issue: $e'),
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

  // Function to show the Date Picker (Unchanged, except for renaming the function)
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
    final bool isEditing = widget.issueId != null;

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
          isEditing ? "Edit Building Issue" : "Add your school building Issues",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _primaryColor))
                : OutlinedButton(
                    onPressed: _saveIssue, // Calls the Firebase save function
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                    child: Text(
                      isEditing
                          ? "Update"
                          : "Save", //  Text changes based on mode
                      style: TextStyle(
                          color: _primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                _buildTextField("Number of Floors",
                    "Enter number of floors in building", _floorsController,
                    isNumber: true),
                _buildTextField("Number of Classrooms",
                    "Enter Number of rooms in building", _classroomsController,
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
                // --- MODIFIED: Uses new XFile-based logic ---
                _buildUploadImagesSection(),
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

  // --- Helper Widgets (Unchanged structure) ---

  /// Reusable Text Field builder
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
            inputFormatters: isNumber
                ? [FilteringTextInputFormatter.digitsOnly]
                : null, // ⭐ Only allow digits for number fields
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
              if (value == null || value.isEmpty) {
                // ⭐ Handle null value
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

  /// Reusable Dropdown Field builder
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12)
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
            validator: (value) => value == null ? 'Please select $label' : null,
          ),
        ],
      ),
    );
  }

  /// Specific builder for the Description field (Multiline Text Field).
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
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter $label'
                : null, // ⭐ Handle null value
          ),
        ],
      ),
    );
  }

  /// Builder for the Date Of Damage Occurance field.
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
              // Calendar icon at the end
              suffixIcon:
                  const Icon(Icons.calendar_today_outlined, color: Colors.grey),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Please select $label'
                : null, //  Handle null value
          ),
        ],
      ),
    );
  }

  ///  MODIFIED: Builder for the Upload Images section. Displays existing and new images.
  Widget _buildUploadImagesSection() {
    // Combine both lists for display purposes
    final List<dynamic> allImagesForDisplay = [
      ..._existingImageUrls,
      ..._selectedNewImages
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Images (JPG/PNG)',
            style:
                TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),

          // --- Image Preview Grid (Displays existing network images AND newly picked local images) ---
          if (allImagesForDisplay.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 100, // Fixed height for the horizontal list
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allImagesForDisplay.length,
                  itemBuilder: (context, index) {
                    final item = allImagesForDisplay[index];

                    Widget imageWidget;
                    VoidCallback? removeAction;

                    if (item is String) {
                      // This is an existing network image URL
                      imageWidget = Image.network(
                        item,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, w, p) => p == null
                            ? w
                            : const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                        errorBuilder: (c, o, s) => const Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.grey),
                      );
                      removeAction = () => _removeExistingImage(index);
                    } else if (item is XFile) {
                      // This is a newly selected local image (XFile)
                      // Use FutureBuilder to read the image bytes asynchronously
                      imageWidget = FutureBuilder<Uint8List>(
                        future: item.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
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
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      );
                      // Calculate index relative to _selectedNewImages
                      final newImageIndex = index - _existingImageUrls.length;
                      removeAction = () => _removeNewImage(newImageIndex);
                    } else {
                      imageWidget =
                          const Icon(Icons.error, size: 60, color: Colors.red);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageWidget,
                          ),
                          if (removeAction !=
                              null) // Only show remove button if action exists
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: removeAction,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
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
            onTap: _pickImages, // Call the image picker function
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: _textFieldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (allImagesForDisplay.isEmpty)
                      ? Colors.transparent
                      : _primaryColor, //  Border logic
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 28,
                      color: allImagesForDisplay.isEmpty
                          ? Colors.grey
                          : _primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    allImagesForDisplay.isEmpty
                        ? 'Tap to Upload Building Damage Photos'
                        : 'Tap to Add More Photos (${allImagesForDisplay.length} selected)',
                    style: TextStyle(
                        color: allImagesForDisplay.isEmpty
                            ? Colors.grey
                            : Colors.black87,
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
}
