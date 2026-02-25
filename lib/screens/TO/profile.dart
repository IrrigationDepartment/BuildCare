import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- Imports ---
import 'dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kPrimaryDark = Color(0xFF312E81); // Indigo 900
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500

  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  String? _profileImageUrl;
  String? _email;
  String? _userType;
  Map<String, dynamic>? _userDataMap;

  // Image Upload Technology Variables
  XFile? _selectedImage;
  String? _selectedImageBase64;
  final ImagePicker _picker = ImagePicker();
  final String _serverUrl = 'https://buildcare.atigalle.x10.mx/'; // Updated to match your new tech

  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    if (currentUser == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userDataMap = data;
          _nameController.text = data['name'] ?? '';
          _mobileController.text = data['mobilePhone'] ?? data['mobitaphone'] ?? '';
          _profileImageUrl = data['profile_image'];
          _email = data['email'];
          _userType = data['userType'];

          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching profile: $e', Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  // --- NEW TECH: Pick Image but Don't Upload Yet ---
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          setState(() {
            _selectedImage = image;
            _selectedImageBase64 = 'data:image/jpeg;base64,$base64Image';
          });
        } else {
          setState(() {
            _selectedImage = image;
            _selectedImageBase64 = null;
          });
        }
        _showSnackBar('Image selected. Click "Save Changes" to upload.', kPrimaryColor);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Error selecting image', Colors.redAccent);
    }
  }

  // --- NEW TECH: Server Upload Logic ---
  Future<String?> _uploadImageToServer() async {
    if (_selectedImage == null) return null;
    
    try {
      final userId = currentUser?.uid;
      final email = currentUser?.email;
      
      if (userId == null) return null;
      
      List<int> imageBytes;
      if (kIsWeb) {
        if (_selectedImageBase64 != null) {
          imageBytes = base64Decode(_selectedImageBase64!.split(',').last);
        } else {
          imageBytes = await _selectedImage!.readAsBytes();
        }
      } else {
        imageBytes = await _selectedImage!.readAsBytes();
      }
      
      var request = http.MultipartRequest('POST', Uri.parse(_serverUrl));
      
      request.files.add(http.MultipartFile.fromBytes(
        'profile_image',
        imageBytes,
        filename: 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      
      request.fields['user_id'] = userId;
      request.fields['email'] = email ?? '';
      request.fields['action'] = 'upload_profile_image';
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        try {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse['success'] == true || jsonResponse['status'] == 'success') {
            return jsonResponse['image_url'] ?? jsonResponse['url'] ?? jsonResponse['file_url'];
          } else if (jsonResponse['image_url'] != null) {
            return jsonResponse['image_url'];
          }
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error in _uploadImageToServer: $e');
      return null;
    }
  }

  // --- MERGED LOGIC: Save Data & Upload Image Together ---
  Future<void> _updateProfileData() async {
    if (!_formKey.currentState!.validate()) return;
    if (currentUser == null) return;

    setState(() => _isUpdating = true);

    try {
      String? finalImageUrl = _profileImageUrl;
      bool imageUploaded = false;

      // 1. Upload image first if one was selected
      if (_selectedImage != null) {
        _showSnackBar('Uploading image...', kPrimaryColor);
        finalImageUrl = await _uploadImageToServer();
        
        if (finalImageUrl != null) {
          imageUploaded = true;
        } else {
          _showSnackBar('Failed to upload image to server.', Colors.orange);
          finalImageUrl = _profileImageUrl; // Fallback to old image
        }
      }

      // 2. Prepare Firestore update data
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'mobilePhone': _mobileController.text.trim(),
        'LastUpdated': Timestamp.now(),
      };

      if (imageUploaded && finalImageUrl != null) {
        updateData['profile_image'] = finalImageUrl;
      }

      // 3. Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update(updateData);

      // 4. Update local map & state
      setState(() {
        if (_userDataMap != null) {
          _userDataMap!['name'] = _nameController.text.trim();
          _userDataMap!['mobilePhone'] = _mobileController.text.trim();
          if (imageUploaded) {
            _userDataMap!['profile_image'] = finalImageUrl;
          }
        }
        if (imageUploaded) {
          _profileImageUrl = finalImageUrl;
          _selectedImage = null; // Clear preview
          _selectedImageBase64 = null;
        }
      });

      _showSnackBar('Profile updated successfully!', Colors.green);

    } catch (e) {
      _showSnackBar('Error updating profile: $e', Colors.redAccent);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryColor),
          onPressed: () {
            if (_userDataMap != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => TODashboard(userData: _userDataMap!)),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('Edit Profile',
            style: TextStyle(color: kTextColor, fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileImage(),
                        
                        // Show a helpful indicator if an image is waiting to be saved
                        if (_selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    'New image selected',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),
                        
                        // Input Fields
                        _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline_rounded),
                        
                        _buildReadOnlyField(
                            label: 'Job Title / Role', 
                            value: _userType ?? 'N/A',
                            icon: Icons.badge_outlined),
                        
                        _buildReadOnlyField(
                            label: 'Work Email Address', 
                            value: _email ?? 'N/A',
                            icon: Icons.email_outlined),
                            
                        _buildTextField(
                            controller: _mobileController,
                            label: 'Mobile Phone',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone),
                            
                        const SizedBox(height: 40),
                        
                        // Update Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ]
                          ),
                          child: ElevatedButton(
                            onPressed: _isUpdating ? null : _updateProfileData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: kPrimaryColor.withOpacity(0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isUpdating
                                ? const SizedBox(
                                    width: 24, 
                                    height: 24, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                  )
                                : const Text('Save Changes',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // --- UPDATED: Avatar Preview with Base64/File support ---
  Widget _buildProfileImage() {
    // Determine which image provider to use
    ImageProvider? imageProvider;
    
    if (_selectedImage != null) {
      if (kIsWeb && _selectedImageBase64 != null) {
        imageProvider = MemoryImage(base64Decode(_selectedImageBase64!.split(',').last));
      } else if (!kIsWeb) {
        imageProvider = FileImage(File(_selectedImage!.path));
      }
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 3),
                image: imageProvider != null 
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: imageProvider == null
                  ? const Icon(Icons.person_rounded, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isUpdating ? null : _pickImage, // Changed to _pickImage
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kPrimaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryDark.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODERN TEXT FIELD ---
  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03), 
                blurRadius: 15, 
                offset: const Offset(0, 5))
          ]),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600, color: kTextColor),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: kSubTextColor, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: kCardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
      ),
    );
  }

  // --- MODERN READ-ONLY FIELD ---
  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kSubTextColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(label, style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: kTextColor, fontSize: 16, fontWeight: FontWeight.w600)),
              ]
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
          )
        ],
      ),
    );
  }
}