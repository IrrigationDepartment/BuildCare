// profile_management.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  String? _profileImageUrl;
  XFile? _selectedImage;
  String? _selectedImageBase64;
  bool _isLoading = false;
  bool _showPasswordFields = false;
  String? _userId;

  // Your server endpoint for image upload - use the correct endpoint
     final String _serverUrl = 'https://buildcare.atigalle.x10.mx/';
  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    _initializeControllers();
    _profileImageUrl = widget.userData?['profile_image'];
    _loadUserData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _mobilePhoneController = TextEditingController(text: widget.userData?['mobilePhone'] ?? widget.userData?['mobitaphone'] ?? '');
    _officeController = TextEditingController(text: widget.userData?['office'] ?? '');
    _officePhoneController = TextEditingController(text: widget.userData?['officePhone'] ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _nameController.text = data?['name'] ?? '';
          _emailController.text = data?['email'] ?? '';
          _mobilePhoneController.text = data?['mobilePhone'] ?? data?['mobitaphone'] ?? '';
          _officeController.text = data?['office'] ?? '';
          _officePhoneController.text = data?['officePhone'] ?? '';
          _profileImageUrl = data?['profile_image'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Lower quality for faster upload
        maxWidth: 800, // Limit size
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
        _showInfoSnackBar('Image selected. Click "Save Changes" to upload.');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Error selecting image: ${e.toString()}');
    }
  }

  Future<String?> _uploadImageToServer() async {
    if (_selectedImage == null) {
      debugPrint('No image selected for upload');
      return null;
    }
    
    try {
      final userId = _userId ?? widget.userData?['id'];
      final email = _auth.currentUser?.email ?? widget.userData?['email'];
      
      if (userId == null) {
        debugPrint('User ID is null');
        return null;
      }
      
      debugPrint('=== Starting image upload ===');
      debugPrint('User ID: $userId');
      debugPrint('Email: $email');
      debugPrint('Server URL: $_serverUrl');
      
      // Read image bytes
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
      
      debugPrint('Image size: ${imageBytes.length} bytes');
      
      // Create multipart request (this is often better for file uploads)
      var request = http.MultipartRequest('POST', Uri.parse(_serverUrl));
      
      // Add image as file
      request.files.add(http.MultipartFile.fromBytes(
        'profile_image', // Field name that server expects
        imageBytes,
        filename: 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      
      // Add other fields
      request.fields['user_id'] = userId;
      request.fields['email'] = email;
      request.fields['action'] = 'upload_profile_image';
      
      // Send request
      debugPrint('Sending multipart request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        debugPrint('Upload successful!');
        
        // Try to parse response
        try {
          var jsonResponse = jsonDecode(response.body);
          debugPrint('Parsed JSON response: $jsonResponse');
          
          // Check different possible response formats
          if (jsonResponse['success'] == true || jsonResponse['status'] == 'success') {
            String? imageUrl = jsonResponse['image_url'] ?? jsonResponse['url'] ?? jsonResponse['file_url'];
            debugPrint('Got image URL: $imageUrl');
            return imageUrl;
          } else if (jsonResponse['image_url'] != null) {
            debugPrint('Got image URL from image_url field: ${jsonResponse['image_url']}');
            return jsonResponse['image_url'];
          }
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
          // Maybe the server returns just the URL as plain text
          if (response.body.trim().startsWith('http')) {
            debugPrint('Got URL as plain text: ${response.body.trim()}');
            return response.body.trim();
          }
          // Check if response contains any URL
          RegExp urlRegex = RegExp('r''https?://[^\s"\'<>]+');
          var match = urlRegex.firstMatch(response.body);
          if (match != null) {
            debugPrint('Found URL in response: ${match.group(0)}');
            return match.group(0);
          }
        }
      } else {
        debugPrint('Upload failed with status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
      
      return null;
    } catch (e) {
      debugPrint('Error in uploadImageToServer: $e');
      debugPrint('Stack trace: ${e.toString()}');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_userId == null) {
      _showErrorSnackBar('User not found');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _profileImageUrl;
      bool imageUploaded = false;
      
      // Upload image to server if selected
      if (_selectedImage != null) {
        debugPrint('Attempting to upload image...');
        _showInfoSnackBar('Uploading image...');
        
        imageUrl = await _uploadImageToServer();
        if (imageUrl != null) {
          _showSuccessSnackBar('Image uploaded successfully!');
          imageUploaded = true;
        } else {
          _showErrorSnackBar('Failed to upload image. Keeping existing image.');
          imageUrl = _profileImageUrl;
        }
      }
      
      // Prepare update data
      Map<String, dynamic> updateData = {
        'LastUpdated': Timestamp.now(),
      };
      
      // Update name if changed
      if (_nameController.text.trim().isNotEmpty) {
        updateData['name'] = _nameController.text.trim();
      }
      
      // Update mobile phone
      if (_mobilePhoneController.text.trim().isNotEmpty) {
        updateData['mobilePhone'] = _mobilePhoneController.text.trim();
        updateData['mobitaphone'] = _mobilePhoneController.text.trim();
      }
      
      // Update office phone if provided
      if (_officePhoneController.text.trim().isNotEmpty) {
        updateData['officePhone'] = _officePhoneController.text.trim();
      }
      
      // Update image URL if new image uploaded
      if (imageUrl != null && imageUrl.isNotEmpty && imageUploaded) {
        updateData['profile_image'] = imageUrl;
      }

      // Only update if there are changes
      if (updateData.length > 1 || (imageUploaded && imageUrl != null)) {
        debugPrint('Updating Firestore with: $updateData');
        await _firestore.collection('users').doc(_userId).update(updateData);
        
        // Update local state
        if (imageUploaded && imageUrl != null) {
          setState(() {
            _profileImageUrl = imageUrl;
            _selectedImage = null;
            _selectedImageBase64 = null;
          });
        }

        _showSuccessSnackBar('Profile updated successfully!');
        // Delay navigation to show success message
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, updateData);
      } else {
        _showInfoSnackBar('No changes to save');
      }
      
    } catch (e) {
      debugPrint('Error in updateProfile: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('New passwords do not match!');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final cred = EmailAuthProvider.credential(
          email: _emailController.text,
          password: _currentPasswordController.text,
        );
        
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newPasswordController.text);
        
        _showSuccessSnackBar('Password changed successfully!');
        
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
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      )
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      )
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      )
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue.shade100,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _buildImagePreview(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // Show newly selected image
    if (_selectedImage != null) {
      if (kIsWeb && _selectedImageBase64 != null) {
        return Image.memory(
          base64Decode(_selectedImageBase64!.split(',').last),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      } else if (!kIsWeb) {
        return Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      }
    }
    
    // Show existing profile image
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    }
    
    // Default avatar
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.blue.shade50,
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool obscureText = false,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey.shade600)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile Management'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_selectedImage != null)
                      Text(
                        'New image selected',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Read-only Information Section
              _buildSection('Account Information'),
              _buildInfoCard('Email', _emailController.text),
              
              if (_officeController.text.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoCard('Office', _officeController.text),
                  ],
                ),
              
              const SizedBox(height: 24),
              
              // Editable Information Section
              _buildSection('Update Your Information'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInputField(
                        label: 'Full Name',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline,
                        hintText: 'Enter your name',
                      ),
                      _buildInputField(
                        label: 'Mobile Phone',
                        controller: _mobilePhoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_outlined,
                        hintText: 'Enter your mobile number',
                      ),
                      _buildInputField(
                        label: 'Office Phone',
                        controller: _officePhoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        hintText: 'Optional',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Change Password Section
              _buildSection('Security'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _showPasswordFields
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.blue.shade700,
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
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                        ),
                        _buildInputField(
                          label: 'New Password',
                          controller: _newPasswordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_reset,
                        ),
                        _buildInputField(
                          label: 'Confirm New Password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_reset,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Update Password',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Update Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}