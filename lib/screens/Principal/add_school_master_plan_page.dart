import 'package:flutter/material.dart';

// Primary color for UI consistency
const Color _primaryColor = Color(0xFF53BDFF);

class AddSchoolMasterPlanPage extends StatefulWidget {
  const AddSchoolMasterPlanPage({super.key});

  @override
  State<AddSchoolMasterPlanPage> createState() => _AddSchoolMasterPlanPageState();
}

class _AddSchoolMasterPlanPageState extends State<AddSchoolMasterPlanPage> {
  // State variables store the simulated image path (String?). Null means no file selected.
  // This simulates holding the path to the file selected via ImagePicker.
  String? _masterPlanImagePath;
  String? _updatedPlanImagePath;
  
  // Text editing controllers
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _schoolNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Helper function to simulate file selection or deselection (like ImagePicker)
  // NOTE: In this restricted environment, we must simulate the file selection 
  // by toggling between a mock file name and null.
  void _pickImageSimulation(String type) {
    setState(() {
      if (type == 'master') {
        // Toggle: if no file, set a mock name/path; if file exists, clear it.
        _masterPlanImagePath = _masterPlanImagePath == null
            ? 'MasterPlan_2025_v1.jpg'
            : null;
      } else if (type == 'updated') {
        _updatedPlanImagePath = _updatedPlanImagePath == null
            ? 'UpdatedPlan_2026_Annex.png'
            : null;
      }
    });
    
    // In a production app, the actual file picker logic (like in the reference code)
    // would be implemented here, storing the actual file or its path/name.
    if (type == 'master' && _masterPlanImagePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image Selected: $_masterPlanImagePath (Simulated)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Back button navigation
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add School Master Plan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Save button as an OutlinedButton with a blue border
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Adjust padding for visual appeal
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implement actual save logic (e.g., uploading the files to a database like Firestore/Storage)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Master Plan form submitted (Simulated)!')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primaryColor, width: 1.5), // Blue border
                foregroundColor: _primaryColor, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // School Name Field
            _buildSectionTitle('School Name'),
            _buildTextField(
              controller: _schoolNameController,
              hintText: 'Enter Your School name',
              maxLines: 1,
            ),
            const SizedBox(height: 30),

            // Master Plan Upload Section
            _buildSectionTitle('Upload Master Plan (JPG/PNG)'),
            _buildFileUploadArea(
              context,
              'Upload school master plan',
              _masterPlanImagePath, // Pass the image path
              onTap: () => _pickImageSimulation('master'), // Use the pick image simulation
            ),
            const SizedBox(height: 30),

            // Description Field
            _buildSectionTitle('Description'),
            _buildTextField(
              controller: _descriptionController,
              hintText: 'describe about school master plan',
              maxLines: 5,
            ),
            const SizedBox(height: 40),

            // Updated Master Plan Note
            _buildUpdatedPlanNote(),
            const SizedBox(height: 10),

            // Updated Master Plan Upload Section
            _buildFileUploadArea(
              context,
              'Upload updated school master plan',
              _updatedPlanImagePath, // Pass the image path
              onTap: () => _pickImageSimulation('updated'), // Use the pick image simulation
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  // Helper widget for section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Helper widget for text input fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: const EdgeInsets.all(15),
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  // Helper widget for the file upload area
  Widget _buildFileUploadArea(
      BuildContext context,
      String defaultText,
      String? imagePath, // Changed name to reflect the user's reference file
      {required VoidCallback onTap}) {
    
    // Check if an image path is present to determine selection state
    final bool isSelected = imagePath != null; 
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.cloud_upload_outlined, // Change icon when selected
              size: 40,
              color: isSelected ? _primaryColor : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              // Display file path/name or default text
              isSelected ? imagePath! : defaultText, 
              style: TextStyle(
                color: isSelected ? _primaryColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the long note about updated plans
  Widget _buildUpdatedPlanNote() {
    return const Text(
      'If newly added building to school, principal should upload their new master plan(JPG/PNG)',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}
