// profile_management.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileManagementPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const ProfileManagementPage({super.key, this.userData});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobilePhoneController;
  late TextEditingController _officeController;
  late TextEditingController _officePhoneController;
  late TextEditingController _nicController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  String? _profileImageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _profileImageUrl = widget.userData?['profile_image'];
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _mobilePhoneController = TextEditingController(text: widget.userData?['mobilePhone'] ?? '');
    _officeController = TextEditingController(text: widget.userData?['office'] ?? '');
    _officePhoneController = TextEditingController(text: widget.userData?['officePhone'] ?? '');
    _nicController = TextEditingController(text: widget.userData?['nic'] ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _profileImageUrl;
    
    try {
      final userId = _auth.currentUser?.uid ?? widget.userData?['id'];
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_validateFields()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid ?? widget.userData?['id'];
      
      // Upload image if selected
      String? imageUrl = await _uploadImage();
      
      // Prepare update data
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'mobilePhone': _mobilePhoneController.text.trim(),
        'office': _officeController.text.trim(),
        'officePhone': _officePhoneController.text.trim(),
        'nic': _nicController.text.trim(),
        'LastUpdated': Timestamp.now(),
      };
      
      if (imageUrl != null) {
        updateData['profile_image'] = imageUrl;
      }

      // Update in Firestore
      await _firestore.collection('users').doc(userId).update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'))
      );
      
      // Return updated data
      Navigator.pop(context, updateData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match!'))
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters!'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Re-authenticate user
        final cred = EmailAuthProvider.credential(
          email: _emailController.text,
          password: _currentPasswordController.text,
        );
        
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newPasswordController.text);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'))
        );
        
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _showPasswordFields = false);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error changing password';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateFields() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required!'))
      );
      return false;
    }
    if (_mobilePhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile phone is required!'))
      );
      return false;
    }
    return true;
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null) as ImageProvider?,
            child: _selectedImage == null && _profileImageUrl == null
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profile'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildProfileImage(),
            const SizedBox(height: 20),
            Text(
              'Edit your profile information',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            
            // Personal Information
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Full Name',
                      controller: _nameController,
                      prefixIcon: Icons.person,
                    ),
                    _buildInputField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      prefixIcon: Icons.email,
                    ),
                    _buildInputField(
                      label: 'NIC',
                      controller: _nicController,
                      prefixIcon: Icons.badge,
                    ),
                    _buildInputField(
                      label: 'Mobile Phone',
                      controller: _mobilePhoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Office Information
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Office Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Office',
                      controller: _officeController,
                      prefixIcon: Icons.business,
                    ),
                    _buildInputField(
                      label: 'Office Phone',
                      controller: _officePhoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Change Password Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showPasswordFields ? Icons.expand_less : Icons.expand_more,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPasswordFields = !_showPasswordFields;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    if (_showPasswordFields) ...[
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Current Password',
                        controller: _currentPasswordController,
                        prefixIcon: Icons.lock,
                      ),
                      _buildInputField(
                        label: 'New Password',
                        controller: _newPasswordController,
                        prefixIcon: Icons.lock_outline,
                      ),
                      _buildInputField(
                        label: 'Confirm New Password',
                        controller: _confirmPasswordController,
                        prefixIcon: Icons.lock_reset,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Change Password'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Update Profile Button
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Update Profile',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
            
            const SizedBox(height: 20),
          ],
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
    _nicController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}