import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- ADDED ---
// Import the new profile page
import 'user_profile.dart';

/// This is the common page to display a list of users
/// based on their role (userType).
class AllUsersPage extends StatelessWidget {
  final String userType;

  const AllUsersPage({
    super.key,
    required this.userType,
  });

  // --- ADDED FUNCTION ---
  /// Toggles the 'isActive' status of a user in Firebase
  Future<void> _toggleUserStatus(
      BuildContext context, String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'isActive': !currentStatus}); // Invert the status

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User ${!currentStatus ? "activated" : "deactivated"}.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All $userType' +
            's'), // Added 'All' and 's' for better title
        backgroundColor: const Color(0xFFF4F6F8), // Match theme
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF4F6F8), // Match theme
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: userType)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading users.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No users found for this role.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final String userId = users[index].id; // Get the document ID

              // Get data from the document (with fallbacks)
              final String name = userData['name'] ?? 'No Name';
              final String nic = userData['nic'] ?? 'No NIC';
              final bool isActive = userData['isActive'] ?? false;
              // Get the profile image URL
              final String profileImageUrl =
                  userData['profile_image'] ?? '';

              return Card(
                elevation: 1,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  // --- MODIFIED: Leading ---
                  // Show profile image in a CircleAvatar
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (profileImageUrl.isNotEmpty)
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: (profileImageUrl.isEmpty)
                        ? Icon(Icons.person, color: Colors.grey.shade600)
                        : null,
                  ),
                  // --- END MODIFICATION ---

                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('NIC: $nic'),
                  isThreeLine: false, // Changed to false, NIC is enough

                  // --- MODIFIED: Trailing ---
                  // Replaced Icon with a Switch
                  trailing: Switch(
                    value: isActive,
                    activeColor: Colors.green,
                    onChanged: (newValue) {
                      // Call the function to update Firebase
                      _toggleUserStatus(context, userId, isActive);
                    },
                  ),
                  // --- END MODIFICATION ---

                  // --- MODIFIED: onTap ---
                  // Navigate to the UserProfilePage
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserProfilePage(userId: userId),
                      ),
                    );
                  },
                  // --- END MODIFICATION ---
                ),
              );
            },
          );
        },
      ),
    );
  }
}