import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSchoolScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic> schoolData;

  const EditSchoolScreen(
      {super.key, required this.schoolId, required this.schoolData});

  @override
  State<EditSchoolScreen> createState() => _EditSchoolScreenState();
}

class _EditSchoolScreenState extends State<EditSchoolScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _zoneController;
  late TextEditingController _studentsController;
  late TextEditingController _teachersController;
  late TextEditingController _staffController;

  // --- Dropdown & Checkboxes ---
  String? _selectedSchoolType;
  final List<String> _schoolTypes = [
    'Government',
    'Semi-Government',
    'Private',
    'International',
  ];

  bool _hasElectricity = false;
  bool _hasWaterSupply = false;
  bool _hasSanitation = false;
  bool _hasCommunication = false;

  bool _isLoading = false;

  // --- Constants ---
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kFieldColor = Color(0xFFF0F2F5);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kPrimaryBlue = Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    
    // 1. Pre-fill Text Controllers
    _nameController = TextEditingController(text: widget.schoolData['schoolName']);
    _addressController = TextEditingController(text: widget.schoolData['schoolAddress']);
    _phoneController = TextEditingController(text: widget.schoolData['schoolPhone']);
    _emailController = TextEditingController(text: widget.schoolData['schoolEmail']);
    _zoneController = TextEditingController(text: widget.schoolData['educationalZone']);
    _studentsController = TextEditingController(text: widget.schoolData['numStudents']?.toString());
    _teachersController = TextEditingController(text: widget.schoolData['numTeachers']?.toString());
    _staffController = TextEditingController(text: widget.schoolData['numNonAcademic']?.toString());

    // 2. FIX FOR DROPDOWN CRASH
    String? incomingType = widget.schoolData['schoolType'];

    // Check if the incoming value is actually in our list
    if (_schoolTypes.contains(incomingType)) {
      _selectedSchoolType = incomingType;
    } else {
      // If data mismatch (e.g. DB has "Government School" but list has "Government")
      if (incomingType == 'Government School') {
        _selectedSchoolType = 'Government';
      } else {
        // If completely unknown, set to null so user is forced to pick a new one
        _selectedSchoolType = null; 
      }
    }

    // 3. Pre-fill Checkboxes
    final infrastructure = widget.schoolData['infrastructure'] as Map<String, dynamic>? ?? {};
    _hasElectricity = infrastructure['electricity'] ?? false;
    _hasWaterSupply = infrastructure['waterSupply'] ?? false;
    _hasSanitation = infrastructure['sanitation'] ?? false;
    _hasCommunication = infrastructure['communication'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _zoneController.dispose();
    _studentsController.dispose();
    _teachersController.dispose();
    _staffController.dispose();
    super.dispose();
  }

  Future<void> _updateSchool() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final schoolData = {
        'schoolName': _nameController.text.trim(),
        'schoolAddress': _addressController.text.trim(),
        'schoolPhone': _phoneController.text.trim(),
        'schoolEmail': _emailController.text.trim(),
        'schoolType': _selectedSchoolType, // This will now be a valid value
        'educationalZone': _zoneController.text.trim(),
        'numStudents': int.tryParse(_studentsController.text.trim()) ?? 0,
        'numTeachers': int.tryParse(_teachersController.text.trim()) ?? 0,
        'numNonAcademic': int.tryParse(_staffController.text.trim()) ?? 0,
        'infrastructure': {
          'electricity': _hasElectricity,
          'waterSupply': _hasWaterSupply,
          'sanitation': _hasSanitation,
          'communication': _hasCommunication,
        },
      };

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .update(schoolData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update school: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTextField(label: 'School Name', hint: 'Enter School name', controller: _nameController),
                  _buildTextField(label: 'School Address', hint: 'Enter School Address', controller: _addressController),
                  _buildTextField(
                    label: 'School E-mail',
                    hint: 'Enter School E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => (val != null && val.contains('@')) ? null : 'Enter valid email',
                  ),
                  _buildTextField(
                    label: 'School Phone',
                    hint: 'Enter Contact Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (val) => (val != null && val.length == 10) ? null : 'Enter 10 digit number',
                  ),
                  
                  // --- Dropdown (This caused the error) ---
                  _buildDropdownField(),
                  
                  _buildTextField(label: 'Educational Zone', hint: 'Enter Zone', controller: _zoneController),
                  _buildTextField(label: 'No. of Students', hint: 'Total students', controller: _studentsController, keyboardType: TextInputType.number, validator: _validateNumber),
                  _buildTextField(label: 'No. of Teachers', hint: 'Total teachers', controller: _teachersController, keyboardType: TextInputType.number, validator: _validateNumber),
                  _buildTextField(label: 'No. of Staff', hint: 'Total staff', controller: _staffController, keyboardType: TextInputType.number, validator: _validateNumber),
                  const SizedBox(height: 16),
                  _buildInfrastructureCheckboxes(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (Same as before) ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Text('Edit School Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
        _isLoading
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: _updateSchool,
                style: OutlinedButton.styleFrom(foregroundColor: kPrimaryBlue, side: BorderSide(color: kPrimaryBlue.withOpacity(0.5))),
                child: const Text('Update'),
              ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSchoolType, // This is now safely set in initState
            items: _schoolTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (newValue) => setState(() => _selectedSchoolType = newValue),
            decoration: _fieldDecoration('Select School Type').copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
            validator: (value) => value == null ? 'Please select a school type' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Infrastructure Components', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: kFieldColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildCheckboxTile('Electricity', _hasElectricity, (v) => setState(() => _hasElectricity = v!)),
              _buildCheckboxTile('Water Supply', _hasWaterSupply, (v) => setState(() => _hasWaterSupply = v!)),
              _buildCheckboxTile('Sanitation', _hasSanitation, (v) => setState(() => _hasSanitation = v!)),
              _buildCheckboxTile('Communication', _hasCommunication, (v) => setState(() => _hasCommunication = v!)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(color: kTextColor)),
      value: value,
      onChanged: onChanged,
      activeColor: kPrimaryBlue,
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: _fieldDecoration(hint),
            validator: validator ?? (value) => (value == null || value.isEmpty) ? 'Field cannot be empty' : null,
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: kFieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryBlue, width: 2.0)),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (int.tryParse(value) == null) return 'Invalid number';
    return null;
  }
}