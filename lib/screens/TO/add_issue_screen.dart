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

  // --- School autocomplete state ---
  List<Map<String, dynamic>> _schoolSuggestions = [];
  List<String> _schoolBuildingNames = [];
  String? _selectedSchoolDocId;
  bool _isLoadingSchools = false;
  bool _schoolSelected = false;
  final LayerLink _schoolLayerLink = LayerLink();
  OverlayEntry? _schoolOverlayEntry;
  final FocusNode _schoolFocusNode = FocusNode();

  bool get _isEditMode => widget.issueId != null;
  bool _isLoading = false;
  bool _isPageLoading = false;

  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryIndigo = Color(0xFF6366F1);
  static const Color _accentRose = Color(0xFFF43F5E);
  static const Color _bgSlate = Color(0xFFF8FAFC);
  static const Color _textFieldBg = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);

  final List<String> _damageTypes = [
    'Foundation & Wall Damage',
    'Roofing Damage',
    'Utility Damage (Electricity/Water)',
    'Floor Damage',
    'Plumbing/Draining Structural Issue',
    'Windows/Doors Frame Damage',
    'Staircase & Corridor Damage',
  ];

  @override
  void initState() {
    super.initState();
    _schoolNameController.addListener(_onSchoolNameChanged);
    _schoolFocusNode.addListener(() {
      if (!_schoolFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), _removeSchoolOverlay);
      }
    });
    if (_isEditMode) _loadIssueData();
  }

  @override
  void dispose() {
    _removeSchoolOverlay();
    _schoolNameController.removeListener(_onSchoolNameChanged);
    _schoolNameController.dispose();
    _schoolFocusNode.dispose();
    _floorsController.dispose();
    _classroomsController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- School autocomplete logic ---
  void _onSchoolNameChanged() {
    final query = _schoolNameController.text.trim();
    if (_schoolSelected) {
      setState(() {
        _schoolSelected = false;
        _selectedSchoolDocId = null;
        _schoolBuildingNames = [];
        _selectedBuilding = null;
      });
    }
    if (query.length >= 2) {
      _fetchSchoolSuggestions(query);
    } else {
      _removeSchoolOverlay();
      setState(() => _schoolSuggestions = []);
    }
  }

  Future<void> _fetchSchoolSuggestions(String query) async {
    setState(() => _isLoadingSchools = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .where('schoolName', isGreaterThanOrEqualTo: query)
          .where('schoolName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(7)
          .get();

      final results = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      setState(() => _schoolSuggestions = results);
      _showSchoolOverlay();
    } catch (e) {
      debugPrint('School fetch error: $e');
    } finally {
      setState(() => _isLoadingSchools = false);
    }
  }

  void _onSchoolSelected(Map<String, dynamic> school) {
    _removeSchoolOverlay();
    final buildingNames = List<String>.from(school['buildingNames'] ?? []);
    setState(() {
      _schoolNameController.text = school['schoolName'] ?? '';
      _selectedSchoolDocId = school['id'];
      _schoolBuildingNames = buildingNames;
      _schoolSelected = true;
      _schoolSuggestions = [];
      _selectedBuilding = null;
    });
    _schoolFocusNode.unfocus();
  }

  void _showSchoolOverlay() {
    _removeSchoolOverlay();
    if (_schoolSuggestions.isEmpty) return;

    final overlay = Overlay.of(context);
    _schoolOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _schoolLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _schoolSuggestions.map((school) {
                  return GestureDetector(
                    onTapDown: (_) => _onSchoolSelected(school),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_outlined,
                              size: 18, color: _primaryIndigo),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  school['schoolName'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                    fontSize: 14,
                                  ),
                                ),
                                if (school['schoolAddress'] != null)
                                  Text(
                                    school['schoolAddress'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_schoolOverlayEntry!);
  }

  void _removeSchoolOverlay() {
    _schoolOverlayEntry?.remove();
    _schoolOverlayEntry = null;
  }

  // --- Add Building Dialog ---
  // FIX: Controller is created fresh inside the dialog, never stored on the class
  void _showAddBuildingDialog() {
    // Create controller locally inside this method — avoids lifecycle issues
    final localBuildingController = TextEditingController();
    bool isAdding = false;
    final schoolName = _schoolNameController.text;
    final schoolDocId = _selectedSchoolDocId;

    if (schoolDocId == null) return;

    showDialog(
      context: context,
      barrierDismissible: !isAdding,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Add New Building',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                    fontSize: 17),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adding building to:',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schoolName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _primaryIndigo),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: localBuildingController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g. Block A, Science Lab',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: _bgSlate,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: _primaryIndigo, width: 2)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isAdding ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          final name =
                              localBuildingController.text.trim();
                          if (name.isEmpty) return;

                          // Duplicate check
                          if (_schoolBuildingNames
                              .map((b) => b.toLowerCase())
                              .contains(name.toLowerCase())) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Building already exists.')),
                            );
                            return;
                          }

                          setDialogState(() => isAdding = true);

                          try {
                            final updatedList = [
                              ..._schoolBuildingNames,
                              name
                            ];
                            await FirebaseFirestore.instance
                                .collection('schools')
                                .doc(schoolDocId)
                                .update({'buildingNames': updatedList});

                            if (mounted) {
                              setState(() {
                                _schoolBuildingNames = updatedList;
                                _selectedBuilding = name;
                              });
                            }

                            if (ctx.mounted) Navigator.pop(ctx);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('"$name" added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isAdding = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to add building: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add Building'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Safely dispose the local controller after dialog closes
      localBuildingController.dispose();
    });
  }

  // --- Existing logic methods ---
  Future<void> _loadIssueData() async {
    setState(() => _isPageLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId!)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _schoolNameController.text = data['schoolName'] ?? '';
        _floorsController.text = data['numFloors']?.toString() ?? '';
        _classroomsController.text =
            data['numClassrooms']?.toString() ?? '';
        _descriptionController.text = data['description'] ?? '';
        _selectedDamageType = data['damageType'];
        if (data['dateOfOccurance'] != null) {
          _selectedDate =
              (data['dateOfOccurance'] as Timestamp).toDate();
          _dateController.text =
              DateFormat('yyyy-MM-dd').format(_selectedDate!);
        }
        _existingImageUrls =
            List<String>.from(data['imageUrls'] ?? []);

        if (data['schoolName'] != null) {
          _schoolSelected = true;
          final schoolSnap = await FirebaseFirestore.instance
              .collection('schools')
              .where('schoolName', isEqualTo: data['schoolName'])
              .limit(1)
              .get();
          if (schoolSnap.docs.isNotEmpty) {
            final schoolDoc = schoolSnap.docs.first;
            _selectedSchoolDocId = schoolDoc.id;
            _schoolBuildingNames = List<String>.from(
                schoolDoc.data()['buildingNames'] ?? []);
            _selectedBuilding = data['buildingName'];
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isPageLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles =
        await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() => _selectedImages.addAll(pickedFiles));
    }
  }

  void _removeNewImage(int index) =>
      setState(() => _selectedImages.removeAt(index));
  void _removeExistingImage(int index) =>
      setState(() => _existingImageUrls.removeAt(index));

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    var uri = Uri.parse("http://98.94.30.13/");
    var request = http.MultipartRequest("POST", uri);
    for (var imageFile in _selectedImages) {
      var fileBytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
          'images[]', fileBytes,
          filename: imageFile.name));
    }
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);
        return decodedResponse['status'] == 'success'
            ? List<String>.from(decodedResponse['imageUrls'])
            : [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _handleSubmit() async {
    if (_isEditMode) await _updateIssue(); else await _addNewIssue();
  }

  Future<void> _addNewIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      List<String> uploadedImageUrls = await _uploadImages();
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'numFloors': int.tryParse(_floorsController.text.trim()) ?? 0,
        'numClassrooms':
            int.tryParse(_classroomsController.text.trim()) ?? 0,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': uploadedImageUrls,
        'status': 'Pending',
        'addedByNic': widget.userNic,
        'timestamp': FieldValue.serverTimestamp(),
      };
      DocumentReference issueRef = await FirebaseFirestore.instance
          .collection('issues')
          .add(issueData);
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Building Issue Reported',
        'subtitle':
            '${_schoolNameController.text.trim()}: $_selectedDamageType',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'issue',
        'issueId': issueRef.id,
        'addedByNic': widget.userNic,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reported Successfully!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateIssue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      List<String> newlyUploadedImageUrls = await _uploadImages();
      List<String> finalImageUrls = [
        ..._existingImageUrls,
        ...newlyUploadedImageUrls
      ];
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'numFloors': int.tryParse(_floorsController.text.trim()) ?? 0,
        'numClassrooms':
            int.tryParse(_classroomsController.text.trim()) ?? 0,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': finalImageUrls,
        'lastUpdatedTimestamp': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId!)
          .update(issueData);
      if (mounted) Navigator.of(context).pop();
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
      backgroundColor: _bgSlate,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? "Edit Building Issue" : "Report Building Issue",
          style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isPageLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: _primaryIndigo))
            : LayoutBuilder(
                builder: (context, constraints) {
                  double horizontalPadding =
                      constraints.maxWidth > 800
                          ? (constraints.maxWidth - 800) / 2
                          : 16;
                  bool isWide = constraints.maxWidth > 600;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
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
        _buildSchoolNameField(),
        _buildBuildingDropdown(isWide),
        if (!isWide)
          _buildDropdown(
              "Damage Type",
              "Select type",
              _damageTypes,
              _selectedDamageType,
              (val) => setState(() => _selectedDamageType = val)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _buildTextField(
                    "Floors", "Number of floors", _floorsController,
                    isNumber: true)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTextField("Classrooms", "Number of rooms",
                    _classroomsController,
                    isNumber: true)),
          ],
        ),
        _buildDescriptionField("Description",
            "Describe the issue in detail...", _descriptionController),
        _buildUploadImagesSection(),
        _buildDateField("Date of Occurrence", "Select date",
            _dateController, _selectDate),
      ],
    );
  }

  Widget _buildSchoolNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School Name',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: _textDark)),
          const SizedBox(height: 8),
          CompositedTransformTarget(
            link: _schoolLayerLink,
            child: TextFormField(
              controller: _schoolNameController,
              focusNode: _schoolFocusNode,
              style: const TextStyle(fontSize: 15),
              decoration:
                  _inputDecoration('Enter school name').copyWith(
                suffixIcon: _isLoadingSchools
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primaryIndigo),
                        ),
                      )
                    : _schoolSelected
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 20)
                        : const Icon(Icons.search,
                            color: Colors.grey, size: 20),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
          ),
          if (!_schoolSelected &&
              _schoolNameController.text.length >= 2 &&
              _schoolSuggestions.isEmpty &&
              !_isLoadingSchools)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'No schools found. Please check the name.',
                style: TextStyle(
                    color: Colors.orange.shade700, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBuildingDropdown(bool isWide) {
    final bool hasBuildings = _schoolBuildingNames.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Damage Building',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textDark)),
                    if (_schoolSelected)
                      GestureDetector(
                        onTap: _showAddBuildingDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryIndigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 15, color: _primaryIndigo),
                              SizedBox(width: 4),
                              Text(
                                'Add Building',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _primaryIndigo,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                IgnorePointer(
                  ignoring: !_schoolSelected,
                  child: Opacity(
                    opacity: _schoolSelected ? 1.0 : 0.5,
                    child: DropdownButtonFormField<String>(
                      value: _selectedBuilding,
                      icon: const Icon(
                          Icons.keyboard_arrow_down_rounded),
                      items: _schoolBuildingNames
                          .map((i) => DropdownMenuItem(
                              value: i,
                              child: Text(i,
                                  overflow:
                                      TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: _schoolSelected
                          ? (val) =>
                              setState(() => _selectedBuilding = val)
                          : null,
                      decoration: _inputDecoration(
                        _schoolSelected
                            ? (hasBuildings
                                ? 'Select building'
                                : 'No buildings — add one above')
                            : 'Select a school first',
                      ),
                      validator: (v) =>
                          v == null ? 'Required' : null,
                    ),
                  ),
                ),
                if (_schoolSelected && !hasBuildings)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 13,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'No buildings yet. Tap "Add Building" to add one.',
                            style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isWide) const SizedBox(width: 16),
        if (isWide)
          Expanded(
            child: _buildDropdown(
              "Damage Type",
              "Select type",
              _damageTypes,
              _selectedDamageType,
              (val) => setState(() => _selectedDamageType = val),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {required bool isNumber}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType:
                  isNumber ? TextInputType.number : TextInputType.text,
              style: const TextStyle(fontSize: 15),
              decoration: _inputDecoration(hint),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ]),
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items,
      String? val, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: val,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: items
                  .map((i) => DropdownMenuItem(
                      value: i,
                      child:
                          Text(i, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: onChanged,
              decoration: _inputDecoration(hint),
              validator: (v) => v == null ? 'Required' : null,
            ),
          ]),
    );
  }

  Widget _buildDescriptionField(
      String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _textDark)),
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
    bool hasImages =
        _existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Images',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 12),
            if (hasImages)
              Container(
                height: 110,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImageUrls.length +
                      _selectedImages.length,
                  itemBuilder: (context, index) {
                    if (index < _existingImageUrls.length) {
                      return _buildImagePreview(
                          onRemove: () =>
                              _removeExistingImage(index),
                          child: Image.network(
                              _existingImageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover));
                    }
                    final newIdx = index - _existingImageUrls.length;
                    return _buildImagePreview(
                      onRemove: () => _removeNewImage(newIdx),
                      child: FutureBuilder<Uint8List>(
                        future:
                            _selectedImages[newIdx].readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData)
                            return Image.memory(snapshot.data!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover);
                          return const SizedBox(
                              width: 100,
                              child: Center(
                                  child:
                                      CircularProgressIndicator()));
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
                  border: Border.all(
                      color: _primaryIndigo.withOpacity(0.3),
                      style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: _primaryIndigo, size: 32),
                    const SizedBox(height: 8),
                    const Text('Add Photos',
                        style: TextStyle(
                            color: _primaryIndigo,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ]),
    );
  }

  Widget _buildImagePreview(
      {required Widget child, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(12), child: child),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: _accentRose, shape: BoxShape.circle),
              child: const Icon(Icons.close,
                  size: 16, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDateField(String label, String hint,
      TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              readOnly: true,
              onTap: onTap,
              decoration: _inputDecoration(hint).copyWith(
                  suffixIcon: const Icon(
                      Icons.calendar_month_outlined,
                      color: _primaryIndigo)),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isEditMode ? "Update Report" : "Submit Report",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: _textFieldBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _primaryIndigo, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentRose)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _accentRose, width: 2)),
    );
  }
}