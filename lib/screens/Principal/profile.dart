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

  // Define the primary color (matching #53BDFF from SettingsPage)
  static const Color _primaryColor = Color(0xFF53BDFF);

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data.
    // **IMPORTANT**: If 'principalName', 'phone', or 'mobile' are not the
    // exact keys in your Firestore document, you must change them here.
    // I've kept your existing keys and added a safe default ('') using `??`.
    _principalNameController =
        TextEditingController(text: widget.userData['principalName'] ?? '');
    _schoolNameController =
        TextEditingController(text: widget.userData['schoolName'] ?? '');
    _schoolTypeController =
        TextEditingController(text: widget.userData['schoolType'] ?? '');
    // Assuming 'Title' field in the UI is 'userType' in Firestore
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
      // Data fields that are editable and need to be updated in Firestore
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
      // Show the actual Firebase error for debugging
      _showMessage('Update Failed', 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Helper Widgets for Building the UI ---

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
          // This field is made editable as it's part of the `dataToUpdate` map.
          _buildTextField(_principalNameController, "Principal Name", readOnly: false), 
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
    // Note: Using a standard blue for the text field focus color.
    final accentColor = readOnly ? Colors.grey[600] : _primaryColor;
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.black54 : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w500),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _primaryColor), // Use primary color here
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
        // UPDATED: Title widget is wrapped in Center and uses bold font weight
        title: const Center(
          child: Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        // The default `centerTitle` property of AppBar is `false` unless 
        // there is a leading widget (which there is not here), or the theme 
        // sets it to true. Using Center widget explicitly ensures centering.
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
                      backgroundColor: _primaryColor, // Use primary color here
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
            // These fields are editable and will be updated
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
                          backgroundColor: _primaryColor, // Use primary color here
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
      // --- Bottom Navigation Bar with consistent color and size ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Highlight the Profile icon (index 1)
        selectedItemColor: _primaryColor, // Use the consistent primary color
        unselectedItemColor: Colors.grey[600], // Standard unselected color
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed, // Ensure icons and labels don't shift
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 30),
            activeIcon: Icon(Icons.home, size: 30), 
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 30), 
            activeIcon: Icon(Icons.person, size: 30), 
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 30),
            activeIcon: Icon(Icons.settings, size: 30), 
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigate back to the Dashboard/Home page
            Navigator.pop(context); 
          } 
          // index 1 (Profile) does nothing, as we are already here.
          // For index 2 (Settings), you would implement navigation to the SettingsPage.
        },
      ),
    );
  }
}