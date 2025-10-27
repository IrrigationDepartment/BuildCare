// manage_users.dart
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// --- ManageUsersPage (New UI) ---
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
  // --- Dummy Data for Pending Approvals Section (Top List) ---
  // මෙම ලැයිස්තුව දැන් භාවිතයෙන් තොරයි (Comment කර ඇති නිසා), නමුත් දත්ත එලෙසම තබා ඇත.
  final List<Map<String, String>> pendingUsers = [
    {
      "name": "Pasidu Rajapaksha",
      "email": "pasi@email.com",
      "phone": "+ 71 59 59 479",
      "role": "Chief Engineer",
      "district": "Matara",
    },
    {
      "name": "Madushan Gunawardana",
      "email": "madush.19@gmail.com",
      "phone": "+ 76 58 25 479",
      "role": "Chief Engineer",
      "district": "Galle",
    },
    {
      "name": "Pasidu Rajapaksha",
      "email": "pasi@email.com",
      "phone": "+ 71 59 59 479",
      "role": "Chief Engineer",
      "district": "Hambanthota",
    },
  ];

  // --- Dummy Data for Lower Approvals Section (UserCard List) ---
  // මෙම ලැයිස්තුව General Pending Approvals සඳහා භාවිතා වේ.
  final List<Map<String, dynamic>> lowerApprovalUsers = [
    {
      "name": "Nimal Bandara",
      "role": "District Engineer - Colombo",
      "isApproved": false,
    },
    {
      "name": "Kamani Perera",
      "role": "Technical Officer - Galle",
      "isApproved": false,
    },
    {
      "name": "Jayantha Sirisena",
      "role": "Principal - Kandy",
      "isApproved": true,
    },
  ];

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
                       * --- COMMENTED OUT: Role Specific Approvals (Chief Engineer, etc.)
                       * ------------------------------------------------------------------ */
                      // // --- 2.1. "Pending Approvals" Header with Back Button (Top List) ---
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      //   child: Row(
                      //     children: [
                      //       // Back button
                      //       IconButton(
                      //         icon: const Icon(Icons.arrow_back, color: Colors.black),
                      //         onPressed: () => Navigator.pop(context),
                      //       ),
                      //       const SizedBox(width: 10),
                      //       Text(
                      //         '${widget.roleTitle.split(' ').last} Approvals', // E.g., 'Engineer Approvals'
                      //         style: const TextStyle(
                      //           color: Colors.black,
                      //           fontSize: 20,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      // // --- 2.2. User Cards List (Top List) ---
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      //   child: ListView.builder(
                      //     physics: const NeverScrollableScrollPhysics(), 
                      //     shrinkWrap: true,
                      //     itemCount: pendingUsers.length,
                      //     itemBuilder: (context, index) {
                      //       final user = pendingUsers[index];
                      //       return _buildUserCard(user);
                      //     },
                      //   ),
                      // ),

                      // const SizedBox(height: 20),
                      // const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                      // const SizedBox(height: 20),
                      
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
                      
                      // UserCard Widgets (Bottom List)
                      ...lowerApprovalUsers.map((user) => UserCard(
                            userName: user['name'],
                            userRole: user['role'],
                            isApproved: user['isApproved'],
                          )).toList(),
                      
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

  // --- Helper Widgets (Kept as is) ---
  
  // This helper is now only technically necessary if you uncomment the top list later.
  Widget _buildUserCard(Map<String, String> user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user['email']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Phone', user['phone']!),
                      const SizedBox(height: 12),
                      _buildInfoRow('District', user['district']!),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Role', user['role']!),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStyledButton(
                          text: 'Edit',
                          color: Colors.orange,
                          icon: Icons.edit,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStyledButton(
                    text: 'View',
                    color: Colors.blue,
                    icon: Icons.remove_red_eye,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStyledButton(
                    text: 'Approve',
                    color: Colors.green,
                    icon: Icons.check_circle,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Info Row Helper
  Widget _buildInfoRow(String label, String value) {
    return Column(
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
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Styled Button Helper
  Widget _buildStyledButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

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
// --- UserCard (General Approval List Item) ---
// -----------------------------------------------------------------------------
class UserCard extends StatelessWidget {
  final String userName;
  final String userRole;
  final bool isApproved;

  const UserCard({
    super.key,
    required this.userName,
    required this.userRole,
    required this.isApproved,
  });

  // Common navigation function for buttons
  void _navigateToBlankPage(BuildContext context, String action) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlankActionPage(
          action: action,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionButton(
                    text: 'View',
                    color: Colors.blue,
                    onPressed: () => _navigateToBlankPage(context, 'View Details'),
                  ),
                  _ActionButton(
                    text: 'Edit',
                    color: Colors.deepOrange,
                    onPressed: () => _navigateToBlankPage(context, 'Edit User'),
                  ),
                  if (!isApproved)
                    _ActionButton(
                      text: 'Approve',
                      color: Colors.green,
                      onPressed: () => _navigateToBlankPage(context, 'Approve User'),
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
// --- Blank Action Page (for button clicks on UserCard) ---
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