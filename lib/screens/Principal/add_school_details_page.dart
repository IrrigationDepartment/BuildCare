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

  // --- Controllers ---
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController =
      TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _educationalZoneController =
      TextEditingController();
  final TextEditingController _studentsController = TextEditingController();
  final TextEditingController _teachersController = TextEditingController();
  final TextEditingController _nonAcademicController = TextEditingController();

  // --- Building controller ---
  final TextEditingController _buildingNameController = TextEditingController();

  // --- School suggestions data ---
  List<Map<String, dynamic>> _availableSchools = [];
  bool _isLoadingSchools = true;

  // --- State Variables ---
  String? _schoolType;
  bool _electricity = false;
  bool _waterSupply = false;
  bool _sanitation = false;
  bool _communication = false;

  bool _isLoading = false;
  bool _isFetchingData = true;
  String? _existingDocId;

  // --- Building names list ---
  List<String> _buildingNames = [];

  // --- Style Constants ---
  static const Color kPrimaryColor = Color(0xFF0077FF);
  static const Color kBackgroundColor = Color(0xFFF4F7FB);
  static const Color kFieldColor = Colors.white;
  static const Color kTextColor = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _fetchSchoolsForAutocomplete();
    await _loadExistingSchoolData();
    if (mounted) {
      setState(() {
        _isFetchingData = false;
      });
    }
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
    _buildingNameController.dispose();
    super.dispose();
  }

  // --- Fetch school list for autocomplete ---
  Future<void> _fetchSchoolsForAutocomplete() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .orderBy('schoolName')
          .get();

      final schools = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'schoolName': (data['schoolName'] ?? '').toString().trim(),
          'schoolAddress': (data['schoolAddress'] ?? '').toString(),
          'schoolEmail': (data['schoolEmail'] ?? '').toString(),
          'schoolPhone': (data['schoolPhone'] ?? '').toString(),
          'schoolType': data['schoolType'],
          'educationalZone': (data['educationalZone'] ?? '').toString(),
          'numStudents': data['numStudents'],
          'numTeachers': data['numTeachers'],
          'numNonAcademic': data['numNonAcademic'],
          'infrastructure': data['infrastructure'] ?? {},
          'buildingNames': data['buildingNames'] ?? [],
        };
      }).where((school) => (school['schoolName'] as String).isNotEmpty).toList();

      if (mounted) {
        setState(() {
          _availableSchools = schools;
          _isLoadingSchools = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching schools: $e");
      if (mounted) {
        setState(() {
          _isLoadingSchools = false;
        });
      }
    }
  }

  // --- Fetch Existing Data Logic ---
  Future<void> _loadExistingSchoolData() async {
    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: widget.userNic)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception("User not found.");
      }

      final userData = userQuery.docs.first.data() as Map<String, dynamic>;
      final String userSchoolName =
          (userData['schoolName'] ?? '').toString().trim();

      if (userSchoolName.isEmpty) {
        return;
      }

      _schoolNameController.text = userSchoolName;

      QuerySnapshot schoolQuery = await FirebaseFirestore.instance
          .collection('schools')
          .where('schoolName', isEqualTo: userSchoolName)
          .limit(1)
          .get();

      if (schoolQuery.docs.isNotEmpty) {
        final doc = schoolQuery.docs.first;
        _existingDocId = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        _schoolAddressController.text = data['schoolAddress']?.toString() ?? '';
        _phoneController.text = data['schoolPhone']?.toString() ?? '';
        _schoolEmailController.text = data['schoolEmail']?.toString() ?? '';
        _educationalZoneController.text =
            data['educationalZone']?.toString() ?? '';

        _studentsController.text = (data['numStudents'] ?? '').toString();
        _teachersController.text = (data['numTeachers'] ?? '').toString();
        _nonAcademicController.text =
            (data['numNonAcademic'] ?? '').toString();

        if (mounted) {
          setState(() {
            final List<String> validTypes = [
              'Government',
              'Semi-Government',
              'Private',
              'International'
            ];
            if (validTypes.contains(data['schoolType'])) {
              _schoolType = data['schoolType'];
            }

            final infra = data['infrastructure'] ?? {};
            _electricity = infra['electricity'] ?? false;
            _waterSupply = infra['waterSupply'] ?? false;
            _sanitation = infra['sanitation'] ?? false;
            _communication = infra['communication'] ?? false;

            final buildings = data['buildingNames'];
            if (buildings is List) {
              _buildingNames = buildings
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching school data: $e");
    }
  }

  void _addBuildingName() {
    final name = _buildingNameController.text.trim();
    if (name.isEmpty) return;

    final exists = _buildingNames.any(
      (element) => element.toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This building name already exists.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _buildingNames.add(name);
      _buildingNameController.clear();
    });
  }

  void _removeBuildingName(int index) {
    setState(() {
      _buildingNames.removeAt(index);
    });
  }

  void _moveBuildingUp(int index) {
    if (index == 0) return;
    setState(() {
      final item = _buildingNames.removeAt(index);
      _buildingNames.insert(index - 1, item);
    });
  }

  void _moveBuildingDown(int index) {
    if (index == _buildingNames.length - 1) return;
    setState(() {
      final item = _buildingNames.removeAt(index);
      _buildingNames.insert(index + 1, item);
    });
  }

  // --- Firestore Save/Update Function ---
  Future<void> _saveSchoolDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final bool isUpdating = _existingDocId != null;

      final Map<String, dynamic> schoolData = {
        'schoolName': _schoolNameController.text.trim(),
        'schoolAddress': _schoolAddressController.text.trim(),
        'schoolPhone': _phoneController.text.trim(),
        'schoolEmail': _schoolEmailController.text.trim(),
        'schoolType': _schoolType,
        'educationalZone': _educationalZoneController.text.trim(),
        'numStudents': int.tryParse(_studentsController.text.trim()) ?? 0,
        'numTeachers': int.tryParse(_teachersController.text.trim()) ?? 0,
        'numNonAcademic': int.tryParse(_nonAcademicController.text.trim()) ?? 0,
        'buildingNames': _buildingNames,
        'infrastructure': {
          'electricity': _electricity,
          'waterSupply': _waterSupply,
          'sanitation': _sanitation,
          'communication': _communication,
        },
        'addedByNic': widget.userNic,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String currentSchoolId;

      if (isUpdating) {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(_existingDocId)
            .update(schoolData);
        currentSchoolId = _existingDocId!;
      } else {
        schoolData['addedAt'] = FieldValue.serverTimestamp();
        schoolData['isActive'] = false;
        final newRef = await FirebaseFirestore.instance
            .collection('schools')
            .add(schoolData);
        currentSchoolId = newRef.id;
        _existingDocId = currentSchoolId;
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': isUpdating ? 'School Details Updated' : 'New School Added',
        'subtitle':
            '${_schoolNameController.text.trim()} was ${isUpdating ? 'updated' : 'added'} by Principal.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'school',
        'schoolId': currentSchoolId,
      });

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: $e'),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: kTextColor),
        title: Text(
          _existingDocId != null ? "School Master Data" : "Add School Details",
          style: const TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton(
                    onPressed: _isFetchingData ? null : _saveSchoolDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isFetchingData
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final bool isLargeScreen = constraints.maxWidth > 800;

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
                              _buildSectionTitle("Basic Details"),
                              _buildLockedSchoolNameField(),

                              _buildTextField(
                                "School Address",
                                "Enter Your School Address",
                                _schoolAddressController,
                              ),

                              if (isLargeScreen)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        "School E-mail",
                                        "Enter Your School E-mail",
                                        _schoolEmailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        isEmail: true,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        "School Phone Number",
                                        "Enter Contact Number",
                                        _phoneController,
                                        keyboardType: TextInputType.phone,
                                        isPhone: true,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildTextField(
                                  "School E-mail",
                                  "Enter Your School E-mail",
                                  _schoolEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  isEmail: true,
                                ),
                                _buildTextField(
                                  "School Phone Number",
                                  "Enter Your School Contact Number",
                                  _phoneController,
                                  keyboardType: TextInputType.phone,
                                  isPhone: true,
                                ),
                              ],

                              const SizedBox(height: 16),
                              _buildSectionTitle("Administrative Info"),

                              if (isLargeScreen)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildDropdown()),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        "Educational Zone",
                                        "Enter Your Educational Zone",
                                        _educationalZoneController,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildDropdown(),
                                _buildTextField(
                                  "School Educational Zone",
                                  "Enter Your School Educational Zone",
                                  _educationalZoneController,
                                ),
                              ],

                              const SizedBox(height: 16),
                              _buildSectionTitle("Demographics"),

                              if (isLargeScreen)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        "Students",
                                        "Total students",
                                        _studentsController,
                                        isNumber: true,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        "Teachers",
                                        "Total Teachers",
                                        _teachersController,
                                        isNumber: true,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        "Non-Academic",
                                        "Total Non-Academic",
                                        _nonAcademicController,
                                        isNumber: true,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildTextField(
                                  "Number of Students in School",
                                  "Enter Total students",
                                  _studentsController,
                                  isNumber: true,
                                ),
                                _buildTextField(
                                  "Number of Teachers in School",
                                  "Enter Total Teachers",
                                  _teachersController,
                                  isNumber: true,
                                ),
                                _buildTextField(
                                  "Number of Non-Academic Staff",
                                  "Enter Total Non-Academic",
                                  _nonAcademicController,
                                  isNumber: true,
                                ),
                              ],

                              const SizedBox(height: 16),
                              _buildBuildingsSection(),
                              const SizedBox(height: 16),
                              _buildInfrastructureSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kTextColor,
        ),
      ),
    );
  }

  Widget _buildLockedSchoolNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "School Name",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _schoolNameController,
            readOnly: true,
            style: TextStyle(color: Colors.grey.shade700),
            decoration: InputDecoration(
              hintText: "School Name",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: kPrimaryColor,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'School name not found';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool isNumber = false,
    bool isEmail = false,
    bool isPhone = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(
              color: readOnly ? Colors.grey.shade700 : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              filled: true,
              fillColor: readOnly ? Colors.grey.shade100 : kFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: kPrimaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (readOnly) return null;
              if (value == null || value.trim().isEmpty) return 'Field required';
              if (isEmail &&
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Enter valid email';
              }
              if (isPhone &&
                  (!RegExp(r'^\d{10}$').hasMatch(value.trim()))) {
                return 'Must be 10 digits';
              }
              if (isNumber && int.tryParse(value.trim()) == null) {
                return 'Enter valid number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    final List<String> schoolTypes = [
      'Government',
      'Semi-Government',
      'Private',
      'International'
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "School Type",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _schoolType,
            iconEnabledColor: Colors.black54,
            decoration: InputDecoration(
              hintText: "Select School Type",
              filled: true,
              fillColor: kFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: schoolTypes
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _schoolType = val),
            validator: (val) {
              return val == null ? 'Please select a type' : null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "School Buildings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _buildingNameController,
                decoration: InputDecoration(
                  hintText: "Enter building name",
                  filled: true,
                  fillColor: kFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onFieldSubmitted: (_) => _addBuildingName(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _addBuildingName,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _buildingNames.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No building names added yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: List.generate(_buildingNames.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: kPrimaryColor.withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: kPrimaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _buildingNames[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: "Move Up",
                            onPressed: () => _moveBuildingUp(index),
                            icon: const Icon(Icons.keyboard_arrow_up),
                          ),
                          IconButton(
                            tooltip: "Move Down",
                            onPressed: () => _moveBuildingDown(index),
                            icon: const Icon(Icons.keyboard_arrow_down),
                          ),
                          IconButton(
                            tooltip: "Delete",
                            onPressed: () => _removeBuildingName(index),
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildInfrastructureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Infrastructure Components",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _buildCheckboxTile(
                "Electricity",
                _electricity,
                (val) => _electricity = val!,
              ),
              const Divider(height: 1),
              _buildCheckboxTile(
                "Water Supply",
                _waterSupply,
                (val) => _waterSupply = val!,
              ),
              const Divider(height: 1),
              _buildCheckboxTile(
                "Sanitation",
                _sanitation,
                (val) => _sanitation = val!,
              ),
              const Divider(height: 1),
              _buildCheckboxTile(
                "Communication Facilities",
                _communication,
                (val) => _communication = val!,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: (val) => setState(() => onChanged(val)),
      activeColor: kPrimaryColor,
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}