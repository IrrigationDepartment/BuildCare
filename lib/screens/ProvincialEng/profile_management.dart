import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// Dashboard එකේ ඇති CustomBottomNavBar එක භාවිතා කිරීමට මෙය අවශ්‍ය වේ
import 'dashboard.dart'; 

class ProfileManagementPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const ProfileManagementPage({super.key, this.userData});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobilePhoneController;
  late TextEditingController _officeController;
  late TextEditingController _officePhoneController;

  String? _profileImageUrl;
  XFile? _selectedImage;
  String? _selectedImageBase64;
  bool _isLoading = false;
  String? _userId;

  final String _serverUrl = 'https://buildcare.atigalle.x10.mx/';

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    _nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _mobilePhoneController = TextEditingController(text: widget.userData?['mobilePhone'] ?? '');
    _officeController = TextEditingController(text: widget.userData?['office'] ?? '');
    _officePhoneController = TextEditingController(text: widget.userData?['officePhone'] ?? '');
    _profileImageUrl = widget.userData?['profileImageUrl'];
  }

  // --- Image Picking and Upload Logic (පැරණි කේතය එලෙසම පවතී) ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      final bytes = await image.readAsBytes();
      _selectedImageBase64 = base64Encode(bytes);
    }
  }

  Future<void> _updateProfile() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _profileImageUrl;

      if (_selectedImageBase64 != null) {
        final response = await http.post(
          Uri.parse('${_serverUrl}upload_profile.php'),
          body: {
            'image': _selectedImageBase64,
            'uid': _userId,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success']) {
            finalImageUrl = data['url'];
          }
        }
      }

      await _firestore.collection('users').doc(_userId).update({
        'name': _nameController.text,
        'mobilePhone': _mobilePhoneController.text,
        'office': _officeController.text,
        'officePhone': _officePhoneController.text,
        'profileImageUrl': finalImageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Profile Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundImage: _selectedImage != null
                            ? FileImage(File(_selectedImage!.path))
                            : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
                        child: (_selectedImage == null && _profileImageUrl == null) ? const Icon(Icons.person, size: 50) : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                  _buildTextField(_emailController, 'Email Address', Icons.email_outlined, enabled: false),
                  _buildTextField(_mobilePhoneController, 'Mobile Phone', Icons.phone_android_outlined),
                  _buildTextField(_officeController, 'Office', Icons.business_outlined),
                  _buildTextField(_officePhoneController, 'Office Phone', Icons.phone_outlined),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- මෙන්න මෙතනට Bottom Navigation එක එකතු කළා ---
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade800),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobilePhoneController.dispose();
    _officeController.dispose();
    _officePhoneController.dispose();
    super.dispose();
  }
}