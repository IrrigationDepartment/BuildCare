import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore

class AddSchoolDetailsPage extends StatefulWidget {
  // Added userNic parameter to identify who is adding the school,
  // consistent with your other file.
  final String userNic;

  const AddSchoolDetailsPage({super.key, required this.userNic});

  @override
  State<AddSchoolDetailsPage> createState() => _AddSchoolDetailsPageState();
}

class _AddSchoolDetailsPageState extends State<AddSchoolDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers for text fields ---
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _educationalZoneController = TextEditingController();
  final TextEditingController _studentsController = TextEditingController();
  final TextEditingController _teachersController = TextEditingController();
  final TextEditingController _nonAcademicController = TextEditingController();

  // --- State for Dropdown & Checkboxes ---
  String? _schoolType;
  bool _electricity = false;
  bool _waterSupply = false;
  bool _sanitation = false;
  bool _communication = false;
  bool _isLoading = false; // New state for loading

  // --- Style Constants ---
  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _schoolEmailController.dispose();
    _phoneController.dispose();
    _educationalZoneController.dispose();
    _studentsController.dispose();
    _teachersController.dispose();
    _nonAcademicController.dispose();
    super.dispose();
  }

  // --- Firestore Save Function ---
  Future<void> _saveSchoolDetails() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Create data map
      final schoolData = {
        'schoolName': _schoolNameController.text.trim(),
        'schoolAddress': _schoolAddressController.text.trim(),
        'schoolPhone': _phoneController.text.trim(),
        'schoolEmail': _schoolEmailController.text.trim(),
        'schoolType': _schoolType,
        'educationalZone': _educationalZoneController.text.trim(),
        // Parse numbers safely, defaulting to 0
        'numStudents': int.tryParse(_studentsController.text.trim()) ?? 0,
        'numTeachers': int.tryParse(_teachersController.text.trim()) ?? 0,
        'numNonAcademic': int.tryParse(_nonAcademicController.text.trim()) ?? 0,
        'infrastructure': {
          'electricity': _electricity,
          'waterSupply': _waterSupply,
          'sanitation': _sanitation,
          'communication': _communication,
        },
        'addedByNic': widget.userNic, // Use the passed NIC
        'addedAt': Timestamp.now(),
      };

      // 3. Add to 'schools' collection
      await FirebaseFirestore.instance.collection('schools').add(schoolData);

      // 4. Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // 5. Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save school details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. Reset loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        title: const Text(
          "Add your school details",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryColor)) // Show loading
                : OutlinedButton(
                    onPressed: _saveSchoolDetails, // Call the new save function
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(color: _primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
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
                _buildTextField("School Name", "Enter Your School name", _schoolNameController, isNumber: false),
                _buildTextField("School Address", "Enter Your School Address", _schoolAddressController, isNumber: false),
                _buildTextField(
                  "School Email",
                  "Enter Your School Email",
                  _schoolEmailController,
                  isNumber: false,
                  isEmail: true,
                ),
                _buildTextField("School Phone Number", "Enter Your School Contact Number", _phoneController, isNumber: true, isPhone: true), // Added phone validation flag
                _buildDropdown(),
                _buildTextField("School Educational Zone", "Enter Your School Educational Zone", _educationalZoneController, isNumber: false),
                _buildTextField("Number of Students in School", "Enter Total students in school", _studentsController, isNumber: true),
                _buildTextField("Number of Teachers in School", "Enter Total Teachers in School", _teachersController, isNumber: true),
                _buildTextField("Number of NonAcademic Staff", "Enter Total Number of NonAcademic Staff", _nonAcademicController, isNumber: true),
                const SizedBox(height: 20),
                _buildInfrastructureSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets and Methods ---

  /// Builds a text field with a label above it and a F3F3F3 background.
  Widget _buildTextField(String label, String hint, TextEditingController controller, {required bool isNumber, bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isNumber
                ? TextInputType.number
                : isEmail
                    ? TextInputType.emailAddress
                    : isPhone
                        ? TextInputType.phone
                        : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: _textFieldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter $label';
              }
              // Email validation check
              if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              // Phone validation (10 digits)
              if (isPhone && value.length != 10) {
                return 'Phone number must be 10 digits';
              }
              // Number validation
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

  /// Builds a dropdown field with a label above it and a F3F3F3 background.
  Widget _buildDropdown() {
    // Expanded list of school types for better usability
    final List<String> schoolTypes = [
      'Government School',
      'Provincial School',
      'Semi-Government School',
      'Private School',
      'International School',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "School Type",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _schoolType,
            decoration: InputDecoration(
              hintText: "Enter Your School Type",
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: _textFieldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 14, bottom: 14),
            ),
            isExpanded: true,
            items: schoolTypes.map((String type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) => setState(() => _schoolType = value),
            validator: (value) => value == null ? 'Please select school type' : null,
          ),
        ],
      ),
    );
  }

  /// Builds the infrastructure checklist section with F3F3F3 background.
  Widget _buildInfrastructureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _textFieldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Infrastructure Components",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 10),
          _buildCheckboxTile("Electricity", _electricity, (val) => _electricity = val!),
          _buildCheckboxTile("Water Supply", _waterSupply, (val) => _waterSupply = val!),
          _buildCheckboxTile("Sanitation", _sanitation, (val) => _sanitation = val!),
          _buildCheckboxTile("Communication Facilities", _communication, (val) => _communication = val!),
        ],
      ),
    );
  }

  /// Helper widget for cleaner CheckboxListTile code.
  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      value: value,
      onChanged: (val) => setState(() => onChanged(val)),
      activeColor: _primaryColor,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}