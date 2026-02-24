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

  static const Color _primaryColor = Color(0xFF53BDFF);

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolPhoneController;
  
  TextEditingController? _autoCompleteController; 

  @override
  void initState() {
    super.initState();
    // Initialize image from the passed userData
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

  // --- IMAGE UPLOAD LOGIC ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://buildcare.atigalle.x10.mx/index.php') 
      );
      
      final bytes = await pickedFile.readAsBytes();
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_image', 
          bytes,
          filename: 'upload.jpg',
        ),
      );
      
      request.fields['userId'] = widget.userId; 

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          String newImageUrl = jsonResponse['profileImageUrl'];

          // FIXED: ONLY update the current user's document.
          DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
          await userRef.set({
            'profile_image': newImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          setState(() {
            _profileImageUrl = newImageUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Photo Updated!"), backgroundColor: Colors.green));
          }
        } else {
           throw Exception(jsonResponse['message'] ?? "Server reported failure");
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Image upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // --- DATA UPDATE LOGIC ---
  Future<void> _updateProfileData() async {
    String typedSchoolName = (_autoCompleteController?.text ?? _schoolNameController.text).trim();

    if (_nameController.text.trim().isEmpty || typedSchoolName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Required fields are empty.")));
      return;
    }

    setState(() => _isUpdatingData = true);

    try {
      String typedSchoolPhone = _schoolPhoneController.text.trim();

      // FIXED: ONLY update the current user's document.
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      
      await userRef.set({
        'name': _nameController.text.trim(),
        'mobilePhone': _phoneController.text.trim(),
        'schoolName': typedSchoolName,
        'officePhone': typedSchoolPhone,
        'profile_image': _profileImageUrl, // Ensure latest URL is saved
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _fetchLatestUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Update error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUpdatingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator()) 
        : SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine layout based on width
                bool isWideScreen = constraints.maxWidth > 800;

                if (isWideScreen) {
                  // --- DESKTOP / TABLET LAYOUT ---
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Image & System Info)
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _buildProfileImage(),
                                  const SizedBox(height: 32),
                                  _buildSystemInfoSection(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                            // Right Column (Editable Form)
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildEditableSection(),
                                  const SizedBox(height: 40),
                                  _buildSaveButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // --- MOBILE LAYOUT ---
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildProfileImage(),
                        const SizedBox(height: 32),
                        _buildEditableSection(),
                        const SizedBox(height: 24),
                        _buildSystemInfoSection(),
                        const SizedBox(height: 40),
                        _buildSaveButton(),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
    );
  }

  // Extracted Widgets for cleaner LayoutBuilder
  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey[100],
              backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) 
                  ? NetworkImage(_profileImageUrl!) 
                  : null,
              child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 70, color: Colors.grey)
                  : null,
            ),
          ),
          if (_isUploadingImage)
            const Positioned.fill(child: CircularProgressIndicator(strokeWidth: 4)),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndUploadImage,
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: _primaryColor,
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isUpdatingData ? null : _updateProfileData,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _isUpdatingData 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildEditableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PERSONAL DETAILS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.1)),
        const SizedBox(height: 16),
        _buildTextField("Full Name", _nameController, Icons.person_outline),
        _buildTextField("Mobile Number", _phoneController, Icons.phone_android),
        
        const SizedBox(height: 12),
        const Text("SCHOOL DETAILS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.1)),
        const SizedBox(height: 16),
        
        // Autocomplete
        Autocomplete<Map<String, dynamic>>(
          initialValue: TextEditingValue(text: _schoolNameController.text),
          optionsBuilder: (textValue) => _availableSchools.where((s) => s['schoolName'].toString().toLowerCase().contains(textValue.text.toLowerCase())),
          displayStringForOption: (option) => option['schoolName'],
          onSelected: (selection) {
            _schoolPhoneController.text = selection['schoolPhone'] ?? '';
            _schoolNameController.text = selection['schoolName'];
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _autoCompleteController = controller;
            return _buildTextField("School Name", controller, Icons.school_outlined, focusNode: focusNode);
          },
        ),
        _buildTextField("Office Phone", _schoolPhoneController, Icons.business_outlined),
      ],
    );
  }

  Widget _buildSystemInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SYSTEM RECORDS (LOCKED)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        _buildLockedCard("Email", widget.userData['email'] ?? 'N/A', Icons.alternate_email),
        _buildLockedCard("NIC Number", widget.userData['nic'] ?? 'N/A', Icons.badge_outlined),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {FocusNode? focusNode}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
      ),
    );
  }

  Widget _buildLockedCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
