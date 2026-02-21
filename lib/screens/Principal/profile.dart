import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  bool _isUploadingImage = false;
  bool _isUpdatingData = false;
  bool _isLoadingData = true;
  String? _profileImageUrl;

  List<Map<String, dynamic>> _availableSchools = [];
  String? _selectedSchoolId;

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _secondaryColor = Color(0xFF0077FF);

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolPhoneController;

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.userData['profile_image'];
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['mobilePhone'] ?? widget.userData['phone'] ?? '');
    _schoolNameController = TextEditingController(text: widget.userData['schoolName'] ?? '');
    _schoolPhoneController = TextEditingController(text: widget.userData['officePhone'] ?? '');

    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchSchoolsForAutocomplete();
    await _fetchLatestUserData();
    if (mounted) setState(() => _isLoadingData = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _schoolNameController.dispose();
    _schoolPhoneController.dispose();
    super.dispose();
  }

  // --- FETCHING ---
  Future<void> _fetchSchoolsForAutocomplete() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('schools').get();
      if (mounted) {
        _availableSchools = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'schoolName': data['schoolName'] ?? '',
            'schoolPhone': data['schoolPhone'] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _fetchLatestUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists && mounted) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _profileImageUrl = userData['profile_image'];
          _nameController.text = userData['name'] ?? '';
          _phoneController.text = userData['mobilePhone'] ?? userData['phone'] ?? '';
          _schoolNameController.text = userData['schoolName'] ?? '';
          _schoolPhoneController.text = userData['officePhone'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- UPDATING ---
  Future<void> _updateProfileData() async {
    if (_nameController.text.trim().isEmpty || _schoolNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fields cannot be empty.")));
      return;
    }

    setState(() => _isUpdatingData = true);

    try {
      String typedSchoolName = _schoolNameController.text.trim();
      String typedSchoolPhone = _schoolPhoneController.text.trim();
      String userNic = widget.userData['nic'] ?? "";

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. School Update
      DocumentReference schoolRef;
      bool isNewSchool = true;
      for (var school in _availableSchools) {
        if (school['schoolName'].toString().toLowerCase() == typedSchoolName.toLowerCase()) {
          isNewSchool = false;
          _selectedSchoolId = school['id'];
          break;
        }
      }

      if (isNewSchool) {
        schoolRef = FirebaseFirestore.instance.collection('schools').doc();
        batch.set(schoolRef, {
          'addedAt': FieldValue.serverTimestamp(),
          'addedByNic': userNic,
          'schoolName': typedSchoolName,
          'schoolPhone': typedSchoolPhone,
          'isActive': true,
        });
      } else {
        schoolRef = FirebaseFirestore.instance.collection('schools').doc(_selectedSchoolId);
        batch.update(schoolRef, {'schoolPhone': typedSchoolPhone, 'schoolName': typedSchoolName});
      }

      // 2. User Profiles Sync
      QuerySnapshot userQuery = await FirebaseFirestore.instance.collection('users').where('nic', isEqualTo: userNic).get();
      for (var doc in userQuery.docs) {
        batch.update(doc.reference, {
          'name': _nameController.text.trim(),
          'mobilePhone': _phoneController.text.trim(),
          'schoolName': typedSchoolName,
          'officePhone': typedSchoolPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // FIX: Force Re-fetch to show new data immediately
      await _fetchLatestUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Update error: $e");
    } finally {
      if (mounted) setState(() => _isUpdatingData = false);
    }
  }

  // --- RESPONSIVE UI ---

  Widget _buildLockedCard(String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        trailing: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    bool isLargeScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Profile"), centerTitle: true, elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator()) 
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isLargeScreen ? 800 : double.infinity),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 40 : 20, vertical: 20),
                child: Column(
                  children: [
                    // Profile Photo
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                      child: _profileImageUrl == null ? const Icon(Icons.person, size: 50) : null,
                    ),
                    const SizedBox(height: 30),

                    // Layout based on screen size
                    isLargeScreen 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSystemInfoSection()),
                            const SizedBox(width: 40),
                            Expanded(child: _buildEditableSection()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildSystemInfoSection(),
                            const Divider(height: 40),
                            _buildEditableSection(),
                          ],
                        ),
                    
                    const SizedBox(height: 40),
                    // Large Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isUpdatingData ? null : _updateProfileData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: _isUpdatingData ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSystemInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("System Records (Locked)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        _buildLockedCard("Email", widget.userData['email'] ?? 'N/A', Icons.email),
        _buildLockedCard("User Type", widget.userData['userType'] ?? 'N/A', Icons.person_pin),
        _buildLockedCard("NIC", widget.userData['nic'] ?? 'N/A', Icons.badge),
      ],
    );
  }

  Widget _buildEditableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Editable Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        _buildTextField("Full Name", _nameController, Icons.person_outline),
        _buildTextField("Personal Phone", _phoneController, Icons.phone_android),
        
        // Autocomplete for Schools
        Autocomplete<Map<String, dynamic>>(
          initialValue: TextEditingValue(text: _schoolNameController.text),
          optionsBuilder: (textValue) => _availableSchools.where((s) => s['schoolName'].toLowerCase().contains(textValue.text.toLowerCase())),
          displayStringForOption: (option) => option['schoolName'],
          onSelected: (selection) {
            _schoolNameController.text = selection['schoolName'];
            _schoolPhoneController.text = selection['schoolPhone'] ?? '';
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return _buildTextField("School Name", controller, Icons.school, focusNode: focusNode);
          },
        ),

        _buildTextField("School Phone", _schoolPhoneController, Icons.phone),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {FocusNode? focusNode}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        ),
      ),
    );
  }
}