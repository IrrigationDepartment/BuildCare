import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // 💡 New import for image picking
import 'dart:io'; // To handle the File type

class AddBuildingIssuesPage extends StatefulWidget {
  const AddBuildingIssuesPage({super.key});

  @override
  State<AddBuildingIssuesPage> createState() => _AddBuildingIssuesPageState();
}

class _AddBuildingIssuesPageState extends State<AddBuildingIssuesPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _classroomsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedBuilding;
  String? _selectedDamageType;
  DateTime? _selectedDate;
  
  // 💡 New state variable to hold the selected image file(s)
  final List<File> _selectedImages = []; 
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _textFieldBackgroundColor = Color(0xFFF3F3F3);

  final List<String> _buildingTypes = [
    'Academic Classroom', 'Office', 'Science Lab', 'Technology Lab', 'Library',
    'Hostel', 'Computer Lab', 'Dahampasala Lab', 'Store Room', 'Auditorium',
    'Main Hall', 'Changing Room', 'Security Room', 'Wash Room', 'Boundary Wall'
  ];

  final List<String> _damageTypes = [
    'Foundation & Wall Damage', 'Roofing Damage', 'Utility Damage (Electricity/Water)',
    'Floor Damage', 'Plumbing/Draining Structural Issue', 'Windows/Doors Frame Damage',
    'Staircase & Corridor Damage'
  ];

  @override
  void dispose() {
    _schoolNameController.dispose();
    _floorsController.dispose();
    _classroomsController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Function to show the Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor, // Primary color for date picker
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // 💡 New function to pick an image
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
      // Optionally show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image Added: ${pickedFile.name}')),
      );
    }
  }

  // 💡 New function to remove an image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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
          "Add your school building Issues",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: OutlinedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Display a confirmation message on successful validation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Building Issue Reported Successfully!')),
                  );
                  // Here you would typically save the data (e.g., to Firestore)
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
                _buildDropdown(
                  "Select Damage Building", 
                  "select Type of Damage Building", 
                  _buildingTypes, 
                  _selectedBuilding, 
                  (String? value) {
                    setState(() {
                      _selectedBuilding = value;
                    });
                  }
                ),
                _buildTextField("Number of Floors", "Enter number of floors in building", _floorsController, isNumber: true),
                _buildTextField("Number of Classrooms", "Enter Number of rooms in building", _classroomsController, isNumber: true),
                _buildDropdown(
                  "Type Of Damage", 
                  "select Type of Damage", 
                  _damageTypes, 
                  _selectedDamageType, 
                  (String? value) {
                    setState(() {
                      _selectedDamageType = value;
                    });
                  }
                ),
                _buildDescriptionField("Description of Issue", "Describe your School building Issue", _descriptionController),
                // 💡 Calling the modified function to handle uploads
                _buildUploadImagesSection(), 
                _buildDateField("Date Of Damage Occurance", "Enter Date Of Damage Occurance", _dateController, () => _selectDate(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable Text Field builder
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
              fillColor: _textFieldBackgroundColor,
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

  /// Reusable Dropdown Field builder
  Widget _buildDropdown(
    String label, 
    String hint, 
    List<String> items, 
    String? currentValue, // Current selected value from State
    Function(String? value) onChanged
  ) {
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
          DropdownButtonFormField<String>(
            value: currentValue, // CORRECT: Sets the currently selected item
            decoration: InputDecoration(
              hintText: hint,
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
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: onChanged, 
            validator: (value) => value == null ? 'Please select $label' : null,
          ),
        ],
      ),
    );
  }

  /// Specific builder for the Description field (Multiline Text Field).
  Widget _buildDescriptionField(String label, String hint, TextEditingController controller) {
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
            maxLines: 4, // Allow multiline input
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
            validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
          ),
        ],
      ),
    );
  }

  /// Builder for the Date Of Damage Occurance field.
  Widget _buildDateField(String label, String hint, TextEditingController controller, VoidCallback onTap) {
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
            readOnly: true, // Prevent manual typing
            onTap: onTap, // Open date picker on tap
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
              // Calendar icon at the end
              suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
            ),
            validator: (value) => value!.isEmpty ? 'Please select $label' : null,
          ),
        ],
      ),
    );
  }


  /// 💡 MODIFIED Builder for the Upload Images section.
  Widget _buildUploadImagesSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Images (JPG/PNG)',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          
          // 💡 InkWell added to make the area clickable for image upload
          InkWell( 
            onTap: _pickImage, // Call the image picker function
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: _textFieldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedImages.isEmpty ? Colors.transparent : _primaryColor,
                  width: 1.5
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 28, color: Colors.grey),
                  SizedBox(width: 10),
                  Text(
                    'Tap to Upload Building Damage Photos',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          // 💡 Display selected images
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 100, // Fixed height for the horizontal list
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}