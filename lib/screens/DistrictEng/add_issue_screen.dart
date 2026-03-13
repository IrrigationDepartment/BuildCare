import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AddIssueScreen extends StatefulWidget {
  final String userNic;
  final String? issueId;

  const AddIssueScreen({
    super.key,
    required this.userNic,
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

  bool get _isEditMode => widget.issueId != null;
  bool _isLoading = false;
  bool _isPageLoading = false;

  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

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

  Future<void> _loadIssueData() async {
    setState(() => _isPageLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId!)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _schoolNameController.text = data['schoolName'] ?? '';
          _floorsController.text = data['numFloors']?.toString() ?? '';
          _classroomsController.text = data['numClassrooms']?.toString() ?? '';
          _descriptionController.text = data['description'] ?? '';
          _selectedBuilding = data['buildingName'];
          _selectedDamageType = data['damageType'];
          if (data['dateOfOccurance'] != null) {
            _selectedDate = (data['dateOfOccurance'] as Timestamp).toDate();
            _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          }
          _existingImageUrls = List<String>.from(data['imageUrls'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isPageLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() => _selectedImages.addAll(pickedFiles));
    }
  }

  void _removeNewImage(int index) => setState(() => _selectedImages.removeAt(index));
  void _removeExistingImage(int index) => setState(() => _existingImageUrls.removeAt(index));

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    var uri = Uri.parse("http://98.94.30.13/");
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

  Future<void> _handleSubmit() async {
    if (_isEditMode) {
      await _updateIssue();
    } else {
      await _addNewIssue();
    }
  }

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

      await FirebaseFirestore.instance.collection('issues').add(issueData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported Successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateIssue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      List<String> newlyUploadedImageUrls = await _uploadImages();
      List<String> finalImageUrls = [..._existingImageUrls, ...newlyUploadedImageUrls];

      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'numFloors': int.tryParse(_floorsController.text.trim()) ?? 0,
        'numClassrooms': int.tryParse(_classroomsController.text.trim()) ?? 0,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': finalImageUrls,
        'lastUpdatedTimestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('issues').doc(widget.issueId!).update(issueData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated Successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Update Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(_isEditMode ? "Edit Building Issue" : "Report Building Issue",
            style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : OutlinedButton(onPressed: _handleSubmit, child: Text(_isEditMode ? "Update" : "Save")),
          ),
        ],
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField("School Name", "Enter school name", _schoolNameController, isNumber: false),
                    _buildDropdown("Damage Building", "Select building", _buildingTypes, _selectedBuilding, (val) => setState(() => _selectedBuilding = val)),
                    _buildTextField("Floors", "Number of floors", _floorsController, isNumber: true),
                    _buildTextField("Classrooms", "Number of rooms", _classroomsController, isNumber: true),
                    _buildDropdown("Damage Type", "Select type", _damageTypes, _selectedDamageType, (val) => setState(() => _selectedDamageType = val)),
                    _buildDescriptionField("Description", "Describe the issue", _descriptionController),
                    _buildUploadImagesSection(),
                    _buildDateField("Date", "Select date", _dateController, _selectDate),
                  ],
                ),
              ),
            ),
    );
  }

  // --- UI Components ---
  Widget _buildTextField(String label, String hint, TextEditingController controller, {required bool isNumber}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ]),
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items, String? val, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: val,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          validator: (v) => v == null ? 'Required' : null,
        ),
      ]),
    );
  }

  Widget _buildDescriptionField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
        ),
      ]),
    );
  }

  Widget _buildUploadImagesSection() {
    bool hasImages = _existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Upload Images', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (hasImages)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length + _selectedImages.length,
              itemBuilder: (context, index) {
                if (index < _existingImageUrls.length) {
                  return _buildImagePreview(onRemove: () => _removeExistingImage(index), child: Image.network(_existingImageUrls[index], width: 100, fit: BoxFit.cover));
                }
                final newIdx = index - _existingImageUrls.length;
                return _buildImagePreview(
                  onRemove: () => _removeNewImage(newIdx),
                  child: FutureBuilder<Uint8List>(
                    future: _selectedImages[newIdx].readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) return Image.memory(snapshot.data!, width: 100, fit: BoxFit.cover);
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
            decoration: BoxDecoration(color: _textFieldBackgroundColor, borderRadius: BorderRadius.circular(10)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined), SizedBox(width: 10), Text('Tap to Upload Photos')]),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: _textFieldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), suffixIcon: const Icon(Icons.calendar_today)),
        ),
      ]),
    );
  }
}