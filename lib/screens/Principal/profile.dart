import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'settings_page.dart';
import 'dashboard.dart';
import '../../login.dart';

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

  // --- School suggestions data ---
  List<Map<String, dynamic>> _availableSchools = [];
  bool _isLoadingSchools = true;

  // --- 6-Month Editing Lock Variables ---
  bool _isSchoolEditable = true;
  DateTime? _nextSchoolEditDate;
  String _originalSchoolName = '';

  // Updated Theme Color to Blue Accent
  static const Color _primaryColor = Colors.blueAccent;

  // Controllers & FocusNodes
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolPhoneController;
  final FocusNode _schoolNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.userData['profile_image'];
    _originalSchoolName = widget.userData['schoolName'] ?? '';

    _nameController =
        TextEditingController(text: widget.userData['name'] ?? '');
    _phoneController = TextEditingController(
      text: widget.userData['mobilePhone'] ?? widget.userData['phone'] ?? '',
    );
    _schoolNameController =
        TextEditingController(text: _originalSchoolName);
    _schoolPhoneController =
        TextEditingController(text: widget.userData['officePhone'] ?? '');

    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchLatestUserData(),
      _fetchSchoolsForAutocomplete(),
    ]);
    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _schoolNameController.dispose();
    _schoolPhoneController.dispose();
    _schoolNameFocusNode.dispose();
    super.dispose();
  }

  // --- DATABASE FETCHING ---
  Future<void> _fetchLatestUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) {
        Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>;

        setState(() {
          _profileImageUrl = userData['profile_image'];
          _nameController.text = userData['name'] ?? '';
          _phoneController.text =
              userData['mobilePhone'] ?? userData['phone'] ?? '';
          
          _originalSchoolName = userData['schoolName'] ?? '';
          _schoolNameController.text = _originalSchoolName;
          _schoolPhoneController.text = userData['officePhone'] ?? '';

          // Check if 6 months have passed since the last edit
          if (userData.containsKey('schoolNameLastEditedAt') && 
              userData['schoolNameLastEditedAt'] != null) {
            
            final DateTime lastEdited = (userData['schoolNameLastEditedAt'] as Timestamp).toDate();
            final DateTime now = DateTime.now();
            final int daysSinceEdit = now.difference(lastEdited).inDays;

            if (daysSinceEdit < 180) {
              _isSchoolEditable = false;
              _nextSchoolEditDate = lastEdited.add(const Duration(days: 180));
            } else {
              _isSchoolEditable = true;
              _nextSchoolEditDate = null;
            }
          } else {
            // If it has never been edited, allow it
            _isSchoolEditable = true;
            _nextSchoolEditDate = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  // --- Fetch school list for autocomplete ---
  Future<void> _fetchSchoolsForAutocomplete() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .orderBy('schoolName')
          .get();

      final schools = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'schoolName': (data['schoolName'] ?? '').toString().trim(),
          'educationalZone': (data['educationalZone'] ?? '').toString(),
        };
      }).where((school) => (school['schoolName'] as String).isNotEmpty).toList();

      if (mounted) {
        setState(() {
          _availableSchools = schools;
          _isLoadingSchools = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching schools: $e");
      if (mounted) {
        setState(() => _isLoadingSchools = false);
      }
    }
  }

  // --- IMAGE UPLOAD LOGIC ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://98.94.30.13/index.php'),
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

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .set({
            'profile_image': newImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          setState(() => _profileImageUrl = newImageUrl);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile Photo Updated!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  // --- PROFILE DATA UPDATE ---
  Future<void> _updateProfileData() async {
    String currentSchoolName = _schoolNameController.text.trim();

    if (_nameController.text.trim().isEmpty || currentSchoolName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Required fields are empty.")),
      );
      return;
    }

    setState(() => _isUpdatingData = true);

    try {
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'mobilePhone': _phoneController.text.trim(),
        'schoolName': currentSchoolName,
        'officePhone': _schoolPhoneController.text.trim(),
        'profile_image': _profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only lock the school name if they actually changed it
      if (_isSchoolEditable && currentSchoolName != _originalSchoolName) {
        updateData['schoolNameLastEditedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set(updateData, SetOptions(merge: true));

      await _fetchLatestUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingData = false);
      }
    }
  }

  // --- LOGOUT LOGIC ---
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey[100],
              backgroundImage: (_profileImageUrl != null &&
                      _profileImageUrl!.isNotEmpty)
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 70, color: Colors.grey)
                  : null,
            ),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: _isUpdatingData
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SAVE CHANGES",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          side: BorderSide(color: Colors.red.shade600, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded),
            SizedBox(width: 8),
            Text(
              "LOGOUT",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PERSONAL DETAILS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField("Full Name", _nameController, Icons.person_outline),
        _buildTextField("Mobile Number", _phoneController, Icons.phone_android),
        const SizedBox(height: 12),
        const Text(
          "SCHOOL DETAILS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        
        // --- 6-Month Warning Banner ---
        if (!_isSchoolEditable)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_clock, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "School Name editing is locked for 6 months.\nNext edit: ${_nextSchoolEditDate != null ? DateFormat.yMMMMd().format(_nextSchoolEditDate!) : 'N/A'}",
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Swap between editable Autocomplete and locked text fields dynamically
        _isSchoolEditable 
            ? _buildSchoolNameAutocompleteField()
            : _buildLockedTextField(
                "School Name",
                _schoolNameController,
                Icons.school_outlined,
              ),

        _buildTextField(
          "Office Phone",
          _schoolPhoneController,
          Icons.business_outlined,
        ),
      ],
    );
  }

  // --- New Autocomplete Field ---
  Widget _buildSchoolNameAutocompleteField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RawAutocomplete<Map<String, dynamic>>(
        textEditingController: _schoolNameController,
        focusNode: _schoolNameFocusNode,
        displayStringForOption: (option) => option['schoolName']?.toString() ?? '',
        optionsBuilder: (TextEditingValue textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();

          if (query.isEmpty) {
            return const Iterable<Map<String, dynamic>>.empty();
          }

          return _availableSchools.where((school) {
            final name = school['schoolName']?.toString().toLowerCase() ?? '';
            return name.contains(query);
          }).take(8);
        },
        onSelected: (option) {
          setState(() {
            _schoolNameController.text = option['schoolName']?.toString() ?? '';
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: "School Name",
              prefixIcon: const Icon(Icons.school_outlined, color: _primaryColor),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primaryColor, width: 1.5),
              ),
              suffixIcon: _isLoadingSchools
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            controller.clear();
                            setState(() {});
                          },
                        )
                      : null,
            ),
            onChanged: (_) {
              setState(() {});
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: MediaQuery.of(context).size.width - 48,
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    final name = option['schoolName']?.toString() ?? '';
                    final zone = option['educationalZone']?.toString() ?? '';

                    return ListTile(
                      leading: const Icon(
                        Icons.school_outlined,
                        color: _primaryColor,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: zone.isNotEmpty ? Text(zone) : null,
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SYSTEM RECORDS (LOCKED)",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _buildLockedCard(
          "Email",
          widget.userData['email'] ?? 'N/A',
          Icons.alternate_email,
        ),
        _buildLockedCard(
          "NIC Number",
          widget.userData['nic'] ?? 'N/A',
          Icons.badge_outlined,
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    FocusNode? focusNode,
  }) {
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        enableInteractiveSelection: false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor),
          suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w500,
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
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}