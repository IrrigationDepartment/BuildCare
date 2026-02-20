// manage_users.dart
import 'package:flutter/material.dart';
// Import Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

// -----------------------------------------------------------------------------
// --- ManageUsersPage (Updated with Firestore StreamBuilder) ---
// -----------------------------------------------------------------------------
class ManageUsersPage extends StatefulWidget {
  final String roleTitle;

  const ManageUsersPage({
    super.key,
    required this.roleTitle,
  });

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  // --- Dummy Data (Removed) ---
  // The dummy 'pendingUsers' and 'lowerApprovalUsers' lists have been removed.
  // We will now fetch live data from Firestore.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Top Title Bar (Role Title) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.roleTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // --- 2. White Main Content Area (Scrollable) ---
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* ------------------------------------------------------------------
                       * --- START: General Pending User Approvals Section
                       * ------------------------------------------------------------------ */
                      
                      // Back Button and Title for General Approvals
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 16.0, top: 20.0, bottom: 8.0),
                        child: Row(
                          children: [
                            // Back button
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'General Pending Approvals', 
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // --- Firestore StreamBuilder for Pending Users ---
                      StreamBuilder<QuerySnapshot>(
                        // Query: Get users where 'status' is 'Pending'
                        stream: FirebaseFirestore.instance
                            .collection('users') // <-- !! COLLECTION NAME !!
                            .where('status', isEqualTo: 'Pending')
                            .snapshots(),
                        
                        builder: (context, snapshot) {
                          // 1. Loading State
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                      
                          // 2. Error State
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Error loading users: ${snapshot.error}'),
                              ),
                            );
                          }
                      
                          // 3. No Data State
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text(
                                  'No pending user approvals.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, color: Colors.black54),
                                ),
                              ),
                            );
                          }
                      
                          final users = snapshot.data!.docs;
                      
                          // 4. Data Loaded State (Display List)
                          return ListView.builder(
                            itemCount: users.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final userDoc = users[index];
                              final userData = userDoc.data() as Map<String, dynamic>;
                              final userId = userDoc.id;
                      
                              return UserCard(
                                userId: userId, // Pass the Document ID
                                userName: userData['name'] ?? 'No Name',
                                userRole: userData['role'] ?? 'No Role',
                                // We know isApproved is false because we filtered for 'Pending'
                                isApproved: false, 
                              );
                            },
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      /* ------------------------------------------------------------------
                       * --- END: General Pending User Approvals Section
                       * ------------------------------------------------------------------ */
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // --- 4. Bottom Navigation Bar ---
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- Helper Widgets ---

  // Bottom Nav Bar Helper
  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.grey, size: 30),
            onPressed: () { /* Home action */ },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.blue[700], size: 30),
            onPressed: () { /* Person action */ },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey, size: 30),
            onPressed: () { /* Settings action */ },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- UserCard (Updated with Firestore Actions) ---
// -----------------------------------------------------------------------------
class UserCard extends StatelessWidget {
  final String userId; // <-- Added to know which document to update
  final String userName;
  final String userRole;
  final bool isApproved;

  const UserCard({
    super.key,
    required this.userId, // <-- Added
    required this.userName,
    required this.userRole,
    required this.isApproved,
  });

  // --- Action Helper Functions ---

  // 1. Update User Status (Approve or Reject)
  Future<void> _updateUserStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users') // <-- !! COLLECTION NAME !!
          .doc(userId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User $userName ${newStatus.toLowerCase()}.'),
          backgroundColor: newStatus == 'Approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 2. View User Details (Keeps old logic)
  void _viewUserDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlankActionPage(
          action: 'View Details',
          target: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.account_circle, size: 40, color: Colors.blueGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isApproved ? Icons.check_circle : Icons.pending,
                    color: isApproved ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ],
              ),
              const Divider(height: 20),
              // --- Updated Action Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionButton(
                    text: 'View',
                    color: Colors.blue,
                    onPressed: () => _viewUserDetails(context),
                  ),
                  // 'Reject' button (Replaced 'Edit')
                  _ActionButton(
                    text: 'Reject',
                    color: Colors.red.shade700,
                    onPressed: () => _updateUserStatus(context, 'Rejected'),
                  ),
                  // 'Approve' button (Now functional)
                  if (!isApproved)
                    _ActionButton(
                      text: 'Approve',
                      color: Colors.green,
                      onPressed: () => _updateUserStatus(context, 'Approved'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Buttons (Used in UserCard)
class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            elevation: 1,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- Blank Action Page (No changes needed) ---
// -----------------------------------------------------------------------------
class BlankActionPage extends StatelessWidget {
  final String action;
  final String target;

  const BlankActionPage({super.key, required this.action, required this.target});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(action),
        backgroundColor: const Color(0xFFE8F2FF),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'This is the blank page for the "$action" action on user: $target.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}