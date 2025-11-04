import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // 1. Import file_picker

// Primary color for UI consistency
const Color _primaryColor = Color(0xFF53BDFF);

class AddSchoolMasterPlanPage extends StatefulWidget {
  const AddSchoolMasterPlanPage({super.key});

  @override
  State<AddSchoolMasterPlanPage> createState() => _AddSchoolMasterPlanPageState();
}

class _AddSchoolMasterPlanPageState extends State<AddSchoolMasterPlanPage> {
  // State variables now store the actual selected file path (String?).
  // We use String? here to represent the path of the selected file.
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

  // 2. Actual file picking logic using file_picker
  Future<void> _pickImage(String type) async {
    // Show a dialog to the user indicating the type of file to select
    // For simplicity, we directly call the picker here.
    
    // Set the allowed extensions for JPG and PNG files
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      // A file was successfully selected
      setState(() {
        final filePath = result.files.single.path;
        final fileName = result.files.single.name;

        if (type == 'master') {
          _masterPlanImagePath = filePath;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Master Plan Selected: $fileName')),
          );
        } else if (type == 'updated') {
          _updatedPlanImagePath = filePath;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated Plan Selected: $fileName')),
          );
        }
      });
    } else {
      // User canceled the picker or selection failed.
      // We don't change the state here, but in a real app, you might want 
      // to handle file deselection/clearing if the user wants to remove the existing file.
      // For now, if they cancel, the existing selection remains.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File selection cancelled.')),
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
                
                // Print paths to console for verification (use file names for SnackBar)
                final masterFileName = _masterPlanImagePath?.split('/').last ?? 'None';
                final updatedFileName = _updatedPlanImagePath?.split('/').last ?? 'None';

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Submitted! Master: $masterFileName, Updated: $updatedFileName'),
                  ),
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
              // 3. Use the new _pickImage function
              onTap: () => _pickImage('master'), 
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
              // 3. Use the new _pickImage function
              onTap: () => _pickImage('updated'), 
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
      String? imagePath,
      {required VoidCallback onTap}) {
    
    // Check if an image path is present to determine selection state
    final bool isSelected = imagePath != null; 
    
    // Get only the file name from the full path for display
    final String displayText = isSelected 
        ? imagePath!.split('/').last // Extracts the file name
        : defaultText;
    
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
            // Display file path/name or default text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? _primaryColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
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