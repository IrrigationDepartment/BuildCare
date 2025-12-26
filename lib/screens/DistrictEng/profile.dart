import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../forgot_password_flow.dart';
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
  String? _officePhone;
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
          _officePhone = data['officePhone'];
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

  // Profile picture upload logic (Supports Web & Mobile)
  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;
    setState(() => _isUpdating = true);

    try {
      var uri = Uri.parse('https://your-server.com/api/upload');
      var request = http.MultipartRequest('POST', uri);
      final byteData = await image.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        byteData,
        filename: image.name,
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        String downloadUrl = jsonResponse['url'];

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'profile_image': downloadUrl});

        setState(() {
          _profileImageUrl = downloadUrl;
          if (_userDataMap != null) _userDataMap!['profile_image'] = downloadUrl;
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      } else {
        throw Exception('Server upload failed');
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
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
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    } catch (e) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
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
            // Navigate back to the Dashboard with updated data
            if (_userDataMap != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DistrictEngDashboard(userData: _userDataMap!),
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(_profileImageUrl!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                                ? const Icon(Icons.person, size: 80, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _updateProfilePicture,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    _buildTextField(controller: _nameController, label: 'Full name', icon: Icons.person_outline),
                    const SizedBox(height: 10),
                    _buildReadOnlyField(label: 'Title', value: _userType ?? 'N/A'),
                    const SizedBox(height: 30),
                    const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    _buildReadOnlyField(label: 'Work Email', value: _email ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _mobileController, label: 'Mobile Phone', icon: Icons.phone_android, keyboardType: TextInputType.phone),
                    const SizedBox(height: 10),
                    _buildReadOnlyField(label: 'Office Phone', value: _officePhone ?? 'N/A'),
                    const SizedBox(height: 30),
                    const Text('Account Setting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    _buildSettingsTile(
                        title: 'Change password',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordFlow()));
                        }),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateProfileData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[400],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isUpdating
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Update Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget methods...
  Widget _buildTextField({required TextEditingController controller, required String label, IconData? icon, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, spreadRadius: 1)]),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16)),
      ]),
    );
  }

  Widget _buildSettingsTile({required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}