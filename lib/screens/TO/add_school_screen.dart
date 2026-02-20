import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSchoolScreen extends StatefulWidget {
<<<<<<< HEAD
=======
  // We need to know who is adding this school.
  // Pass the user's NIC or ID from the dashboard when navigating here.
>>>>>>> main
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
<<<<<<< HEAD
=======
  final _emailController = TextEditingController(); // New field
>>>>>>> main
  final _emailController = TextEditingController();
  final _zoneController = TextEditingController();
  final _studentsController = TextEditingController();
  final _teachersController = TextEditingController();
  final _staffController = TextEditingController();

  // --- State for Dropdown & Checkboxes ---
<<<<<<< HEAD
=======
  // --- State for Dropdowns & Checkboxes ---
>>>>>>> main
  String? _selectedSchoolType;
  final List<String> _schoolTypes = [
    'Government',
    'Semi-Government',
    'Private',
    'International',
  ];

<<<<<<< HEAD
=======
  String? _selectedDistrict;
  final List<String> _districts = [
    'Galle',
    'Matara',
    'Hambanthota',
  ];

>>>>>>> main
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
<<<<<<< HEAD
=======
    // Clean up controllers
>>>>>>> main
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

<<<<<<< HEAD
  // --- Main Save Function with Notification Logic ---
=======
  // --- 1. Main Save Function (UPDATED) ---
  Future<void> _saveSchool() async {
    // First, validate the form
    if (!_formKey.currentState!.validate()) {
      return; // If validation fails, do nothing
  // --- Main Save Function ---
>>>>>>> main
  Future<void> _saveSchool() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
<<<<<<< HEAD
=======
      // Create a map of the school data
>>>>>>> main
      final schoolData = {
        'schoolName': _nameController.text.trim(),
        'schoolAddress': _addressController.text.trim(),
        'schoolPhone': _phoneController.text.trim(),
        'schoolEmail': _emailController.text.trim(),
        'schoolType': _selectedSchoolType,
<<<<<<< HEAD
=======
        'schoolDistrict': _selectedDistrict, // Saved District
>>>>>>> main
        'educationalZone': _zoneController.text.trim(),
        'numStudents': int.tryParse(_studentsController.text.trim()) ?? 0,
        'numTeachers': int.tryParse(_teachersController.text.trim()) ?? 0,
        'numNonAcademic': int.tryParse(_staffController.text.trim()) ?? 0,
        'infrastructure': {
<<<<<<< HEAD
=======
          // Store checkboxes as a nested map
>>>>>>> main
          'electricity': _hasElectricity,
          'waterSupply': _hasWaterSupply,
          'sanitation': _hasSanitation,
          'communication': _hasCommunication,
        },
<<<<<<< HEAD
=======
        'addedByNic': widget.userNic, // Save *who* added it
        'addedAt': Timestamp.now(), // Save *when* it was added

        // --- THIS IS THE CHANGE YOU REQUESTED ---
        'isActive': false, // Default to inactive, requires higher-level approval
        // -----------------------------------------
      };

      // Add to the 'schools' collection in Firestore
      await FirebaseFirestore.instance.collection('schools').add(schoolData);

      // Show success message and go back
>>>>>>> main
        'addedByNic': widget.userNic,
        'addedAt': Timestamp.now(),
        'isActive': false,
      };

<<<<<<< HEAD
      // 1. Save School and get the Document ID
=======
      // 1. Save School
>>>>>>> main
      DocumentReference schoolRef = await FirebaseFirestore.instance
          .collection('schools')
          .add(schoolData);

<<<<<<< HEAD
      // 2. TRIGGER NOTIFICATION with the schoolId
=======
      // 2. Trigger Notification
>>>>>>> main
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New School Added',
        'subtitle': '${_nameController.text.trim()} was added by Principal.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'school',
<<<<<<< HEAD
        'schoolId': schoolRef.id, // Linking the ID so notification click works
=======
        'schoolId': schoolRef.id,
>>>>>>> main
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
<<<<<<< HEAD
=======
      // Show error message
>>>>>>> main
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
<<<<<<< HEAD
=======
                  // --- 2. Custom Header ---
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // --- 3. Form Fields ---
>>>>>>> main
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
<<<<<<< HEAD
=======
                    // New field
>>>>>>> main
                    label: 'School E-mail',
                    hint: 'Enter Your School E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
<<<<<<< HEAD
                      if (value == null || value.isEmpty)
                        return 'Field required';
=======
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      // Basic email validation
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      if (value == null || value.isEmpty) return 'Field required';
>>>>>>> main
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
<<<<<<< HEAD
                      if (value == null || value.isEmpty)
                        return 'Field required';
                      if (value.length != 10) return 'Must be 10 digits';
=======
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      // 10-digit validation
                      if (value.length != 10) {
                        return 'Phone number must be 10 digits';
                      }
>>>>>>> main
                      return null;
                    },
                  ),
                  _buildDropdownField(),
