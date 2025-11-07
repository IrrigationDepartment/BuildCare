import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // A Future to fetch the user's data
  late final Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future in initState
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 1,
        // TODO: Add an 'Edit' button
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit),
        //     onPressed: () {
        //       // Navigate to an EditUserPage
        //     },
        //   ),
        // ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          // 1. Show loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Show error
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data.'));
          }

          // 3. Check if user exists
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          // 4. If data is loaded, extract it
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          // Extract data with fallbacks
          final String name = userData['name'] ?? 'No Name';
          final String email = userData['email'] ?? 'No Email';
          final String nic = userData['nic'] ?? 'No NIC';
          final String mobile = userData['mobilePhone'] ?? 'No Phone';
          final String userType = userData['userType'] ?? 'No Role';
          final String schoolName = userData['schoolName'] ?? 'No School';
          final bool isActive = userData['isActive'] ?? false;
          final String profileImageUrl = userData['profile_image'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- Profile Image ---
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    // Use NetworkImage to load the URL
                    // If URL is empty or invalid, show a person icon
                    backgroundImage: (profileImageUrl.isNotEmpty)
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: (profileImageUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userType,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                // --- Active Status Badge ---
                Chip(
                  label: Text(
                    isActive ? 'Active' : 'Deactivated',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: isActive ? Colors.green : Colors.red,
                  avatar: Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                // --- User Details List ---
                _buildDetailRow(Icons.email, 'Email', email),
                _buildDetailRow(Icons.phone, 'Mobile Phone', mobile),
                _buildDetailRow(Icons.badge, 'NIC', nic),
                _buildDetailRow(Icons.school, 'School', schoolName),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to build detail rows
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
