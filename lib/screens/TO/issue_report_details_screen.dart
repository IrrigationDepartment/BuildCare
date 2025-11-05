import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting the date

class IssueReportDetailsScreen extends StatefulWidget {
  final String issueId;
  const IssueReportDetailsScreen({super.key, required this.issueId});

  @override
  State<IssueReportDetailsScreen> createState() =>
      _IssueReportDetailsScreenState();
}

class _IssueReportDetailsScreenState extends State<IssueReportDetailsScreen> {
  // --- Style Constants ---
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  // --- State Variables ---
  final _formKey = GlobalKey<FormState>();
  bool _isPageLoading = true;
  bool _isSaving = false;

  // --- Controllers for each field ---
  late TextEditingController _schoolNameController;
  late TextEditingController _buildingNameController;
  late TextEditingController _buildingAreaController;
  late TextEditingController _numFloorsController;
  late TextEditingController _numClassroomsController;
  late TextEditingController _damageTypeController;
  late TextEditingController _descriptionController;
  
  // --- Variables for Date and Images ---
  DateTime? _selectedDate;
  String _formattedDate = 'Select Date';
  List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    // Initialize empty controllers first
    _schoolNameController = TextEditingController();
    _buildingNameController = TextEditingController();
    _buildingAreaController = TextEditingController();
    _numFloorsController = TextEditingController();
    _numClassroomsController = TextEditingController();
    _damageTypeController = TextEditingController();
    _descriptionController = TextEditingController();

    // Fetch data and populate controllers
    _fetchIssueDetails();
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _schoolNameController.dispose();
    _buildingNameController.dispose();
    _buildingAreaController.dispose();
    _numFloorsController.dispose();
    _numClassroomsController.dispose();
    _damageTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Data Fetching ---
  Future<void> _fetchIssueDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Populate controllers with existing data
        _schoolNameController.text = data['schoolName'] ?? '';
        _buildingNameController.text = data['buildingName'] ?? '';
        _buildingAreaController.text = data['buildingArea'] ?? '';
        _numFloorsController.text = data['numFloors']?.toString() ?? '';
        _numClassroomsController.text = data['numClassrooms']?.toString() ?? '';
        _damageTypeController.text = data['damageType'] ?? '';
        _descriptionController.text = data['description'] ?? '';

        // Handle date
        if (data['dateOfOccurance'] != null) {
          _selectedDate = (data['dateOfOccurance'] as Timestamp).toDate();
          _formattedDate = DateFormat('yyyy/MM/dd').format(_selectedDate!);
        }

        // Load images
        _images = data['imageUrls'] ?? [];

        setState(() {
          _isPageLoading = false;
        });
      } else {
        // Handle document not found
        setState(() {
          _isPageLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Issue details not found.'),
                backgroundColor: Colors.red),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Handle error
      setState(() {
        _isPageLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error fetching details: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Save Changes ---
  Future<void> _saveChanges() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return; // Don't save if validation fails
    }

    // 2. Set loading state
    setState(() {
      _isSaving = true;
    });

    try {
      // 3. Prepare data map
      final Map<String, dynamic> updatedData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _buildingNameController.text.trim(),
        'buildingArea': _buildingAreaController.text.trim(),
        'numFloors': int.tryParse(_numFloorsController.text.trim()),
        'numClassrooms': int.tryParse(_numClassroomsController.text.trim()),
        'damageType': _damageTypeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dateOfOccurance':
            _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        // Note: We are not editing 'imageUrls' here.
        // That would require a much more complex UI (add/remove buttons).
      };

      // 4. Update Firestore
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .update(updatedData);

      // 5. Show success and pop
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back after saving
      }
    } catch (e) {
      // 6. Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 7. Unset loading state
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --- Date Picker Dialog ---
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // User cannot pick a future date
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _formattedDate = DateFormat('yyyy/MM/dd').format(_selectedDate!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Repair Report',
            style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          // Updated "Save" button
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                // --- Form Widget ---
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Replaced _buildDetailRow with _buildTextFormField ---
                      _buildTextFormField(
                        controller: _schoolNameController,
                        label: 'School Name:',
                      ),
                      _buildTextFormField(
                        controller: _buildingNameController,
                        label: 'Select Damage Building:',
                      ),
                      _buildTextFormField(
                        controller: _buildingAreaController,
                        label: 'Building Area (sq. ft/m²):',
                      ),
                      _buildTextFormField(
                        controller: _numFloorsController,
                        label: 'Number of Floors:',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextFormField(
                        controller: _numClassroomsController,
                        label: 'Number of Classrooms:',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextFormField(
                        controller: _damageTypeController,
                        label: 'Type Of Damage:',
                      ),
                      _buildTextFormField(
                        controller: _descriptionController,
                        label: 'Description of Issue:',
                        maxLines: 4,
                      ),
                      // --- Date Picker Widget ---
                      _buildDatePicker(context),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Uploaded Images(JPG/PNG)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // This widget just displays images, it doesn't edit them
                      _buildImageGallery(_images),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- NEW: Helper to build editable text fields ---
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label'.replaceAll(":", ""),
              filled: true,
              fillColor: kBackgroundColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '$label cannot be empty'.replaceAll(":", "");
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // --- NEW: Helper to build the date picker ---
  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Of Damage Occurance:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate, // Call _pickDate function
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formattedDate,
                    style: const TextStyle(fontSize: 15, color: kSubTextColor),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      color: kSubTextColor, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED: Helper to build the image gallery ---
  Widget _buildImageGallery(List<dynamic> images) {
    if (images.isEmpty) {
      return const Text('No images uploaded.',
          style: TextStyle(color: kSubTextColor));
    }

    return SizedBox(
      height: 100, // Give the gallery a fixed height
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: images.map((imageUrl) {
            // --- ADDED: GestureDetector wrapper ---
            return GestureDetector(
              onTap: () {
                // --- ADDED: Navigation to a new zoomable screen ---
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Builder creates the new screen
                    builder: (context) => _buildImageZoomScreen(imageUrl.toString()),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl.toString(), // This is the server URL
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    // Loading and error builders for a better UX
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- NEW: Helper to build the full-screen zoomable image page ---
  Widget _buildImageZoomScreen(String imageUrl) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // This adds a white back arrow
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: Center(
        // InteractiveViewer is the widget that enables zooming and panning
        child: InteractiveViewer(
          panEnabled: true, // Allow panning
          minScale: 1.0,    // Start at 100%
          maxScale: 4.0,    // Allow user to zoom up to 400%
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain, // Show the whole image
            // Re-added loading/error builders for the zoom screen
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- This helper is no longer used, but kept for reference ---
  // Widget _buildDetailRow(String label, String? value) { ... }
}
