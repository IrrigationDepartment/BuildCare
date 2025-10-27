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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add your school details",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('School details saved successfully!')),
                );
              }
            },
            child: const Text("Save", style: TextStyle(color: _primaryColor, fontSize: 16)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField("School Name", "Enter Your School name", _schoolNameController),
                _buildTextField("School Address", "Enter Your School Address", _schoolAddressController),
                _buildTextField("School Phone Number", "Enter Your School Contact Number", _phoneController),
                _buildDropdown(),
                _buildTextField("School Educational Zone", "Enter Your School Educational Zone", _educationalZoneController),
                _buildTextField("Number of Students in School", "Enter Total students in school", _studentsController),
                _buildTextField("Number of Teachers in School", "Enter Total Teachers in School", _teachersController),
                _buildTextField("Number of Non-Academic Staff", "Enter Total Number of NonAcademic Staff", _nonAcademicController),
                const SizedBox(height: 20),
                _buildInfrastructureSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _schoolType,
        decoration: InputDecoration(
          labelText: "School Type",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        items: const [
          DropdownMenuItem(value: "Provincial school", child: Text("Provincial ")),
          DropdownMenuItem(value: "government School", child: Text("governmet")),
         // DropdownMenuItem(value: "Private School", child: Text("Private School")),
        ],
        onChanged: (value) => setState(() => _schoolType = value),
        validator: (value) => value == null ? 'Please select school type' : null,
      ),
    );
  }

  Widget _buildInfrastructureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Infrastructure Components",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          CheckboxListTile(
            title: const Text("Electricity"),
            value: electricity,
            onChanged: (val) => setState(() => electricity = val!),
          ),
          CheckboxListTile(
            title: const Text("Water Supply"),
            value: waterSupply,
            onChanged: (val) => setState(() => waterSupply = val!),
          ),
          CheckboxListTile(
            title: const Text("Sanitation"),
            value: sanitation,
            onChanged: (val) => setState(() => sanitation = val!),
          ),
          CheckboxListTile(
            title: const Text("Communication Facilities"),
            value: communication,
            onChanged: (val) => setState(() => communication = val!),
          ),
        ],
      ),
    );
  }
}
