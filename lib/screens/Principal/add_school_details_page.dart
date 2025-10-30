import 'package:flutter/material.dart';

class AddSchoolDetailsPage extends StatefulWidget {
  const AddSchoolDetailsPage({super.key});

  @override
  State<AddSchoolDetailsPage> createState() => _AddSchoolDetailsPageState();
}

class _AddSchoolDetailsPageState extends State<AddSchoolDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _educationalZoneController = TextEditingController();
  final TextEditingController _studentsController = TextEditingController();
  final TextEditingController _teachersController = TextEditingController();
  final TextEditingController _nonAcademicController = TextEditingController();

  String? _schoolType;
  bool electricity = false;
  bool waterSupply = false;
  bool sanitation = false;
  bool communication = false;

  static const Color _primaryColor = Color(0xFF53BDFF);
  // Color for text fields background (F3F3F3)
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _phoneController.dispose();
    _educationalZoneController.dispose();
    _studentsController.dispose();
    _teachersController.dispose();
    _nonAcademicController.dispose();
    super.dispose();
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
            child: OutlinedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('School details saved successfully!')),
                  );
                }
              },
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
                _buildTextField("School Phone Number", "Enter Your School Contact Number", _phoneController, isNumber: true),
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

  /// Builds a text field with a label above it and a F3F3F3 background.
  Widget _buildTextField(String label, String hint, TextEditingController controller, {required bool isNumber}) {
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
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: _textFieldBackgroundColor, // Applied F3F3F3 color
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
          ),
        ],
      ),
    );
  }

  /// Builds a dropdown field with a label above it and a F3F3F3 background.
  Widget _buildDropdown() {
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
              fillColor: _textFieldBackgroundColor, // Applied F3F3F3 color
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 14, bottom: 14), 
            ),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: "Provincial school", child: Text("Provincial")),
              DropdownMenuItem(value: "government School", child: Text("Government")),
              // DropdownMenuItem(value: "Private School", child: Text("Private School")),
            ],
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
        color: _textFieldBackgroundColor, // 🚩 Changed to F3F3F3
        borderRadius: BorderRadius.circular(10), // Matched radius to text fields
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Infrastructure Components",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 10),
          _buildCheckboxTile("Electricity", electricity, (val) => electricity = val!),
          _buildCheckboxTile("Water Supply", waterSupply, (val) => waterSupply = val!),
          _buildCheckboxTile("Sanitation", sanitation, (val) => sanitation = val!),
          _buildCheckboxTile("Communication Facilities", communication, (val) => communication = val!),
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