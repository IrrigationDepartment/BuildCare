import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../models/school.dart';

// --- NEW: Edit School Page ---
class EditSchoolPage extends StatefulWidget {
  final School school;
  final String userNic; // <-- MODIFIED: Accept the user's NIC

  const EditSchoolPage({
    Key? key, 
    required this.school,
    required this.userNic, // <-- MODIFIED: Add to constructor
  }) : super(key: key);

  @override
  _EditSchoolPageState createState() => _EditSchoolPageState();
}

class _EditSchoolPageState extends State<EditSchoolPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _typeController;
  late TextEditingController _zoneController;
  late TextEditingController _studentsController;
  late TextEditingController _teachersController;
  late TextEditingController _nonAcademicController;

  // Static list for School Type dropdown/picker (since it's 'Semi-Government' in the image)
  final List<String> _schoolTypes = [
    'Government',
    'Semi-Government',
    'Private',
    'International'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing school data
    _nameController = TextEditingController(text: widget.school.name);
    _addressController = TextEditingController(text: widget.school.address);
    _phoneController = TextEditingController(text: widget.school.phoneNumber);
    // Use the existing type or default to the first in the list
    _typeController = TextEditingController(text: widget.school.type);
    _zoneController = TextEditingController(text: widget.school.zone);
    _studentsController =
        TextEditingController(text: widget.school.students.toString());
    _teachersController =
        TextEditingController(text: widget.school.teachers.toString());
    _nonAcademicController =
        TextEditingController(text: widget.school.nonAcademicStaff.toString());
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _typeController.dispose(); // Will be disposed even if we use a dropdown
    _zoneController.dispose();
    _studentsController.dispose();
    _teachersController.dispose();
    _nonAcademicController.dispose();
    super.dispose();
  }

  // Function to handle saving the form
  Future<void> _saveChanges() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if the school type is a valid selection
    if (!_schoolTypes.contains(_typeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid School Type.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      
      // <-- MODIFIED: Use the NIC passed to this widget
      final String currentUserNic = widget.userNic;

      // Prepare the data to be updated
      final Map<String, dynamic> updateData = {
        'schoolName': _nameController.text,
        'schoolAddress': _addressController.text,
        'schoolPhone': _phoneController.text,
        'schoolType': _typeController.text,
        'educationalZone': _zoneController.text,
        'numStudents': int.tryParse(_studentsController.text) ?? 0,
        'numTeachers': int.tryParse(_teachersController.text) ?? 0,
        'numNonAcademic': int.tryParse(_nonAcademicController.text) ?? 0,

        // --- Add the "Edit Record" fields ---
        'lastEditedAt': Timestamp.now(),
        'lastEditedByNic': currentUserNic, // Save the real NIC
      };

      // Update the document in Firestore
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.school.id)
          .update(updateData);

      // Show success message and pop the page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${_nameController.text} details updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating school: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Match the style from the screenshot (which looks like a material page)
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_nameController.text}'), // Use the controller text
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // School Name - Matches the style of the screenshot
                  _buildTextFormField(
                      controller: _nameController,
                      label: 'School Name',
                      initialText: widget.school.name),
                  // School Address
                  _buildTextFormField(
                      controller: _addressController,
                      label: 'School Address',
                      initialText: widget.school.address),
                  // School Phone Number
                  _buildTextFormField(
                      controller: _phoneController,
                      label: 'School Phone Number',
                      initialText: widget.school.phoneNumber,
                      keyboardType: TextInputType.phone),

                  // School Type - Using a Dropdown/TextFormField combo to match the screenshot's 'fillable' field look
                  _buildTypeDropdownField(),

                  // School Educational Zone
                  _buildTextFormField(
                      controller: _zoneController,
                      label: 'School Educational Zone',
                      initialText: widget.school.zone),
                  // Number of Students
                  _buildTextFormField(
                    controller: _studentsController,
                    label: 'Number of Students',
                    initialText: widget.school.students.toString(),
                    keyboardType: TextInputType.number,
                    isNumber: true,
                  ),
                  // Number of Teachers
                  _buildTextFormField(
                    controller: _teachersController,
                    label: 'Number of Teachers',
                    initialText: widget.school.teachers.toString(),
                    keyboardType: TextInputType.number,
                    isNumber: true,
                  ),
                  // Number of Non-Academic Staff
                  _buildTextFormField(
                    controller: _nonAcademicController,
                    label: 'Number of Non-Academic Staff',
                    initialText: widget.school.nonAcademicStaff.toString(),
                    keyboardType: TextInputType.number,
                    isNumber: true,
                  ),
                  const SizedBox(height: 30),
                  // Save Changes Button - Matches the style of the screenshot
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.deepPurple.shade300.withOpacity(0.1),
                    ),
                    child: TextButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: TextButton.styleFrom(
                        backgroundColor: _isLoading
                            ? Colors.deepPurple.shade200
                            : Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2.5),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Removed the separate loading overlay since the button handles it
        ],
      ),
    );
  }

  // A custom widget to match the screenshot's TextFormField style
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String initialText,
    TextInputType keyboardType = TextInputType.text,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The label above the field, matching the screenshot's style
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              // The style from the screenshot suggests a filled field with rounded corners
              filled: true,
              fillColor: Colors.deepPurple.shade50.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide.none, // Hide border for a cleaner, filled look
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.grey.shade300), // Light grey outline
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Colors.deepPurple, width: 2), // Purple focus
              ),
              hintText: label,
            ),
            keyboardType: keyboardType,
            inputFormatters:
                isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a $label';
              }
              if (isNumber && int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
            // The text style to make the entered text prominent
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Custom Dropdown for School Type to match the TextFormField style
  Widget _buildTypeDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
            child: Text(
              'School Type',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          DropdownButtonFormField<String>(
            value: _schoolTypes.contains(_typeController.text)
                ? _typeController.text
                : _schoolTypes.first,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              filled: true,
              fillColor: Colors.deepPurple.shade50.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Colors.deepPurple, width: 2),
              ),
            ),
            items: _schoolTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _typeController.text = newValue;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a School Type';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}