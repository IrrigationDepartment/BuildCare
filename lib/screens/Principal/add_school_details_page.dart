import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSchoolDetailsPage extends StatefulWidget {
  final String userNic;

  const AddSchoolDetailsPage({super.key, required this.userNic});

  @override
  State<AddSchoolDetailsPage> createState() => _AddSchoolDetailsPageState();
}

class _AddSchoolDetailsPageState extends State<AddSchoolDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers for input fields ---
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _educationalZoneController = TextEditingController();
  final TextEditingController _studentsController = TextEditingController();
  final TextEditingController _teachersController = TextEditingController();
  final TextEditingController _nonAcademicController = TextEditingController();

  // --- State Variables ---
  String? _schoolType;
  String? _selectedDistrict; 
  bool _electricity = false;
  bool _waterSupply = false;
  bool _sanitation = false;
  bool _communication = false;
  bool _isLoading = false;

  // --- Style Constants ---
  static const Color kPrimaryColor = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kFieldColor = Color(0xFFF0F2F5);
  static const Color kTextColor = Color(0xFF333333);

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final schoolData = {
        'schoolName': _schoolNameController.text.trim(),
        'schoolAddress': _schoolAddressController.text.trim(),
        'schoolPhone': _phoneController.text.trim(),
        'schoolEmail': _schoolEmailController.text.trim(),
        'schoolType': _schoolType,
        'educationalZone': _educationalZoneController.text.trim(),
        'district': _selectedDistrict, 
        'numStudents': int.tryParse(_studentsController.text.trim()) ?? 0,
        'numTeachers': int.tryParse(_teachersController.text.trim()) ?? 0,
        'numNonAcademic': int.tryParse(_nonAcademicController.text.trim()) ?? 0,
        'infrastructure': {
          'electricity': _electricity,
          'waterSupply': _waterSupply,
          'sanitation': _sanitation,
          'communication': _communication,
        },
        'addedByNic': widget.userNic,
        'addedAt': Timestamp.now(),
        'isActive': false,
      };

      DocumentReference schoolRef = await FirebaseFirestore.instance
          .collection('schools')
          .add(schoolData);

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New School Added',
        'subtitle': '${_schoolNameController.text.trim()} was added by Principal.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'school',
        'schoolId': schoolRef.id, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School details saved successfully! Pending approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add your school Details",
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: _isLoading
                ? const SizedBox(width: 30, child: CircularProgressIndicator(strokeWidth: 2))
                : OutlinedButton(
                    onPressed: _saveSchoolDetails,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("School Name", "Enter Your School name", _schoolNameController),
                _buildTextField("School Address", "Enter Your School Address", _schoolAddressController),
                _buildTextField(
                  "School E-mail",
                  "Enter Your School E-mail",
                  _schoolEmailController,
                  keyboardType: TextInputType.emailAddress,
                  isEmail: true,
                ),
                _buildTextField(
                  "School PhoneNumber",
                  "Enter Your School Contact Number",
                  _phoneController,
                  keyboardType: TextInputType.phone,
                  isPhone: true,
                ),
                _buildDropdown(),
                _buildTextField("School Educational Zone", "Enter Your School Educational Zone", _educationalZoneController),
                
                
                _buildDistrictDropdown(),

                _buildTextField("Number of Students in School", "Enter Total students in school", _studentsController, isNumber: true),
                _buildTextField("Number of Teachers in School", "Enter Total Teachers in School", _teachersController, isNumber: true),
                _buildTextField("Number of NonAcademic Staff", "Enter Total Number of NonAcademic", _nonAcademicController, isNumber: true),
                const SizedBox(height: 10),
                _buildInfrastructureSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildTextField(String label, String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool isNumber = false, bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: kFieldColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Field required';
              if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter valid email';
              if (isPhone && value.length != 10) return 'Must be 10 digits';
              if (isNumber && int.tryParse(value) == null) return 'Enter valid number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    final List<String> schoolTypes = ['Government', 'Semi-Government',];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("School Type", style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _schoolType,
            decoration: InputDecoration(
              hintText: "Enter Your School Type",
              filled: true,
              fillColor: kFieldColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: schoolTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (val) => setState(() => _schoolType = val),
            validator: (val) => val == null ? 'Please select a type' : null,
          ),
        ],
      ),
    );
  }

  // --- District Dropdown Helper ---
  Widget _buildDistrictDropdown() {
    final List<String> districts = ['Galle', 'Matara', 'Hambantota'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(" School District", style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: InputDecoration(
              hintText: "Select Your District",
              filled: true,
              fillColor: kFieldColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: districts.map((dist) => DropdownMenuItem(value: dist, child: Text(dist))).toList(),
            onChanged: (val) => setState(() => _selectedDistrict = val),
            validator: (val) => val == null ? 'Please select a district' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Infrastructure Components", style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kFieldColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildCheckboxTile("Electricity", _electricity, (val) => _electricity = val!),
              _buildCheckboxTile("Water Supply", _waterSupply, (val) => _waterSupply = val!),
              _buildCheckboxTile("Sanitation", _sanitation, (val) => _sanitation = val!),
              _buildCheckboxTile("Communication Facilities", _communication, (val) => _communication = val!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, color: kTextColor)),
      value: value,
      onChanged: (val) => setState(() => onChanged(val)),
      activeColor: kPrimaryColor,
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}