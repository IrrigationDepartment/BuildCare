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

  final FocusNode _schoolNameFocusNode = FocusNode();

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
    _schoolNameFocusNode.dispose();
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
      // 1. Fetch User Data to get the assigned School Name
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

      // 2. Fetch the School Data using the School Name
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

        if (data.containsKey('lastEditedAt') && data['lastEditedAt'] != null) {
          final DateTime lastEdited =
              (data['lastEditedAt'] as Timestamp).toDate();
          final DateTime now = DateTime.now();
          final int daysSinceEdit = now.difference(lastEdited).inDays;

          if (daysSinceEdit < 180) {
            _isEditable = false;
            _nextEditDate = lastEdited.add(const Duration(days: 180));
          }
        }

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
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching school data: $e");
    }
  }

  void _applySelectedSchool(Map<String, dynamic> school) {
    setState(() {
      _schoolNameController.text = school['schoolName']?.toString() ?? '';
      _schoolAddressController.text = school['schoolAddress']?.toString() ?? '';
      _schoolEmailController.text = school['schoolEmail']?.toString() ?? '';
      _phoneController.text = school['schoolPhone']?.toString() ?? '';
      _educationalZoneController.text =
          school['educationalZone']?.toString() ?? '';

      final List<String> validTypes = [
        'Government',
        'Semi-Government',
        'Private',
        'International'
      ];
      final selectedType = school['schoolType']?.toString();
      if (selectedType != null && validTypes.contains(selectedType)) {
        _schoolType = selectedType;
      }

      _studentsController.text = (school['numStudents'] ?? '').toString();
      _teachersController.text = (school['numTeachers'] ?? '').toString();
      _nonAcademicController.text =
          (school['numNonAcademic'] ?? '').toString();

      final infra = school['infrastructure'] ?? {};
      _electricity = infra['electricity'] ?? false;
      _waterSupply = infra['waterSupply'] ?? false;
      _sanitation = infra['sanitation'] ?? false;
      _communication = infra['communication'] ?? false;
    });
  }

  // --- Firestore Save/Update Function ---
  Future<void> _saveSchoolDetails() async {
    if (!_isEditable) return;
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
        'infrastructure': {
          'electricity': _electricity,
          'waterSupply': _waterSupply,
          'sanitation': _sanitation,
          'communication': _communication,
        },
        'addedByNic': widget.userNic,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastEditedAt': FieldValue.serverTimestamp(),
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
          if (_isEditable)
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
                              if (!_isEditable)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_clock,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "Editing is locked. School details can only be updated every 6 months. Next available edit date: ${_nextEditDate != null ? DateFormat.yMMMMd().format(_nextEditDate!) : 'N/A'}.",
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              _buildSectionTitle("Basic Details"),
                              _buildSchoolNameAutocompleteField(),

                              _buildTextField(
                                "School Address",
                                "Enter Your School Address",
                                _schoolAddressController,
                                readOnly: !_isEditable,
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
                                        readOnly: !_isEditable,
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
                                        readOnly: !_isEditable,
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
                                  readOnly: !_isEditable,
                                ),
                                _buildTextField(
                                  "School Phone Number",
                                  "Enter Your School Contact Number",
                                  _phoneController,
                                  keyboardType: TextInputType.phone,
                                  isPhone: true,
                                  readOnly: !_isEditable,
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
                                        readOnly: !_isEditable,
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
                                  readOnly: !_isEditable,
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
                                        readOnly: !_isEditable,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        "Teachers",
                                        "Total Teachers",
                                        _teachersController,
                                        isNumber: true,
                                        readOnly: !_isEditable,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        "Non-Academic",
                                        "Total Non-Academic",
                                        _nonAcademicController,
                                        isNumber: true,
                                        readOnly: !_isEditable,
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
                                  readOnly: !_isEditable,
                                ),
                                _buildTextField(
                                  "Number of Teachers in School",
                                  "Enter Total Teachers",
                                  _teachersController,
                                  isNumber: true,
                                  readOnly: !_isEditable,
                                ),
                                _buildTextField(
                                  "Number of Non-Academic Staff",
                                  "Enter Total Non-Academic",
                                  _nonAcademicController,
                                  isNumber: true,
                                  readOnly: !_isEditable,
                                ),
                              ],

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

  Widget _buildSchoolNameAutocompleteField() {
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
          !_isEditable
              ? TextFormField(
                  controller: _schoolNameController,
                  readOnly: true,
                  style: TextStyle(color: Colors.grey.shade700),
                  decoration: InputDecoration(
                    hintText: "Enter Your School name",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
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
                )
              : RawAutocomplete<Map<String, dynamic>>(
                  textEditingController: _schoolNameController,
                  focusNode: _schoolNameFocusNode,
                  displayStringForOption: (option) =>
                      option['schoolName']?.toString() ?? '',
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query =
                        textEditingValue.text.trim().toLowerCase();

                    if (query.isEmpty) {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }

                    return _availableSchools.where((school) {
                      final name =
                          school['schoolName']?.toString().toLowerCase() ?? '';
                      return name.contains(query);
                    }).take(8);
                  },
                  onSelected: _applySelectedSchool,
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController controller,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: _isLoadingSchools
                            ? "Loading schools..."
                            : "Enter Your School name",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: kFieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
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
                        suffixIcon: _isLoadingSchools
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {});
                                    },
                                  )
                                : const Icon(Icons.search),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Field required';
                        }
                        return null;
                      },
                    );
                  },
                  optionsViewBuilder: (
                    BuildContext context,
                    AutocompleteOnSelected<Map<String, dynamic>> onSelected,
                    Iterable<Map<String, dynamic>> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: MediaQuery.of(context).size.width > 900
                              ? 420
                              : MediaQuery.of(context).size.width - 48,
                          constraints: const BoxConstraints(maxHeight: 260),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              final name =
                                  option['schoolName']?.toString() ?? '';
                              final zone =
                                  option['educationalZone']?.toString() ?? '';

                              return ListTile(
                                leading: const Icon(
                                  Icons.school_outlined,
                                  color: kPrimaryColor,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: zone.isNotEmpty
                                    ? Text(zone)
                                    : null,
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
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
              if (value == null || value.isEmpty) return 'Field required';
              if (isEmail &&
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Enter valid email';
              }
              if (isPhone &&
                  (!RegExp(r'^\d{10}$').hasMatch(value.trim()))) {
                return 'Must be 10 digits';
              }
              if (isNumber && int.tryParse(value) == null) {
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
            value: _schoolType,
            iconEnabledColor:
                _isEditable ? Colors.black54 : Colors.grey.shade400,
            decoration: InputDecoration(
              hintText: "Select School Type",
              filled: true,
              fillColor: !_isEditable ? Colors.grey.shade100 : kFieldColor,
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
            onChanged:
                _isEditable ? (val) => setState(() => _schoolType = val) : null,
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
            color: !_isEditable ? Colors.grey.shade100 : Colors.white,
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
        style: TextStyle(
          fontSize: 14,
          color: !_isEditable ? Colors.grey.shade600 : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: _isEditable ? (val) => setState(() => onChanged(val)) : null,
      activeColor: kPrimaryColor,
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}