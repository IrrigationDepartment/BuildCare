import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

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

  // --- NEW COLOR PALETTE ---
  static const Color _primaryIndigo = Color(0xFF6366F1);
  static const Color _accentRose = Color(0xFFF43F5E);
  static const Color _bgSlate = Color(0xFFF8FAFC);
  static const Color _textFieldBg = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);

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
    if (_isEditMode) _loadIssueData();
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

  // (Keeping your logic methods identical as requested)
  Future<void> _loadIssueData() async {
    setState(() => _isPageLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('issues').doc(widget.issueId!).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
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
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isPageLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) setState(() => _selectedImages.addAll(pickedFiles));
  }

  void _removeNewImage(int index) => setState(() => _selectedImages.removeAt(index));
  void _removeExistingImage(int index) => setState(() => _existingImageUrls.removeAt(index));

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    var uri = Uri.parse("https://buildcare.atigalle.x10.mx/");
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
    } catch (e) { return []; }
  }

  Future<void> _handleSubmit() async {
    if (_isEditMode) await _updateIssue(); else await _addNewIssue();
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
      DocumentReference issueRef = await FirebaseFirestore.instance.collection('issues').add(issueData);
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
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => _isLoading = false); }
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
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Update Error: $e');
    } finally { if (mounted) setState(() => _isLoading = false); }
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
      backgroundColor: _bgSlate,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: _textDark, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(
          _isEditMode ? "Edit Building Issue" : "Report Building Issue",
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isPageLoading 
          ? const Center(child: CircularProgressIndicator(color: _primaryIndigo)) 
          : LayoutBuilder(
              builder: (context, constraints) {
                double horizontalPadding = constraints.maxWidth > 800 ? (constraints.maxWidth - 800) / 2 : 16;
                bool isWide = constraints.maxWidth > 600;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildResponsiveGrid(isWide),
                        const SizedBox(height: 24),
                        _buildSubmitButton(isWide),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  Widget _buildResponsiveGrid(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("School Name", "Enter school name", _schoolNameController, isNumber: false),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDropdown("Damage Building", "Select building", _buildingTypes, _selectedBuilding, (val) => setState(() => _selectedBuilding = val))),
            if (isWide) const SizedBox(width: 16),
            if (isWide) Expanded(child: _buildDropdown("Damage Type", "Select type", _damageTypes, _selectedDamageType, (val) => setState(() => _selectedDamageType = val))),
          ],
        ),
        if (!isWide) _buildDropdown("Damage Type", "Select type", _damageTypes, _selectedDamageType, (val) => setState(() => _selectedDamageType = val)),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTextField("Floors", "Number of floors", _floorsController, isNumber: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField("Classrooms", "Number of rooms", _classroomsController, isNumber: true)),
          ],
        ),
        
        _buildDescriptionField("Description", "Describe the issue in detail...", _descriptionController),
        _buildUploadImagesSection(),
        _buildDateField("Date of Occurrence", "Select date", _dateController, _selectDate),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {required bool isNumber}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 15),
          decoration: _inputDecoration(hint),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ]),
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items, String? val, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: val,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
          decoration: _inputDecoration(hint),
          validator: (v) => v == null ? 'Required' : null,
        ),
      ]),
    );
  }

  Widget _buildDescriptionField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: _inputDecoration(hint),
        ),
      ]),
    );
  }

  Widget _buildUploadImagesSection() {
    bool hasImages = _existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Upload Images', style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 12),
        if (hasImages)
          Container(
            height: 110,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length + _selectedImages.length,
              itemBuilder: (context, index) {
                if (index < _existingImageUrls.length) {
                  return _buildImagePreview(onRemove: () => _removeExistingImage(index), child: Image.network(_existingImageUrls[index], width: 100, height: 100, fit: BoxFit.cover));
                }
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
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryIndigo.withOpacity(0.3), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.add_a_photo_outlined, color: _primaryIndigo, size: 32),
                const SizedBox(height: 8),
                const Text('Add Photos', style: TextStyle(color: _primaryIndigo, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildImagePreview({required Widget child, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: _accentRose, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDateField(String label, String hint, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: _inputDecoration(hint).copyWith(suffixIcon: const Icon(Icons.calendar_month_outlined, color: _primaryIndigo)),
        ),
      ]),
    );
  }

  Widget _buildSubmitButton(bool isWide) {
    return SizedBox(
      width: isWide ? 300 : double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryIndigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : Text(_isEditMode ? "Update Report" : "Submit Report", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: _textFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryIndigo, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accentRose)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accentRose, width: 2)),
    );
  }
}