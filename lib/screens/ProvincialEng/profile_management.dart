import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import the dashboard to use the CustomBottomNavBar
import 'dashboard.dart' as dashboard;
import 'app_settings.dart'; // Ensure Settings is imported

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

  final String _serverUrl = 'http://98.94.30.13/';

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
        _showSnackBar('Image selected. Click "Save Changes" to upload.', Colors.blue);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Error selecting image', Colors.red);
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
      request.fields['email'] = email;
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
      debugPrint('Error in uploadImageToServer: $e');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_userId == null) {
      _showSnackBar('User not found', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _profileImageUrl;
      bool imageUploaded = false;
      
      if (_selectedImage != null) {
        _showSnackBar('Uploading image...', Colors.blue);
        
        imageUrl = await _uploadImageToServer();
        if (imageUrl != null) {
          _showSnackBar('Image uploaded successfully!', Colors.green);
          imageUploaded = true;
        } else {
          _showSnackBar('Failed to upload image', Colors.orange);
          imageUrl = _profileImageUrl;
        }
      }
      
      Map<String, dynamic> updateData = {
        'LastUpdated': Timestamp.now(),
      };
      
      if (_nameController.text.trim().isNotEmpty) {
        updateData['name'] = _nameController.text.trim();
      }
      
      if (_mobilePhoneController.text.trim().isNotEmpty) {
        updateData['mobilePhone'] = _mobilePhoneController.text.trim();
        updateData['mobitaphone'] = _mobilePhoneController.text.trim();
      }
      
      if (_officePhoneController.text.trim().isNotEmpty) {
        updateData['officePhone'] = _officePhoneController.text.trim();
      }
      
      if (imageUrl != null && imageUrl.isNotEmpty && imageUploaded) {
        updateData['profile_image'] = imageUrl;
      }

      if (updateData.length > 1 || (imageUploaded && imageUrl != null)) {
        await _firestore.collection('users').doc(_userId).update(updateData);
        
        if (imageUploaded && imageUrl != null) {
          setState(() {
            _profileImageUrl = imageUrl;
            _selectedImage = null;
            _selectedImageBase64 = null;
          });
        }

        _showSnackBar('Profile updated successfully!', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
      } else {
        _showSnackBar('No changes to save', Colors.blue);
      }
      
    } catch (e) {
      debugPrint('Error in updateProfile: $e');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      )
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade600,
              Colors.purple.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              width: 126,
              height: 126,
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: _buildImagePreview(),
              ),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade700,
                      Colors.purple.shade700,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      if (kIsWeb && _selectedImageBase64 != null) {
        return Image.memory(
          base64Decode(_selectedImageBase64!.split(',').last),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      } else if (!kIsWeb) {
        return Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      }
    }
    
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
              color: Colors.blue,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }
    
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade100,
            Colors.purple.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              readOnly: readOnly,
              style: TextStyle(
                fontSize: 16,
                color: readOnly ? Colors.grey.shade600 : Colors.black,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blue.shade600,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: prefixIcon != null
                    ? Icon(
                        prefixIcon,
                        color: Colors.grey.shade600,
                        size: 22,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.shade100,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
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
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoItem('Email', _emailController.text),
              if (_officeController.text.isNotEmpty)
                _buildInfoItem('Office', _officeController.text),
              const SizedBox(height: 40),
              Text(
                'Update Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInputField(
                      label: 'Full Name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                      hintText: 'Enter your full name',
                    ),
                    _buildInputField(
                      label: 'Mobile Phone',
                      controller: _mobilePhoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_iphone_rounded,
                      hintText: 'Enter mobile number',
                    ),
                    _buildInputField(
                      label: 'Office Phone',
                      controller: _officePhoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_rounded,
                      hintText: 'Enter office number (optional)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade600,
                      Colors.purple.shade600,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _updateProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading)
                            const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else ...[
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const dashboard.CustomBottomNavBar(currentIndex: 1),
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