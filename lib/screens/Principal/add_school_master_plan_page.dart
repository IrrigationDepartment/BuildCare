import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart'; 

class AddMasterPlanScreen extends StatefulWidget {
  final String schoolName;
  final String userNic;
  // Optional ID for editing an existing document
  final String? masterPlanId;

  const AddMasterPlanScreen({
    Key? key,
    required this.schoolName,
    required this.userNic,
    this.masterPlanId, 
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
  String _currentImageUrl = ''; 
  
  // Cache for reviewer details to optimize the reviews dialog
  static final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.masterPlanId != null) {
        _loadMasterPlanForEdit(widget.masterPlanId!);
      }
    });
  }

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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        _currentImageUrl = ''; 
      });
    }
  }

  Future<void> _uploadAndSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (widget.masterPlanId == null && _pickedFile == null && _currentImageUrl.isEmpty) {
      _showErrorSnackBar("Please select an image to upload.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String finalImageUrl = _currentImageUrl;

    try {
      if (_pickedFile != null) {
        var uri = Uri.parse("http://buildcare.atigalle.x10.mx/index.php");
        var request = http.MultipartRequest("POST", uri);

        request.fields['description'] = _descriptionController.text;
        request.fields['schoolName'] = widget.schoolName;

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
            _showErrorSnackBar("Server upload error: ${decodedResponse['message']}");
            return;
          }
        } else {
          _showErrorSnackBar("HTTP Upload Error: ${response.statusCode}");
          return;
        }
      }

      DateTime now = DateTime.now();
      String dateString = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
      String timeString = "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}";

      Map<String, dynamic> firestoreData = {
        'schoolName': widget.schoolName,    
        'description': _descriptionController.text,
        'masterPlanUrl': finalImageUrl,
        'addedByNic': widget.userNic,       
      };

      if (widget.masterPlanId == null) {
        firestoreData['createdAt'] = Timestamp.now();
        firestoreData['uploadDate'] = dateString; 
        firestoreData['uploadTime'] = timeString; 
        
        await FirebaseFirestore.instance
            .collection('schoolMasterPlans')
            .add(firestoreData);
        _showSuccessSnackBar("Master plan added successfully!");
      } else {
        firestoreData['updatedAt'] = Timestamp.now();
        firestoreData['lastEditDate'] = dateString;
        firestoreData['lastEditTime'] = timeString;

        await FirebaseFirestore.instance
            .collection('schoolMasterPlans')
            .doc(widget.masterPlanId)
            .update(firestoreData);
        _showSuccessSnackBar("Master plan updated successfully!");
      }

      _descriptionController.clear();
      setState(() {
        _pickedFile = null;
        _currentImageUrl = '';
      });
      if (mounted) {
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

  Future<void> _deleteMasterPlan(String docId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('schoolMasterPlans')
          .doc(docId)
          .delete();

      _showSuccessSnackBar("Master plan deleted successfully!");
      
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

  Future<void> _showDeleteConfirmationDialog(String docId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
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

  // --- OPTIMIZED REVIEWS DIALOG ---
  void _showReviewsDialog(String masterPlanId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Review History"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, 
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schoolMasterPlans')
                  .doc(masterPlanId)
                  .collection('reviews')
                  .orderBy('reviewedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No reviews added yet.", style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    String note = data['note'] ?? 'No Note';
                    String reviewerNicOrId = data['reviewerName'] ?? ''; // Assuming this holds the User ID or NIC based on your DB setup
                    Timestamp? ts = data['reviewedAt'];
                    String dateStr = ts != null 
                      ? DateFormat('yyyy-MM-dd hh:mm a').format(ts.toDate()) 
                      : 'Unknown Date';

                    // Using FutureBuilder to dynamically fetch the real user name
                    return FutureBuilder<void>(
                      future: _fetchReviewerName(reviewerNicOrId),
                      builder: (context, nameSnapshot) {
                        String realName = "Loading...";
                        if (nameSnapshot.connectionState == ConnectionState.done) {
                           realName = _userCache[reviewerNicOrId]?['name'] ?? 'Unknown User';
                        }

                        return Card(
                          color: Colors.grey[50],
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: const Icon(Icons.comment, color: Colors.blueAccent),
                            title: Text(note, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text("By: $realName"),
                                Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        );
                      }
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // Helper to fetch reviewer names into a cache to avoid lag
  Future<void> _fetchReviewerName(String identifier) async {
    if (identifier.isEmpty || _userCache.containsKey(identifier)) return;
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(identifier).get();
      if (doc.exists && doc.data() != null) {
        _userCache[identifier] = doc.data()!;
      } else {
        var query = await FirebaseFirestore.instance.collection('users').where('nic', isEqualTo: identifier).limit(1).get();
        if (query.docs.isNotEmpty) {
           _userCache[identifier] = query.docs.first.data();
        }
      }
    } catch (e) {
      debugPrint("Error fetching reviewer: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
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
                    
                    // --- ACTION BUTTONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        // 1. VIEW REVIEWS BUTTON 
                        TextButton.icon(
                          icon: const Icon(Icons.visibility, size: 20, color: Colors.orange),
                          label: const Text("Reviews", style: TextStyle(color: Colors.orange)),
                          onPressed: () {
                            _showReviewsDialog(masterPlanId);
                          },
                        ),

                        // Right side: Edit and Delete
                        Row(
                          children: [
                            // EDIT Button
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddMasterPlanScreen(
                                      schoolName: schoolName,
                                      userNic: widget.userNic,
                                      masterPlanId: masterPlanId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // DELETE Button
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(masterPlanId),
                            ),
                          ],
                        )
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

  // BUILD THE RESPONSIVE UI
  @override
  Widget build(BuildContext context) {
    String titleText = widget.masterPlanId == null ? "Add New Master Plan" : "Edit Master Plan";
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
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
                  child: OutlinedButton(
                    onPressed: _uploadAndSave,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue, width: 2), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if the screen is wide enough for a two-column layout
            bool isDesktop = constraints.maxWidth >= 800;

            if (isDesktop) {
              // --- DESKTOP / WEB LAYOUT (Two Columns) ---
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: The Form
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: _buildFormSection(),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Column 2: Existing Records List
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Your Submitted Master Plans",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15),
                            _buildRecordsList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // --- MOBILE LAYOUT (Stacked) ---
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormSection(),
                    const SizedBox(height: 30),
                    const Text(
                      "Your Submitted Master Plans",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    _buildRecordsList(),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Extracted the form into its own widget builder for cleaner layout management
  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  height: 250, // Slightly taller for better viewing
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
                              ? Image.network(_pickedFile!.path, fit: BoxFit.cover)
                              : Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
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
                                  Icon(Icons.image_search, size: 60, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text("Tap to upload master plan",
                                      style: TextStyle(color: Colors.grey[600])),
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
                  hintText: "Describe the school master plan...",
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
            ],
          ),
        ),
      ],
    );
  }
}