<<<<<<< HEAD
=======
                      if (value == null || value.isEmpty) return 'Field required';
                      if (value.length != 10) return 'Must be 10 digits';
                      return null;
                    },
                  ),
                  _buildSchoolTypeDropdown(),
                  _buildDistrictDropdown(), // The new District dropdown
>>>>>>> main
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
<<<<<<< HEAD
=======

                  // --- 4. Checkboxes ---
>>>>>>> main
                  _buildInfrastructureCheckboxes(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
=======
  // --- Helper Widgets ---

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
>>>>>>> main
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
<<<<<<< HEAD
=======
        // Back Button
>>>>>>> main
        IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
<<<<<<< HEAD
=======
        // Title
>>>>>>> main
        const Text(
          'Add your school \nDetails',
          textAlign: TextAlign.center,
          style: TextStyle(
<<<<<<< HEAD
              fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor),
        ),
        _isLoading
            ? const CircularProgressIndicator()
=======
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        // Save Button
        _isLoading
            ? const CircularProgressIndicator()
              fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor),
        ),
        _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
>>>>>>> main
            : OutlinedButton(
                onPressed: _saveSchool,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryBlue,
                  side: BorderSide(color: kPrimaryBlue.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
<<<<<<< HEAD
=======
                    borderRadius: BorderRadius.circular(12),
                  ),
>>>>>>> main
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save'),
              ),
      ],
    );
  }

<<<<<<< HEAD
=======
  // --- Helper Widget: Standard Text Field ---
>>>>>>> main
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
<<<<<<< HEAD
=======
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
>>>>>>> main
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
<<<<<<< HEAD
=======
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
>>>>>>> main
                (value) =>
                    (value == null || value.isEmpty) ? 'Field required' : null,
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildDropdownField() {
=======
  // --- Helper Widget: School Type Dropdown ---
  Widget _buildSchoolTypeDropdown() {
>>>>>>> main
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
=======
          const Text(
            'School Type',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSchoolType,
            value: _selectedSchoolType,
            items: _schoolTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() => _selectedSchoolType = newValue);
            },
            decoration: _fieldDecoration('Enter Your School Type').copyWith(
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            validator: (value) {
              if (value == null) {
                return 'Please select a school type';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

>>>>>>> main
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
<<<<<<< HEAD
            decoration: _fieldDecoration('Enter Your School Type').copyWith(
=======
            decoration: _fieldDecoration('Select School Type').copyWith(
>>>>>>> main
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            validator: (value) => value == null ? 'Please select a type' : null,
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
=======
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
>>>>>>> main
  Widget _buildInfrastructureCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
<<<<<<< HEAD
=======
        const Text(
          'Infrastructure Components',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
>>>>>>> main
        const Text('Infrastructure Components',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: kTextColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
<<<<<<< HEAD
=======
            color: kFieldColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildCheckboxTile(
                title: 'Electricity',
                value: _hasElectricity,
                onChanged: (val) => setState(() => _hasElectricity = val!),
              ),
              _buildCheckboxTile(
                title: 'Water Supply',
                value: _hasWaterSupply,
                onChanged: (val) => setState(() => _hasWaterSupply = val!),
              ),
              _buildCheckboxTile(
                title: 'Sanitation',
                value: _hasSanitation,
                onChanged: (val) => setState(() => _hasSanitation = val!),
              ),
              _buildCheckboxTile(
                title: 'Communication Facilities',
                value: _hasCommunication,
                onChanged: (val) => setState(() => _hasCommunication = val!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
>>>>>>> main
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

<<<<<<< HEAD
=======
  // --- Helper Methods ---

>>>>>>> main
  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: kFieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
<<<<<<< HEAD
=======
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryBlue, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
>>>>>>> main
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  String? _validateNumber(String? value) {
<<<<<<< HEAD
=======
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
>>>>>>> main
    if (value == null || value.isEmpty) return 'Field required';
    if (int.tryParse(value) == null) return 'Enter valid number';
    return null;
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> main
