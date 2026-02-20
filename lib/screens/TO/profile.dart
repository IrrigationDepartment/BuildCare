import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- Imports ---
import 'dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  String? _profileImageUrl;
  String? _email;
  String? _userType;
  Map<String, dynamic>? _userDataMap;

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
          _mobileController.text = data['mobilePhone'] ?? '';
          _profileImageUrl = data['profile_image'];
          _email = data['email'];
          _userType = data['userType'];

          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  /// FIXED: Profile Picture Update function using your custom URL
  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUpdating = true);

    try {
      var uri = Uri.parse('http://buildcare.atigalle.x10.mx/profile/TO');

      var request = http.MultipartRequest('POST', uri);

      final byteData = await image.readAsBytes();

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        byteData,
        filename: image.name,
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        String downloadUrl = jsonResponse['url'] ?? '';

        if (downloadUrl.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .update({'profile_image': downloadUrl});

          setState(() {
            _profileImageUrl = downloadUrl;
            if (_userDataMap != null) {
              _userDataMap!['profile_image'] = downloadUrl;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateProfileData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'name': _nameController.text.trim(),
        'mobilePhone': _mobileController.text.trim(),
      });

      if (_userDataMap != null) {
        _userDataMap!['name'] = _nameController.text.trim();
        _userDataMap!['mobilePhone'] = _mobileController.text.trim();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
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
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: _profileImageUrl != null &&
                                      _profileImageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _profileImageUrl == null ||
                                    _profileImageUrl!.isEmpty
                                ? const Icon(Icons.person,
                                    size: 80, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUpdating ? null : _updateProfilePicture,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle),
                                child: _isUpdating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                        controller: _nameController,
                        label: 'Full name',
                        icon: Icons.person_outline),
                    const SizedBox(height: 10),
                    _buildReadOnlyField(
                        label: 'Title', value: _userType ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildReadOnlyField(
                        label: 'Work Email', value: _email ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildTextField(
                        controller: _mobileController,
                        label: 'Mobile Phone',
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateProfileData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[400],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isUpdating
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Update Profile',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      IconData? icon,
      TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)
          ]),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(15)),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value,
            style: const TextStyle(color: Colors.black87, fontSize: 16)),
      ]),
    );
  }
}