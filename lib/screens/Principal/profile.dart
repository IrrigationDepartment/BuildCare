import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'settings_page.dart';
import 'dashboard.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const ProfilePage({
    super.key,
    required this.userData,
    required this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingImage = false;
  bool _isUpdatingData = false;
  bool _isLoadingData = true;
  String? _profileImageUrl;

  List<Map<String, dynamic>> _availableSchools = [];
  String? _selectedSchoolId;

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _secondaryColor = Color(0xFF0077FF);

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolPhoneController;
  
  // Captures the Autocomplete's internal controller
  TextEditingController? _autoCompleteController; 

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.userData['profile_image'];
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['mobilePhone'] ?? widget.userData['phone'] ?? '');
    _schoolNameController = TextEditingController(text: widget.userData['schoolName'] ?? '');
    _schoolPhoneController = TextEditingController(text: widget.userData['officePhone'] ?? '');

    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchSchoolsForAutocomplete();
    await _fetchLatestUserData();
    if (mounted) setState(() => _isLoadingData = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _schoolNameController.dispose();
    _schoolPhoneController.dispose();
    _autoCompleteController?.dispose();
    super.dispose();
  }

  // --- FETCHING ---
  Future<void> _fetchSchoolsForAutocomplete() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('schools').get();
      if (mounted) {
        _availableSchools = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'schoolName': data['schoolName'] ?? '',
            'schoolPhone': data['schoolPhone'] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching schools: $e");
    }
  }

  Future<void> _fetchLatestUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists && mounted) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _profileImageUrl = userData['profile_image'];
          _nameController.text = userData['name'] ?? '';
          _phoneController.text = userData['mobilePhone'] ?? userData['phone'] ?? '';
          _schoolNameController.text = userData['schoolName'] ?? '';
          _schoolPhoneController.text = userData['officePhone'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  // --- IMAGE UPLOAD (YOUR CUSTOM BACKEND LOGIC + WEB COMPATIBILITY) ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      // Use your requested endpoint
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://buildcare.atigalle.x10.mx/index.php') 
      );
      
      // Read as bytes (Works on Web, iOS, Android)
      final bytes = await pickedFile.readAsBytes();
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_image', 
          bytes,
          filename: 'upload.jpg', // Forced filename as requested
        ),
      );
      
      // Optional: Pass userId if your index.php requires it to map to the correct user directory
      request.fields['userId'] = widget.userId; 

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
        } catch (e) {
          throw Exception("Invalid JSON from server: ${response.body}");
        }

        // Checking your custom 'status' flag
        if (jsonResponse['status'] == 'success') {
          String newImageUrl = jsonResponse['profileImageUrl'];

          // Update Firestore
          await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
            'profile_image': newImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            _profileImageUrl = newImageUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Photo Updated!"), backgroundColor: Colors.green));
          }
        } else {
           throw Exception(jsonResponse['message'] ?? "Unknown server error");
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // --- UPDATING DATA ---
  Future<void> _updateProfileData() async {
    String typedSchoolName = (_autoCompleteController?.text ?? _schoolNameController.text).trim();

    if (_nameController.text.trim().isEmpty || typedSchoolName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and School cannot be empty.")));
      return;
    }

    setState(() => _isUpdatingData = true);

    try {
      String typedSchoolPhone = _schoolPhoneController.text.trim();
      String userNic = widget.userData['nic']?.toString() ?? "";

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. School Collection Update logic
      DocumentReference schoolRef;
      bool isNewSchool = true;
      
      for (var school in _availableSchools) {
        if (school['schoolName'].toString().toLowerCase() == typedSchoolName.toLowerCase()) {
          isNewSchool = false;
          _selectedSchoolId = school['id'];
          break;
        }
      }

      if (isNewSchool) {
        schoolRef = FirebaseFirestore.instance.collection('schools').doc();
        batch.set(schoolRef, {
          'addedAt': FieldValue.serverTimestamp(),
          'addedByNic': userNic,
          'schoolName': typedSchoolName,
          'schoolPhone': typedSchoolPhone,
          'isActive': false, 
          'educationalZone': null,
          'schoolAddress': null,
          'schoolEmail': null,
          'schoolType': null,
          'numStudents': null,
          'numTeachers': null,
          'numNonAcademic': null,
          'infrastructure': {
            'communication': false,
            'electricity': false,
            'sanitation': false,
            'waterSupply': false,
          }
        });
      } else {
        schoolRef = FirebaseFirestore.instance.collection('schools').doc(_selectedSchoolId);
        batch.update(schoolRef, {'schoolPhone': typedSchoolPhone, 'schoolName': typedSchoolName});
      }

      // 2. EXPLICITLY UPDATE THE USER COLLECTION
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      batch.update(userRef, {
        'name': _nameController.text.trim(),
        'mobilePhone': _phoneController.text.trim(),
        'schoolName': typedSchoolName,
        'officePhone': typedSchoolPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update other matching records if they exist
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: userNic)
          .where('userType', isEqualTo: 'Principal')
          .get();

      for (var doc in userQuery.docs) {
        if (doc.id != widget.userId) { 
          batch.update(doc.reference, {
            'name': _nameController.text.trim(),
            'mobilePhone': _phoneController.text.trim(),
            'schoolName': typedSchoolName,
            'officePhone': typedSchoolPhone,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      await _fetchLatestUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingData = false);
    }
  }

  // --- RESPONSIVE UI ---

  Widget _buildLockedCard(String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        trailing: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile Settings", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator()) 
        : SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isLargeScreen = constraints.maxWidth > 800;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isLargeScreen ? 1000 : 600),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 40 : 24, 
                        vertical: 24
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 65,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                                child: _profileImageUrl == null 
                                    ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                                    : null,
                              ),
                              if (_isUploadingImage)
                                const Positioned.fill(
                                  child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 6),
                                ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          isLargeScreen 
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildSystemInfoSection()),
                                  const SizedBox(width: 48),
                                  Expanded(child: _buildEditableSection()),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildEditableSection(),
                                  const SizedBox(height: 30),
                                  const Divider(height: 40),
                                  _buildSystemInfoSection(),
                                ],
                              ),
                          
                          const SizedBox(height: 40),
                          
                          SizedBox(
                            width: isLargeScreen ? 400 : double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isUpdatingData ? null : _updateProfileData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isUpdatingData 
                                  ? const CircularProgressIndicator(color: Colors.white) 
                                  : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
    );
  }

  Widget _buildSystemInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("System Records", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        const Text("These details cannot be changed.", style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 16),
        _buildLockedCard("Email Address", widget.userData['email']?.toString() ?? 'N/A', Icons.email_outlined),
        _buildLockedCard("Account Type", widget.userData['userType']?.toString() ?? 'N/A', Icons.admin_panel_settings_outlined),
        _buildLockedCard("National Identity Card (NIC)", widget.userData['nic']?.toString() ?? 'N/A', Icons.badge_outlined),
      ],
    );
  }

  Widget _buildEditableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Editable Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        const Text("Update your personal and school details.", style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 16),
        _buildTextField("Full Name", _nameController, Icons.person_outline),
        _buildTextField("Personal Mobile", _phoneController, Icons.phone_android),
        
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Autocomplete<Map<String, dynamic>>(
            initialValue: TextEditingValue(text: _schoolNameController.text),
            optionsBuilder: (textValue) {
              if (textValue.text.isEmpty) return const Iterable.empty();
              return _availableSchools.where((s) => s['schoolName'].toString().toLowerCase().contains(textValue.text.toLowerCase()));
            },
            displayStringForOption: (option) => option['schoolName'],
            onSelected: (selection) {
              _schoolPhoneController.text = selection['schoolPhone'] ?? '';
              _schoolNameController.text = selection['schoolName'];
              if (_autoCompleteController != null) {
                _autoCompleteController!.text = selection['schoolName'];
              }
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (_autoCompleteController != controller) {
                _autoCompleteController = controller;
              }

              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: "School Name",
                  hintText: "Search or type a new school",
                  prefixIcon: const Icon(Icons.school_outlined, color: _primaryColor),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 2)),
                ),
              );
            },
          ),
        ),

        _buildTextField("School Phone (Office)", _schoolPhoneController, Icons.phone),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 2)),
        ),
      ),
    );
  }
}