import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final String userType;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userData,
    required this.userType,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _isActive = widget.userData['isActive'] ?? false;
  }

  Future<void> _toggleUserStatus() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _firestore.collection('users').doc(widget.userId).update({
        'isActive': !_isActive,
        'updatedAt': Timestamp.now(),
      });

      setState(() {
        _isActive = !_isActive;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${_isActive ? 'activated' : 'deactivated'} successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this user? This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _firestore.collection('users').doc(widget.userId).delete();

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserDetails() async {
    final nameController =
        TextEditingController(text: widget.userData['name'] ?? '');
    final phoneController =
        TextEditingController(text: widget.userData['mobilePhone'] ?? '');
    final emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    final nicController =
        TextEditingController(text: widget.userData['nic'] ?? '');
    final officeController =
        TextEditingController(text: widget.userData['office'] ?? '');
    final officePhoneController =
        TextEditingController(text: widget.userData['officePhone'] ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Name Field
              _buildModernTextField(
                label: 'Full Name',
                controller: nameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              
              // Email Field
              _buildModernTextField(
                label: 'Email Address',
                controller: emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Mobile Phone Field
              _buildModernTextField(
                label: 'Mobile Phone',
                controller: phoneController,
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              // NIC Field
              _buildModernTextField(
                label: 'NIC Number',
                controller: nicController,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              
              // Office Field
              _buildModernTextField(
                label: 'Office',
                controller: officeController,
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 16),
              
              // Office Phone Field
              _buildModernTextField(
                label: 'Office Phone',
                controller: officePhoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final updatedData = {
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'mobilePhone': phoneController.text.trim(),
                      'nic': nicController.text.trim(),
                      'office': officeController.text.trim(),
                      'officePhone': officePhoneController.text.trim(),
                      'updatedAt': Timestamp.now(),
                    };
                    
                    Navigator.pop(context);
                    await _saveUserDetails(updatedData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _saveUserDetails(Map<String, dynamic> updatedData) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _firestore
          .collection('users')
          .doc(widget.userId)
          .update(updatedData);

      // Update local data
      widget.userData.addAll(updatedData);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
    final createdAt = widget.userData['createdAt'] != null
        ? (widget.userData['createdAt'] as Timestamp).toDate()
        : null;
    final updatedAt = widget.userData['updatedAt'] != null
        ? (widget.userData['updatedAt'] as Timestamp).toDate()
        : null;
    
    final profileImageUrl = widget.userData['profile_image'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue.shade700),
            onPressed: _updateUserDetails,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // Profile Image
                        profileImageUrl.isNotEmpty
                            ? CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(profileImageUrl),
                                onBackgroundImageError: (exception, stackTrace) {
                                  // If image fails to load, show initials
                                },
                                child: profileImageUrl.isEmpty
                                    ? Text(
                                        widget.userData['name'] != null &&
                                                widget.userData['name'].isNotEmpty
                                            ? widget.userData['name'][0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      )
                                    : null,
                              )
                            : CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                child: Text(
                                  widget.userData['name'] != null &&
                                          widget.userData['name'].isNotEmpty
                                      ? widget.userData['name'][0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userData['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isActive
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isActive
                                        ? Colors.green
                                        : Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: _isActive
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.userData['userType'] ?? widget.userType,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Personal Information Card
                  _buildDetailCard(
                    'Personal Information',
                    [
                      _buildInfoItem(
                        'Email Address',
                        widget.userData['email'] ?? '',
                        Icons.email_outlined,
                      ),
                      const Divider(height: 1),
                      _buildInfoItem(
                        'Mobile Phone',
                        widget.userData['mobilePhone'] ?? '',
                        Icons.phone_android_outlined,
                      ),
                      const Divider(height: 1),
                      _buildInfoItem(
                        'NIC Number',
                        widget.userData['nic'] ?? '',
                        Icons.badge_outlined,
                      ),
                      const Divider(height: 1),
                      _buildInfoItem(
                        'Office',
                        widget.userData['office'] ?? '',
                        Icons.work_outline,
                      ),
                      const Divider(height: 1),
                      _buildInfoItem(
                        'Office Phone',
                        widget.userData['officePhone'] ?? '',
                        Icons.phone_outlined,
                      ),
                      const Divider(height: 1),
                      _buildInfoItem(
                        'Security Question (Nickname)',
                        widget.userData['securityQuestionNickname'] ?? '',
                        Icons.security_outlined,
                      ),
                      const Divider(height: 1),
                      _buildInfoItem(
                        'Security Question (Pet)',
                        widget.userData['securityQuestionPet'] ?? '',
                        Icons.pets_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Account Information Card
                  _buildDetailCard(
                    'Account Information',
                    [
                      _buildInfoItem(
                        'User ID',
<<<<<<< HEAD
                        widget.userId.substring(0, 8) + '...',
=======
                        '${widget.userId.substring(0, 8)}...',
>>>>>>> main
                        Icons.fingerprint_outlined,
                      ),
                      const Divider(height: 1),
                      if (createdAt != null)
                        _buildInfoItem(
                          'Account Created',
                          DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                          Icons.calendar_today_outlined,
                        ),
                      if (updatedAt != null) ...[
                        const Divider(height: 1),
                        _buildInfoItem(
                          'Last Updated',
                          DateFormat('dd MMM yyyy, hh:mm a').format(updatedAt),
                          Icons.update_outlined,
                        ),
                      ],
                      const Divider(height: 1),
                      _buildInfoItem(
                        'Profile Image URL',
                        profileImageUrl.isNotEmpty 
                            ? '${profileImageUrl.substring(0, 30)}...' 
                            : 'Not set',
                        Icons.image_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleUserStatus,
                          icon: Icon(
                            _isActive
                                ? Icons.person_off_outlined
                                : Icons.person_add_alt_1_outlined,
                            size: 20,
                          ),
                          label: Text(_isActive ? 'Deactivate' : 'Activate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isActive
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                            side: BorderSide(
                              color: _isActive
                                  ? Colors.orange.shade300
                                  : Colors.green.shade300,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteUser,
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}