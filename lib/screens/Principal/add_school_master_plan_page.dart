import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AddMasterPlanScreen extends StatefulWidget {
  final String schoolName;
  final String userNic;
  // Optional ID for editing an existing document
  final String? masterPlanId;

  const AddMasterPlanScreen({
    Key? key,
    required this.schoolName,
    required this.userNic,
    this.masterPlanId, // Make the ID optional
  }) : super(key: key);

  @override
  _AddMasterPlanScreenState createState() => _AddMasterPlanScreenState();
}

class _AddMasterPlanScreenState extends State<AddMasterPlanScreen> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedFile;
  bool _isLoading = false;
  String _currentImageUrl = ''; // To show existing image when editing

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure context is available before async call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.masterPlanId != null) {
        _loadMasterPlanForEdit(widget.masterPlanId!);
      }
    });
  }

  // Function to fetch existing data for editing
  Future<void> _loadMasterPlanForEdit(String id) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('schoolMasterPlans')
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _descriptionController.text = data['description'] ?? '';
        setState(() {
          _currentImageUrl = data['masterPlanUrl'] ?? '';
        });
        _showSuccessSnackBar("Master Plan loaded for editing.");
      } else {
        _showErrorSnackBar("Error: Master Plan not found.");
      }
    } catch (e) {
      _showErrorSnackBar("Error loading plan: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 1. Method to pick an image
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        _currentImageUrl = ''; // Clear current image URL if a new image is picked
      });
    }
  }

  // 2. Main method to upload and save/update data
  Future<void> _uploadAndSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (widget.masterPlanId == null &&
        _pickedFile == null &&
        _currentImageUrl.isEmpty) {
      _showErrorSnackBar("Please select an image to upload.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String finalImageUrl = _currentImageUrl;

    try {
      if (_pickedFile != null) {
        // --- STEP A: Upload NEW Image to your PHP Server ---
        var uri = Uri.parse("http://buildcare.atigalle.x10.mx/index.php");
        var request = http.MultipartRequest("POST", uri);

        request.fields['description'] = _descriptionController.text;
        request.fields['schoolName'] = widget.schoolName;

        // Cross-platform file upload logic
        if (kIsWeb) {
          var bytes = await _pickedFile!.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(
              'master_plan_file', bytes,
              filename: _pickedFile!.name);
          request.files.add(multipartFile);
        } else {
          var stream = _pickedFile!.openRead();
          var length = await _pickedFile!.length();
          var multipartFile = http.MultipartFile('master_plan_file', stream, length,
              filename: _pickedFile!.name);
          request.files.add(multipartFile);
        }

        var response = await request.send();
        var responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          var decodedResponse = jsonDecode(responseBody);
          if (decodedResponse['status'] == 'success') {
            finalImageUrl = decodedResponse['masterPlanUrl'];
          } else {
            _showErrorSnackBar(
                "Server upload error: ${decodedResponse['message']}");
            return;
          }
        } else {
          _showErrorSnackBar("HTTP Upload Error: ${response.statusCode}");
          return;
        }
      }
      // If we are editing AND no new file was picked, finalImageUrl remains _currentImageUrl

      // --- STEP B: Save/Update URL to Firestore ---
      Map<String, dynamic> firestoreData = {
        'schoolName': widget.schoolName,
        'description': _descriptionController.text,
        'masterPlanUrl': finalImageUrl,
        'addedByNic': widget.userNic,
      };

      if (widget.masterPlanId == null) {
        // CREATE NEW RECORD
        firestoreData['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('schoolMasterPlans')
            .add(firestoreData);
        _showSuccessSnackBar("Master plan added successfully!");
      } else {
        // UPDATE EXISTING RECORD
        firestoreData['updatedAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('schoolMasterPlans')
            .doc(widget.masterPlanId)
            .update(firestoreData);
        _showSuccessSnackBar("Master plan updated successfully!");
      }

      // Clear form/navigate after successful submission/update
      _descriptionController.clear();
      setState(() {
        _pickedFile = null;
        _currentImageUrl = '';
      });
      if (mounted) {
        // Send true back to indicate a possible refresh is needed on the previous page
        Navigator.pop(context, true); 
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred during save: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- DELETE FUNCTIONALITY ---
  Future<void> _deleteMasterPlan(String docId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Step A: Delete the document from Firestore
      await FirebaseFirestore.instance
          .collection('schoolMasterPlans')
          .doc(docId)
          .delete();

      _showSuccessSnackBar("Master plan deleted successfully!");
      
      // Navigate back after deletion
      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {
      _showErrorSnackBar("Error deleting plan: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // New utility function for confirmation dialog
  Future<void> _showDeleteConfirmationDialog(String docId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this master plan?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMasterPlan(docId);
              },
            ),
          ],
        );
      },
    );
  }
  // --- END DELETE FUNCTIONALITY ---

  // --- Helper snackbar methods (assuming they are correct) ---
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Widget to display the record list using StreamBuilder
  Widget _buildRecordsList() {
    return StreamBuilder<QuerySnapshot>(
      // Use where clause to filter by current user's NIC
      stream: FirebaseFirestore.instance
          .collection('schoolMasterPlans')
          .where('addedByNic', isEqualTo: widget.userNic)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text(
                  'Error loading data: ${snapshot.error}. Please ensure the required Firestore index is created.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text('No master plans added by you yet.'),
            ),
          );
        }

        final documents = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            final masterPlanId = doc.id;
            final schoolName = data['schoolName'] ?? 'N/A';
            final description = data['description'] ?? 'No description';
            final timestamp = data['createdAt'] as Timestamp?;

            String formattedDate = timestamp != null
                ? 'Added on: ${timestamp.toDate().toString().split(' ')[0]}'
                : 'Date N/A';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map_outlined, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(schoolName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(description,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text(formattedDate,
                                  style:
                                      TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // EDIT Button
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text("Edit"),
                          onPressed: () async {
                            // Navigate to the same screen for editing
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddMasterPlanScreen(
                                  schoolName: schoolName,
                                  userNic: widget.userNic,
                                  masterPlanId: masterPlanId, // PASS THE ID HERE
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        // DELETE Button
                        TextButton.icon(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.red),
                          label: const Text("Delete",
                              style: TextStyle(color: Colors.red)),
                          onPressed: () => _showDeleteConfirmationDialog(masterPlanId),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  // 3. Build the UI
  @override
  Widget build(BuildContext context) {
    String titleText =
        widget.masterPlanId == null ? "Add New Master Plan" : "Edit Master Plan";
    String buttonText = widget.masterPlanId == null ? "Save" : "Update";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          // 🔄 CHANGE 1: Changed icon from Icons.arrow_back_ios to standard Icons.arrow_back
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context, true), // Pop and signal refresh
        ),
        actions: [
          // Save/Update Button
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              // 🔄 CHANGE 2: Changed from TextButton to OutlinedButton for blue outline effect
              : Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
                  child: OutlinedButton(
                    onPressed: _uploadAndSave,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue, width: 2), // Blue outline
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
            // --- Record Submission Form ---
            const Text(
              "Master Plan Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Master Plan Image",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  // Image Upload/Display Box
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _pickedFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(_pickedFile!.path,
                                      fit: BoxFit.cover)
                                  : Image.file(File(_pickedFile!.path),
                                      fit: BoxFit.cover),
                            )
                          : _currentImageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_currentImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, o, s) => const Icon(
                                          Icons.broken_image,
                                          size: 60,
                                          color: Colors.red)),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_search,
                                          size: 60, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text("Tap to upload master plan",
                                          style: TextStyle(
                                              color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Box
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "describe about school master plan",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a description";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // --- Record Display Section ---
            const Text(
              "Your Submitted Master Plans",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Display the records added by the current NIC
            _buildRecordsList(),
          ],
        ),
      ),
    );
  }
}