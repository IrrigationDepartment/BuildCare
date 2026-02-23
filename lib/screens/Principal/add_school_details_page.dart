import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  bool _electricity = false;
  bool _waterSupply = false;
  bool _sanitation = false;
  bool _communication = false;
  
  bool _isLoading = false;
  bool _isFetchingData = true; 
  String? _existingDocId;      

  // --- 6-Month Editing Lock Variables ---
  bool _isEditable = true;
  DateTime? _nextEditDate;

  // --- Style Constants ---
  static const Color kPrimaryColor = Color(0xFF0077FF);
  static const Color kBackgroundColor = Color(0xFFF4F7FB);
  static const Color kFieldColor = Colors.white;
  static const Color kTextColor = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _loadExistingSchoolData(); 
  }

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

  // --- Fetch Existing Data Logic ---
  Future<void> _loadExistingSchoolData() async {
    try {
      // 1. Fetch User Data to get the assigned School Name
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: widget.userNic)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception("User not found.");
      }

      String userSchoolName = userQuery.docs.first['schoolName']?.toString().trim() ?? '';
      
      if (userSchoolName.isEmpty) {
        // If the user has no school assigned yet, let them start fresh
        setState(() => _isFetchingData = false);
        return;
      }

      // Pre-fill the school name based on the user's profile
      _schoolNameController.text = userSchoolName;

      // 2. Fetch the School Data using the School Name
      QuerySnapshot schoolQuery = await FirebaseFirestore.instance
          .collection('schools')
          .where('schoolName', isEqualTo: userSchoolName)
          .limit(1)
          .get();

      if (schoolQuery.docs.isNotEmpty) {
        var doc = schoolQuery.docs.first;
        _existingDocId = doc.id;
        var data = doc.data() as Map<String, dynamic>;

        // Load data into controllers
        _schoolAddressController.text = data['schoolAddress']?.toString() ?? '';
        _phoneController.text = data['schoolPhone']?.toString() ?? '';
        _schoolEmailController.text = data['schoolEmail']?.toString() ?? '';
        _educationalZoneController.text = data['educationalZone']?.toString() ?? '';
        
        _studentsController.text = (data['numStudents'] ?? '').toString();
        _teachersController.text = (data['numTeachers'] ?? '').toString();
        _nonAcademicController.text = (data['numNonAcademic'] ?? '').toString();

        // 3. Check 6-Month Editing Rules
        if (data.containsKey('lastEditedAt') && data['lastEditedAt'] != null) {
          DateTime lastEdited = (data['lastEditedAt'] as Timestamp).toDate();
          DateTime now = DateTime.now();
          int daysSinceEdit = now.difference(lastEdited).inDays;
          
          if (daysSinceEdit < 180) {
            _isEditable = false;
            _nextEditDate = lastEdited.add(const Duration(days: 180));
          }
        }

        setState(() {
          final List<String> validTypes = ['Government', 'Semi-Government', 'Private', 'International'];
          if (validTypes.contains(data['schoolType'])) {
             _schoolType = data['schoolType'];
          }
          
          var infra = data['infrastructure'] ?? {};
          _electricity = infra['electricity'] ?? false;
          _waterSupply = infra['waterSupply'] ?? false;
          _sanitation = infra['sanitation'] ?? false;
          _communication = infra['communication'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching school data: $e");
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  // --- Firestore Save/Update Function ---
  Future<void> _saveSchoolDetails() async {
    if (!_isEditable) return; // Prevent saving if locked
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
        'numStudents': int.tryParse(_studentsController.text.trim()) ?? 0,
        'numTeachers': int.tryParse(_teachersController.text.trim()) ?? 0,
        'numNonAcademic': int.tryParse(_nonAcademicController.text.trim()) ?? 0,
        'infrastructure': {
          'electricity': _electricity,
          'waterSupply': _waterSupply,
          'sanitation': _sanitation,
          'communication': _communication,
        },
        'addedByNic': widget.userNic, // Keep track of who edited it last
        'updatedAt': FieldValue.serverTimestamp(),
        'lastEditedAt': FieldValue.serverTimestamp(), // NEW: Save timestamp for the 6-month lock
      };

      String currentSchoolId;

      if (_existingDocId != null) {
        // UPDATE existing record
        await FirebaseFirestore.instance.collection('schools').doc(_existingDocId).update(schoolData);
        currentSchoolId = _existingDocId!;
      } else {
        // CREATE new record
        schoolData['addedAt'] = FieldValue.serverTimestamp();
        schoolData['isActive'] = false; 
        DocumentReference newRef = await FirebaseFirestore.instance.collection('schools').add(schoolData);
        currentSchoolId = newRef.id;
        _existingDocId = currentSchoolId; 
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _existingDocId != null ? 'School Details Updated' : 'New School Added',
        'subtitle': '${_schoolNameController.text.trim()} was ${_existingDocId != null ? 'updated' : 'added'} by Principal.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'school',
        'schoolId': currentSchoolId, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School details saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save details: $e'), backgroundColor: Colors.red),
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
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: kTextColor),
        title: Text(
          _existingDocId != null ? "School Master Data" : "Add School Details", 
          style: const TextStyle(color: kTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (_isEditable) // Only show Save button if the form is editable
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              child: _isLoading
                  ? const SizedBox(width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: _isFetchingData ? null : _saveSchoolDetails, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isFetchingData
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor)) 
            : LayoutBuilder(
                builder: (context, constraints) {
                  bool isLargeScreen = constraints.maxWidth > 800;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Edit Lock Warning Banner
                              if (!_isEditable)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    border: Border.all(color: Colors.orange.shade200),
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_clock, color: Colors.orange.shade700),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "Editing is locked. School details can only be updated every 6 months. Next available edit date: ${DateFormat.yMMMMd().format(_nextEditDate!)}.",
                                          style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              _buildSectionTitle("Basic Details"),
                              _buildTextField("School Name", "Enter Your School name", _schoolNameController, readOnly: !_isEditable),
                              _buildTextField("School Address", "Enter Your School Address", _schoolAddressController, readOnly: !_isEditable),
                              
                              if (isLargeScreen)
                                Row(
                                  children: [
                                    Expanded(child: _buildTextField("School E-mail", "Enter Your School E-mail", _schoolEmailController, keyboardType: TextInputType.emailAddress, isEmail: true, readOnly: !_isEditable)),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildTextField("School Phone Number", "Enter Contact Number", _phoneController, keyboardType: TextInputType.phone, isPhone: true, readOnly: !_isEditable)),
                                  ],
                                )
                              else ...[
                                _buildTextField("School E-mail", "Enter Your School E-mail", _schoolEmailController, keyboardType: TextInputType.emailAddress, isEmail: true, readOnly: !_isEditable),
                                _buildTextField("School Phone Number", "Enter Your School Contact Number", _phoneController, keyboardType: TextInputType.phone, isPhone: true, readOnly: !_isEditable),
                              ],

                              const SizedBox(height: 16),
                              _buildSectionTitle("Administrative Info"),
                              
                              if (isLargeScreen)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildDropdown()),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildTextField("Educational Zone", "Enter Your Educational Zone", _educationalZoneController, readOnly: !_isEditable)),
                                  ],
                                )
                              else ...[
                                _buildDropdown(),
                                _buildTextField("School Educational Zone", "Enter Your School Educational Zone", _educationalZoneController, readOnly: !_isEditable),
                              ],

                              const SizedBox(height: 16),
                              _buildSectionTitle("Demographics"),

                              if (isLargeScreen)
                                Row(
                                  children: [
                                    Expanded(child: _buildTextField("Students", "Total students", _studentsController, isNumber: true, readOnly: !_isEditable)),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildTextField("Teachers", "Total Teachers", _teachersController, isNumber: true, readOnly: !_isEditable)),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildTextField("Non-Academic", "Total Non-Academic", _nonAcademicController, isNumber: true, readOnly: !_isEditable)),
                                  ],
                                )
                              else ...[
                                _buildTextField("Number of Students in School", "Enter Total students", _studentsController, isNumber: true, readOnly: !_isEditable),
                                _buildTextField("Number of Teachers in School", "Enter Total Teachers", _teachersController, isNumber: true, readOnly: !_isEditable),
                                _buildTextField("Number of Non-Academic Staff", "Enter Total Non-Academic", _nonAcademicController, isNumber: true, readOnly: !_isEditable),
                              ],

                              const SizedBox(height: 16),
                              _buildInfrastructureSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool isNumber = false, bool isEmail = false, bool isPhone = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(color: readOnly ? Colors.grey.shade700 : Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: readOnly ? Colors.grey.shade100 : kFieldColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (readOnly) return null; // Skip validation if it's read-only
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
    final List<String> schoolTypes = ['Government', 'Semi-Government', 'Private', 'International'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("School Type", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _schoolType,
            iconEnabledColor: _isEditable ? Colors.black54 : Colors.grey.shade400,
            decoration: InputDecoration(
              hintText: "Select School Type",
              filled: true,
              fillColor: !_isEditable ? Colors.grey.shade100 : kFieldColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: schoolTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: _isEditable ? (val) => setState(() => _schoolType = val) : null,
            validator: (val) {
              if (!_isEditable) return null;
              return val == null ? 'Please select a type' : null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Infrastructure Components", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: !_isEditable ? Colors.grey.shade100 : Colors.white, 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300)
          ),
          child: Column(
            children: [
              _buildCheckboxTile("Electricity", _electricity, (val) => _electricity = val!),
              const Divider(height: 1),
              _buildCheckboxTile("Water Supply", _waterSupply, (val) => _waterSupply = val!),
              const Divider(height: 1),
              _buildCheckboxTile("Sanitation", _sanitation, (val) => _sanitation = val!),
              const Divider(height: 1),
              _buildCheckboxTile("Communication Facilities", _communication, (val) => _communication = val!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(title, style: TextStyle(fontSize: 14, color: !_isEditable ? Colors.grey.shade600 : Colors.black87, fontWeight: FontWeight.w500)),
      value: value,
      onChanged: _isEditable ? (val) => setState(() => onChanged(val)) : null,
      activeColor: kPrimaryColor,
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}