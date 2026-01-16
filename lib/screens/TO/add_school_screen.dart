import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSchoolScreen extends StatefulWidget {
  final String userNic;

  const AddSchoolScreen({super.key, required this.userNic});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers for text fields ---
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _zoneController = TextEditingController();
  final _studentsController = TextEditingController();
  final _teachersController = TextEditingController();
  final _staffController = TextEditingController();

  // --- State for Dropdowns & Checkboxes ---
  String? _selectedSchoolType;
  final List<String> _schoolTypes = [
    'Government',
    'Semi-Government',
  ];

  String? _selectedDistrict;
  final List<String> _districts = [
    'Galle',
    'Matara',
    'Hambanthota',
  ];

  bool _hasElectricity = false;
  bool _hasWaterSupply = false;
  bool _hasSanitation = false;
  bool _hasCommunication = false;

  bool _isLoading = false;

  // --- Style Constants ---
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kFieldColor = Color(0xFFF0F2F5);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kPrimaryBlue = Color(0xFF42A5F5);

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

  // --- Main Save Function ---
  Future<void> _saveSchool() async {
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
        'schoolType': _selectedSchoolType,
        'schoolDistrict': _selectedDistrict, // Saved District
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
        'addedByNic': widget.userNic,
        'addedAt': Timestamp.now(),
        'isActive': false,
      };

      // 1. Save School
      DocumentReference schoolRef = await FirebaseFirestore.instance
          .collection('schools')
          .add(schoolData);

      // 2. Trigger Notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New School Added',
        'subtitle': '${_nameController.text.trim()} was added by Principal.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'school',
        'schoolId': schoolRef.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School added successfully! Pending approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add school: $e'),
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
                  _buildTextField(
                    label: 'School Name',
                    hint: 'Enter Your School name',
                    controller: _nameController,
                  ),
                  _buildTextField(
                    label: 'School Address',
                    hint: 'Enter Your School Address',
                    controller: _addressController,
                  ),
                  _buildTextField(
                    label: 'School E-mail',
                    hint: 'Enter Your School E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Field required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return 'Enter valid email';
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: 'School PhoneNumber',
                    hint: 'Enter Your School Contact Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Field required';
                      if (value.length != 10) return 'Must be 10 digits';
                      return null;
                    },
                  ),
                  _buildSchoolTypeDropdown(),
                  _buildDistrictDropdown(), // The new District dropdown
                  _buildTextField(
                    label: 'School Educational Zone',
                    hint: 'Enter Your School Educational Zone',
                    controller: _zoneController,
                  ),
                  _buildTextField(
                    label: 'Number of Students in School',
                    hint: 'Enter Total students in school',
                    controller: _studentsController,
                    keyboardType: TextInputType.number,
                    validator: _validateNumber,
                  ),
                  _buildTextField(
                    label: 'Number of Teachers in School',
                    hint: 'Enter Total Teachers in School',
                    controller: _teachersController,
                    keyboardType: TextInputType.number,
                    validator: _validateNumber,
                  ),
                  _buildTextField(
                    label: 'Number of NonAcademic Staff',
                    hint: 'Enter Total Number of NonAcademic',
                    controller: _staffController,
                    keyboardType: TextInputType.number,
                    validator: _validateNumber,
                  ),
                  const SizedBox(height: 16),
                  _buildInfrastructureCheckboxes(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widget: Header ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Text(
          'Add your school \nDetails',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor),
        ),
        _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton(
                onPressed: _saveSchool,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryBlue,
                  side: BorderSide(color: kPrimaryBlue.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save'),
              ),
      ],
    );
  }

  // --- Helper Widget: Standard Text Field ---
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kTextColor)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: _fieldDecoration(hint),
            validator: validator ??
                (value) =>
                    (value == null || value.isEmpty) ? 'Field required' : null,
          ),
        ],
      ),
    );
  }

  // --- Helper Widget: School Type Dropdown ---
  Widget _buildSchoolTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School Type',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kTextColor)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSchoolType,
            items: _schoolTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (newValue) =>
                setState(() => _selectedSchoolType = newValue),
            decoration: _fieldDecoration('Select School Type').copyWith(
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            validator: (value) => value == null ? 'Please select a type' : null,
          ),
        ],
      ),
    );
  }

  // --- Helper Widget: School District Dropdown ---
  Widget _buildDistrictDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School District',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kTextColor)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            items: _districts
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (newValue) =>
                setState(() => _selectedDistrict = newValue),
            decoration: _fieldDecoration('Select School District').copyWith(
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            validator: (value) => value == null ? 'Please select a district' : null,
          ),
        ],
      ),
    );
  }

  // --- Helper Widget: Infrastructure Checkboxes ---
  Widget _buildInfrastructureCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Infrastructure Components',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: kTextColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: kFieldColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildCheckboxTile('Electricity', _hasElectricity,
                  (val) => setState(() => _hasElectricity = val!)),
              _buildCheckboxTile('Water Supply', _hasWaterSupply,
                  (val) => setState(() => _hasWaterSupply = val!)),
              _buildCheckboxTile('Sanitation', _hasSanitation,
                  (val) => setState(() => _hasSanitation = val!)),
              _buildCheckboxTile('Communication Facilities', _hasCommunication,
                  (val) => setState(() => _hasCommunication = val!)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
      String title, bool value, ValueChanged<bool?> onChanged) {
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

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: kFieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Field required';
    if (int.tryParse(value) == null) return 'Enter valid number';
    return null;
  }
}