import 'package:flutter/material.dart';

// --- The New Page: ManageUsersPage ---
class ManageUsersPage extends StatefulWidget {
  // Variable to receive the title sent from the Dashboard
  final String roleTitle;

  const ManageUsersPage({
    super.key,
    required this.roleTitle, // Title is required
  });

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  // --- Dummy Data to display on the UI ---
  // You will need to load this data from Firebase or another source
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
      "name": "Pasidu Rajapaksha", // 3rd card in the image
      "email": "pasi@email.com",
      "phone": "+ 71 59 59 479",
      "role": "Chief Engineer",
      "district": "Hambanthota",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color is dark grey, like in the image
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Top Title Bar ("Manage Chief Engineer") ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.roleTitle, // Displaying the Title sent from the Dashboard
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // --- 2. White Main Content Area ---
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // --- 2.1. "Pending Approvals" Header ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Row(
                        children: [
                          // Back button
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () {
                              // Navigates back to the dashboard when clicked
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Pending Approvals',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- 2.2. User Cards List ---
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: pendingUsers.length, // Number of items in the list
                        itemBuilder: (context, index) {
                          // Data for one user from the list
                          final user = pendingUsers[index];
                          // Calling the function that builds the User Card
                          return _buildUserCard(user);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // --- 3. Bottom Navigation Bar ---
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- Function to build a User Card ---
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
            // --- 1. Name, Email, and Icon ---
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

            // --- 2. Phone, Role, District, Edit ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Phone, District
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
                // Right Side: Role, Edit Button
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
                          onPressed: () {
                            // Action when the Edit button is clicked
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 3. View and Approve Buttons ---
            Row(
              children: [
                Expanded(
                  child: _buildStyledButton(
                    text: 'View',
                    color: Colors.blue,
                    icon: Icons.remove_red_eye,
                    onPressed: () {
                      // Action when the View button is clicked
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStyledButton(
                    text: 'Approve',
                    color: Colors.green,
                    icon: Icons.check_circle,
                    onPressed: () {
                      // Action when the Approve button is clicked
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build an Info Row (e.g., "Phone: +71...")
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

  // Helper function to build the styled Button as seen in the image
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

  // Function to build the Bottom Nav Bar as seen in the image
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
            onPressed: () {
              // Action when the Home icon is clicked
            },
          ),
          // Center Icon is blue, like in the image
          IconButton(
            icon: Icon(Icons.person, color: Colors.blue[700], size: 30),
            onPressed: () {
              // Action when the Person icon is clicked
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey, size: 30),
            onPressed: () {
              // Action when the Settings icon is clicked
            },
          ),
        ],
      ),
    );
  }
}