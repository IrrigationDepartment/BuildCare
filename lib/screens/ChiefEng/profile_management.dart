import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dashboard.dart' as dashboard;
import '../../login.dart';

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
    _nameController =
        TextEditingController(text: widget.userData?['name'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData?['email'] ?? '');
    _mobilePhoneController = TextEditingController(
      text: widget.userData?['mobilePhone'] ??
          widget.userData?['mobitaphone'] ??
          '',
    );
    _officeController =
        TextEditingController(text: widget.userData?['office'] ?? '');
    _officePhoneController =
        TextEditingController(text: widget.userData?['officePhone'] ?? '');
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
          _mobilePhoneController.text =
              data?['mobilePhone'] ?? data?['mobitaphone'] ?? '';
          _officeController.text = data?['office'] ?? '';
          _officePhoneController.text = data?['officePhone'] ?? '';

          if (data?['profile_image'] != null &&
              data!['profile_image'].toString().isNotEmpty) {
            _profileImageUrl = data['profile_image'];
          }
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
        _showSnackBar('Image selected. Tap save to upload.', Colors.blue);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Error selecting image', Colors.red);
    }
  }

  Future<String?> _uploadImageToServer() async {
    if (_selectedImage == null) return null;

    try {
      final userId = _userId ?? widget.userData?['id'];
      final email = _auth.currentUser?.email ?? widget.userData?['email'];

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

      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_image',
          imageBytes,
          filename: 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      request.fields['user_id'] = userId;
      request.fields['email'] = email ?? '';
      request.fields['action'] = 'upload_profile_image';
      request.fields['upload_type'] = 'chiefe';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse['success'] == true ||
              jsonResponse['status'] == 'success') {
            return jsonResponse['image_url'] ??
                jsonResponse['url'] ??
                jsonResponse['profileImageUrl'] ??
                jsonResponse['file_url'];
          } else if (jsonResponse['image_url'] != null) {
            return jsonResponse['image_url'];
          }
        } catch (e) {
          debugPrint('Error parsing JSON: $e | Body: ${response.body}');
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
          imageUploaded = true;
        } else {
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

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      _showSnackBar('Error logging out: $e', Colors.red);
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      if (kIsWeb && _selectedImageBase64 != null) {
        return Image.memory(
          base64Decode(_selectedImageBase64!.split(',').last),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
        );
      } else if (!kIsWeb) {
        return Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
        );
      }
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
      );
    }

    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person_rounded, size: 56, color: Colors.white),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: ClipOval(child: _buildImagePreview()),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.trim().isEmpty
                ? 'Your Profile'
                : _nameController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _emailController.text.isEmpty
                ? 'Manage your personal information'
                : _emailController.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildHeaderBadge(
                icon: Icons.edit_rounded,
                text: 'Tap photo to change',
              ),
              if (_selectedImage != null)
                _buildHeaderBadge(
                  icon: Icons.check_circle_rounded,
                  text: 'New image selected',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: readOnly ? Colors.grey.shade700 : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon, size: 20),
              filled: true,
              fillColor:
                  readOnly ? const Color(0xFFF9FAFB) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded),
                  SizedBox(width: 10),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _confirmLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          side: BorderSide(color: Colors.red.shade200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: 'Account Information',
          subtitle: 'Your basic account details',
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: _emailController.text,
              ),
              if (_officeController.text.isNotEmpty)
                _buildInfoTile(
                  icon: Icons.business_outlined,
                  title: 'Office',
                  value: _officeController.text,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          icon: Icons.edit_note_rounded,
          child: Column(
            children: [
              _buildModernField(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
                hintText: 'Enter your full name',
              ),
              _buildModernField(
                label: 'Email Address',
                controller: _emailController,
                icon: Icons.email_outlined,
                readOnly: true,
                hintText: 'Email address',
              ),
              _buildModernField(
                label: 'Mobile Phone',
                controller: _mobilePhoneController,
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                hintText: 'Enter mobile number',
              ),
              _buildModernField(
                label: 'Office Phone',
                controller: _officePhoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hintText: 'Enter office number',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(),
        const SizedBox(height: 12),
        _buildLogoutButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _buildLeftPanel()),
                            const SizedBox(width: 22),
                            Expanded(flex: 5, child: _buildRightPanel()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildLeftPanel(),
                            const SizedBox(height: 20),
                            _buildRightPanel(),
                            const SizedBox(height: 20),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar:
          const dashboard.CustomBottomNavBar(currentIndex: 1),
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