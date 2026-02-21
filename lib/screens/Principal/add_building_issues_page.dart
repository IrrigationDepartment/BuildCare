import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class AddBuildingIssuesPage extends StatefulWidget {
  final String userNic;
  final String? issueId;

  const AddBuildingIssuesPage({
    super.key,
    required this.userNic,
    this.issueId,
  });

  @override
  State<AddBuildingIssuesPage> createState() => _AddBuildingIssuesPageState();
}

class _AddBuildingIssuesPageState extends State<AddBuildingIssuesPage> {
  final _formKey = GlobalKey<FormState>();

  // --- UI Controllers ---
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedBuilding;
  String? _selectedDamageType;
  DateTime? _selectedDate;

  // Logic flags
  bool get _isEditMode => widget.issueId != null;
  bool _isLoading = false;
  bool _isPageLoading = false;

  // Image Management
  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  // Color Palette
  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

  // Dropdown Options
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isPageLoading = true);

    if (_isEditMode) {
      await _loadIssueData();
    } else {
      await _fetchSchoolFromUserNic();
    }

    if (mounted) {
      setState(() => _isPageLoading = false);
    }
  }

  // --- Fetch School based on User NIC ---
  Future<void> _fetchSchoolFromUserNic() async {
    try {
      // Find the user document using the NIC
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: widget.userNic)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        var userData = userQuery.docs.first.data() as Map<String, dynamic>;
        // Extract the school name associated with this user
        String? linkedSchool = userData['schoolName'];
        
        if (linkedSchool != null && linkedSchool.isNotEmpty) {
          _schoolNameController.text = linkedSchool;
        } else {
          _schoolNameController.text = 'School Not Found in Profile';
        }
      }
    } catch (e) {
      debugPrint("Error fetching user school details: $e");
    }
  }

  // --- Fetch existing data if in Edit Mode ---
  Future<void> _loadIssueData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('issues').doc(widget.issueId!).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _schoolNameController.text = data['schoolName'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _selectedBuilding = data['buildingName'];
        _selectedDamageType = data['damageType'];
        if (data['dateOfOccurance'] != null) {
          _selectedDate = (data['dateOfOccurance'] as Timestamp).toDate();
          _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        }
        _existingImageUrls = List<String>.from(data['imageUrls'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- Image Handling Logic ---
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() => _selectedImages.addAll(pickedFiles));
    }
  }

  void _removeNewImage(int index) => setState(() => _selectedImages.removeAt(index));
  void _removeExistingImage(int index) => setState(() => _existingImageUrls.removeAt(index));

  // --- Upload images to External PHP Hosting ---
  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    var uri = Uri.parse("https://buildcare.atigalle.x10.mx/index.php");
    var request = http.MultipartRequest("POST", uri);

    for (var imageFile in _selectedImages) {
      var fileBytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('images[]', fileBytes, filename: imageFile.name));
    }
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);
        return decodedResponse['status'] == 'success' ? List<String>.from(decodedResponse['imageUrls']) : [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- Form Submission Logic ---
  Future<void> _handleSubmit() async {
    if (_isEditMode) {
      await _updateIssue();
    } else {
      await _addNewIssue();
    }
  }

  // Create New Record
  Future<void> _addNewIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      List<String> uploadedImageUrls = await _uploadImages();
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': uploadedImageUrls,
        'status': 'Pending',
        'addedByNic': widget.userNic,
        'timestamp': FieldValue.serverTimestamp(),
      };

      DocumentReference issueRef = await FirebaseFirestore.instance.collection('issues').add(issueData);

      // Trigger Cloud Notification for Admins
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Building Issue Reported',
        'subtitle': '${_schoolNameController.text.trim()}: $_selectedDamageType',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'issue',
        'issueId': issueRef.id,
        'addedByNic': widget.userNic,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported Successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Update Existing Record
  Future<void> _updateIssue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      List<String> newlyUploadedImageUrls = await _uploadImages();
      List<String> finalImageUrls = [..._existingImageUrls, ...newlyUploadedImageUrls];

      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': finalImageUrls,
        'lastUpdatedTimestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('issues').doc(widget.issueId!).update(issueData);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Update Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime.now(),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(_isEditMode ? "Edit Building Issue" : "Add School Building Issues", 
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: _isLoading ? const Center(child: CircularProgressIndicator(strokeWidth: 2)) : OutlinedButton(
              onPressed: _handleSubmit,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: _primaryColor)),
              child: Text(_isEditMode ? "Update" : "Save", style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isPageLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("School Name", "School Name", _schoolNameController, readOnly: true), // Made Read-Only
                _buildDropdown("Select Damage Building", "Select Type of Damage Building", _buildingTypes, _selectedBuilding, (val) => setState(() => _selectedBuilding = val)),
                _buildDropdown("Type Of Damage", "Select Type of Damage", _damageTypes, _selectedDamageType, (val) => setState(() => _selectedDamageType = val)),
                _buildDescriptionField("Description of Issue", "Describe the School building Issue", _descriptionController),
                _buildUploadImagesSection(),
                _buildDateField("Date Of Damage Occurance", "Enter Date Of Damage Occurance", _dateController, _selectDate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets to keep UI clean ---

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint, 
            filled: true, 
            fillColor: readOnly ? Colors.grey[300] : _textFieldBackgroundColor, // Visual cue that it's read-only
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), 
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12)
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ]),
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items, String? val, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: val, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged, decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
          validator: (v) => v == null ? 'Required' : null,
        ),
      ]),
    );
  }

  Widget _buildDescriptionField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, maxLines: 4, decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(12))),
      ]),
    );
  }

  Widget _buildUploadImagesSection() {
    bool hasImages = _existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Upload Images (JPG/PNG)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        if (hasImages)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length + _selectedImages.length,
              itemBuilder: (context, index) {
                // Display images already stored in Cloud
                if (index < _existingImageUrls.length) {
                  return _buildImagePreview(onRemove: () => _removeExistingImage(index), child: Image.network(_existingImageUrls[index], width: 100, height: 100, fit: BoxFit.cover));
                }
                // Display images newly picked from Device
                final newIdx = index - _existingImageUrls.length;
                return _buildImagePreview(
                  onRemove: () => _removeNewImage(newIdx),
                  child: FutureBuilder<Uint8List>(
                    future: _selectedImages[newIdx].readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) return Image.memory(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover);
                      return const SizedBox(width: 100, child: Center(child: CircularProgressIndicator()));
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
            decoration: BoxDecoration(color: _textFieldBackgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: hasImages ? _primaryColor : Colors.transparent)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, color: Colors.grey), SizedBox(width: 10), Text('Tap to Upload Building Damage Photos', style: TextStyle(color: Colors.grey))]),
          ),
        ),
      ]),
    );
  }

  Widget _buildImagePreview({required Widget child, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        Positioned(right: 0, child: GestureDetector(onTap: onRemove, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 18, color: Colors.white)))),
      ]),
    );
  }

  Widget _buildDateField(String label, String hint, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller, 
          readOnly: true, 
          onTap: onTap, 
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey), contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ]),
    );
  }
}