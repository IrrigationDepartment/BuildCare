import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  // You MUST pass the user's data and their Firestore document ID to this page
  final Map<String, dynamic> userData;
  final String userId; // This is the document ID

  const ProfilePage({
    super.key,
    required this.userData,
    required this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers to manage the text fields
  late TextEditingController _principalNameController;
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolTypeController;
  late TextEditingController _titleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _nicController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the correct keys from Firestore
    _principalNameController =
        TextEditingController(text: widget.userData['principalName'] ?? '');
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
    _mobileController =
        TextEditingController(text: widget.userData['mobile'] ?? '');
    _nicController = TextEditingController(text: widget.userData['nic'] ?? '');
  }

  @override
  void dispose() {
    // Dispose all updated controllers
    _principalNameController.dispose();
    _schoolNameController.dispose();
    _schoolTypeController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
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
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  /// Handles the profile update logic
  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataToUpdate = {
        'principalName': _principalNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'mobile': _mobileController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(dataToUpdate);

      _showMessage('Success', 'Your profile has been updated.');
    } catch (e) {
      // --- THIS IS THE FIX ---
      // Instead of a generic message, show the actual Firebase error.
      // This will tell you if it's a PERMISSION_DENIED error.
      _showMessage('Update Failed', 'Error: ${e.toString()}');
      // --- END OF FIX ---
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Helper Widgets for Building the UI (No changes below this line) ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(_principalNameController, "Principal Name"),
          const SizedBox(height: 10),
          _buildTextField(_schoolNameController, "School Name", readOnly: true),
          const SizedBox(height: 10),
          _buildTextField(_schoolTypeController, "School Type", readOnly: true),
          const SizedBox(height: 10),
          _buildTextField(_titleController, "Title", readOnly: true),
          const SizedBox(height: 10),
          _buildTextField(_nicController, "NIC", readOnly: true),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          _showMessage('Not Implemented', '$title page is not ready yet.');
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: readOnly ? Colors.grey[600] : Colors.blueAccent,
            fontWeight: FontWeight.w500),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        fillColor: readOnly ? Colors.grey[100] : Colors.transparent,
        filled: readOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.grey[600],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blueAccent,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          _showMessage('Not Implemented',
                              'Image upload is not ready yet.');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionTitle('Personal Information'),
            _buildPersonalInfoCard(),
            _buildSectionTitle('Contact Information'),
            _buildEditableInfoCard(
                _emailController, 'Work Email', Icons.email_outlined),
            _buildEditableInfoCard(
                _phoneController, 'Phone', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            _buildEditableInfoCard(
                _mobileController, 'Mobile', Icons.smartphone_outlined,
                keyboardType: TextInputType.phone),
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
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Update Profile',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
