import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// --- IMPORT YOUR FORGOT PASSWORD SCREEN HERE ---
import '/screens/forgot_password_flow.dart';
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
  // Controllers
  late TextEditingController _principalNameController;
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolTypeController;
  late TextEditingController _titleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _officePhoneController;
  late TextEditingController _nicController;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _profileImageUrl;

  static const Color _primaryColor = Color(0xFF53BDFF);

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.userData['profile_image'];
    _fetchLatestUserData();

    _principalNameController = TextEditingController(
        text: widget.userData['name'] ?? widget.userData['principalName'] ?? '');
    
    // Initialized for the Autocomplete logic
    _schoolNameController =
        TextEditingController(text: widget.userData['schoolName'] ?? '');

    _schoolTypeController =
        TextEditingController(text: widget.userData['schoolType'] ?? '');
    _titleController =
        TextEditingController(text: widget.userData['userType'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.userData['phone'] ?? '');
    _mobileController = TextEditingController(
        text: widget.userData['mobile'] ?? widget.userData['mobilePhone'] ?? '');
    _officePhoneController =
        TextEditingController(text: widget.userData['officePhone'] ?? '');
    _nicController = TextEditingController(text: widget.userData['nic'] ?? '');
  }

  // Logic to fetch school suggestions from Firestore
  Future<List<Map<String, dynamic>>> _getSchoolSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .where('schoolName', isGreaterThanOrEqualTo: query)
          .where('schoolName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(5)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error fetching schools: $e");
      return [];
    }
  }

  Future<void> _fetchLatestUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && mounted) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          if (data.containsKey('profile_image')) {
            _profileImageUrl = data['profile_image'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching latest data: $e");
    }
  }

  @override
  void dispose() {
    _principalNameController.dispose();
    _schoolNameController.dispose();
    _schoolTypeController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _officePhoneController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  void _showMessage(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final bytes = await image.readAsBytes();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://buildcare.atigalle.x10.mx/index.php'),
      );

      request.files.add(http.MultipartFile.fromBytes('profile_image', bytes, filename: 'upload.jpg'));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          String newImageUrl = jsonResponse['profileImageUrl'];
          await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({'profile_image': newImageUrl});

          if (mounted) {
            setState(() => _profileImageUrl = newImageUrl);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Photo Updated!")));
          }
        }
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final dataToUpdate = {
        'name': _principalNameController.text.trim(),
        'principalName': _principalNameController.text.trim(),
        'schoolName': _schoolNameController.text.trim(), // Now saving the edited school name
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'mobilePhone': _mobileController.text.trim(),
        'officePhone': _officePhoneController.text.trim(),
        'schoolType': _schoolTypeController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(dataToUpdate);

      _showMessage('Success', 'Your profile and school information have been updated.');
    } catch (e) {
      _showMessage('Update Failed', 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Components ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(_principalNameController, "Principal Name", readOnly: false),
          const SizedBox(height: 15),
          
          // --- AUTOCOMPLETE SCHOOL NAME FIELD ---
          const Text("School Name", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500, fontSize: 12)),
          Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (option) => option['schoolName'] ?? '',
            optionsBuilder: (TextEditingValue textEditingValue) async {
              return await _getSchoolSuggestions(textEditingValue.text);
            },
            onSelected: (Map<String, dynamic> selection) {
              setState(() {
                _schoolNameController.text = selection['schoolName'] ?? '';
                if (selection.containsKey('schoolType')) {
                  _schoolTypeController.text = selection['schoolType'];
                }
              });
            },
            fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
              // Pre-fill with existing data if controller is empty
              if (fieldTextEditingController.text.isEmpty && _schoolNameController.text.isNotEmpty) {
                fieldTextEditingController.text = _schoolNameController.text;
              }
              return TextField(
                controller: fieldTextEditingController,
                focusNode: focusNode,
                onChanged: (value) => _schoolNameController.text = value,
                decoration: InputDecoration(
                  hintText: "Search or enter new school",
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primaryColor)),
                ),
              );
            },
          ),
          
          const SizedBox(height: 10),
          _buildTextField(_schoolTypeController, "School Type", readOnly: false),
          const SizedBox(height: 10),
          _buildTextField(_titleController, "Title", readOnly: true),
          const SizedBox(height: 10),
          _buildTextField(_nicController, "NIC", readOnly: true),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey[600]),
          labelText: label,
          border: InputBorder.none,
          labelStyle: TextStyle(color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          if (title == 'Change password') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordFlow()));
          }
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.black54 : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: readOnly ? Colors.grey[600] : _primaryColor, fontWeight: FontWeight.w500),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primaryColor)),
        fillColor: readOnly ? Colors.grey[200] : Colors.transparent,
        filled: readOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Center(child: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold))),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(userData: widget.userData, userId: widget.userId))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      image: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(_profileImageUrl!), fit: BoxFit.cover)
                          : null,
                      border: Border.all(color: _primaryColor, width: 2),
                    ),
                    child: _isUploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                            ? Icon(Icons.person, size: 70, color: Colors.grey[600])
                            : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      radius: 20, backgroundColor: _primaryColor,
                      child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20), onPressed: _pickAndUploadImage),
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionTitle('Personal Information'),
            _buildPersonalInfoCard(),
            _buildSectionTitle('Contact Information'),
            _buildEditableInfoCard(_emailController, 'Work Email', Icons.email_outlined),
            _buildEditableInfoCard(_phoneController, 'Personal Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
            _buildEditableInfoCard(_mobileController, 'Mobile', Icons.smartphone_outlined, keyboardType: TextInputType.phone),
            _buildEditableInfoCard(_officePhoneController, 'Office Phone', Icons.business_outlined, keyboardType: TextInputType.phone),
            _buildSectionTitle('Account Setting'),
            _buildSettingItem('Change password'),
            _buildSettingItem('Manage Notifications'),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Update Profile', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 30), activeIcon: Icon(Icons.home, size: 30), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 30), activeIcon: Icon(Icons.person, size: 30), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 30), activeIcon: Icon(Icons.settings, size: 30), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (context) => PrincipalDashboard(userData: widget.userData)));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(userData: widget.userData, userId: widget.userId)));
        },
      ),
    );
  }
}