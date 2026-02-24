import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSchoolScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic> schoolData;

  const EditSchoolScreen({
    super.key,
    required this.schoolId,
    required this.schoolData,
  });

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

  String? _selectedSchoolType;
  final List<String> _schoolTypes = ['Government', 'Semi-Government', 'Private', 'International'];

  bool _hasElectricity = false;
  bool _hasWaterSupply = false;
  bool _hasSanitation = false;
  bool _hasCommunication = false;
  bool _isLoading = false;

  // --- EYE-CATCHING COLOR PALETTE ---
  static const Color kPrimaryIndigo = Color(0xFF303F9F);
  static const Color kAccentAmber = Color(0xFFFFC107);
  static const Color kBgSlate = Color(0xFFF8FAFC);
  static const Color kCardColor = Colors.white;
  static const Color kTextDark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schoolData['schoolName']);
    _addressController = TextEditingController(text: widget.schoolData['schoolAddress']);
    _phoneController = TextEditingController(text: widget.schoolData['schoolPhone']);
    _emailController = TextEditingController(text: widget.schoolData['schoolEmail']);
    _zoneController = TextEditingController(text: widget.schoolData['educationalZone']);
    _studentsController = TextEditingController(text: widget.schoolData['numStudents']?.toString());
    _teachersController = TextEditingController(text: widget.schoolData['numTeachers']?.toString());
    _staffController = TextEditingController(text: widget.schoolData['numNonAcademic']?.toString());

    String? incomingType = widget.schoolData['schoolType'];
    if (_schoolTypes.contains(incomingType)) {
      _selectedSchoolType = incomingType;
    } else if (incomingType == 'Government School') {
      _selectedSchoolType = 'Government';
    }

    final infra = widget.schoolData['infrastructure'] as Map<String, dynamic>? ?? {};
    _hasElectricity = infra['electricity'] ?? false;
    _hasWaterSupply = infra['waterSupply'] ?? false;
    _hasSanitation = infra['sanitation'] ?? false;
    _hasCommunication = infra['communication'] ?? false;
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final schoolData = {
        'schoolName': _nameController.text.trim(),
        'schoolAddress': _addressController.text.trim(),
        'schoolPhone': _phoneController.text.trim(),
        'schoolEmail': _emailController.text.trim(),
        'schoolType': _selectedSchoolType,
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

      await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).update(schoolData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 800;

    return Scaffold(
      backgroundColor: kBgSlate,
      appBar: AppBar(
        title: const Text('Edit School Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0.5,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton(
                onPressed: _updateSchool,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Changes'),
              ),
            )
          else
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000), // Prevents overly wide forms on desktop
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Institution Details"),
                  _buildResponsiveRow(isLargeScreen, [
                    _buildTextField(label: 'School Name', hint: 'Enter School name', controller: _nameController),
                    _buildDropdownField(),
                  ]),
                  _buildTextField(label: 'School Address', hint: 'Full physical address', controller: _addressController),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader("Contact & Zone"),
                  _buildResponsiveRow(isLargeScreen, [
                    _buildTextField(
                      label: 'School E-mail',
                      hint: 'example@school.lk',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => (val != null && val.contains('@')) ? null : 'Enter valid email',
                    ),
                    _buildTextField(
                      label: 'School Phone',
                      hint: '0112345678',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (val) => (val != null && val.length == 10) ? null : 'Enter 10 digits',
                    ),
                  ]),
                  _buildTextField(label: 'Educational Zone', hint: 'Assigned zone', controller: _zoneController),

                  const SizedBox(height: 16),
                  _buildSectionHeader("Statistics"),
                  _buildResponsiveRow(isLargeScreen, [
                    _buildTextField(label: 'No. of Students', hint: 'Total', controller: _studentsController, keyboardType: TextInputType.number, validator: _validateNumber),
                    _buildTextField(label: 'No. of Teachers', hint: 'Total', controller: _teachersController, keyboardType: TextInputType.number, validator: _validateNumber),
                    _buildTextField(label: 'No. of Staff', hint: 'Non-academic', controller: _staffController, keyboardType: TextInputType.number, validator: _validateNumber),
                  ]),

                  const SizedBox(height: 16),
                  _buildSectionHeader("Infrastructure Components"),
                  _buildInfrastructureGrid(isLargeScreen),
                  const SizedBox(height: 40), // Extra space at bottom for scrolling
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper: Responsive Row Switcher ---
  Widget _buildResponsiveRow(bool isLarge, List<Widget> children) {
    if (!isLarge) return Column(children: children);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: w))).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimaryIndigo, letterSpacing: 1.1)),
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15),
            decoration: _fieldDecoration(hint),
            validator: validator ?? (value) => (value == null || value.isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSchoolType,
            items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedSchoolType = v),
            decoration: _fieldDecoration('Select Type').copyWith(suffixIcon: const Icon(Icons.arrow_drop_down, color: kPrimaryIndigo)),
            validator: (value) => value == null ? 'Selection required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureGrid(bool isLarge) {
    return Container(
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Wrap(
        children: [
          _buildResponsiveCheckbox('Electricity', _hasElectricity, (v) => setState(() => _hasElectricity = v!), isLarge),
          _buildResponsiveCheckbox('Water Supply', _hasWaterSupply, (v) => setState(() => _hasWaterSupply = v!), isLarge),
          _buildResponsiveCheckbox('Sanitation', _hasSanitation, (v) => setState(() => _hasSanitation = v!), isLarge),
          _buildResponsiveCheckbox('Communication', _hasCommunication, (v) => setState(() => _hasCommunication = v!), isLarge),
        ],
      ),
    );
  }

  Widget _buildResponsiveCheckbox(String title, bool value, Function(bool?) onChanged, bool isLarge) {
    return SizedBox(
      width: isLarge ? 249 : double.infinity, // Grid effect on large screens
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, color: kTextDark)),
        value: value,
        onChanged: onChanged,
        activeColor: kPrimaryIndigo,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: kCardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimaryIndigo, width: 2.0)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent, width: 2.0)),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (int.tryParse(value) == null) return 'Numbers only';
    return null;
  }
}