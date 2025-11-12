import 'package:flutter/material.dart';
import 'add_school_details_page.dart';
import 'add_building_issues_page.dart';
// This import is correct, it imports the file containing 'AddMasterPlanScreen'
import 'add_school_master_plan_page.dart';
import 'profile.dart';
import 'settings_page.dart';

// 🚀 NEW IMPORTS
// Add these two lines to import Firestore and date formatting tools
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PrincipalDashboard extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const PrincipalDashboard({super.key, required this.userData});

  static const Color _primaryColor = Color(0xFF53BDFF);

  // --- Helper function for navigation to keep the onTap clean ---
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      // Home - Do nothing, already on Dashboard
    } else if (index == 1) {
      // Profile - Navigate to ProfilePage
      if (userData != null) {
        final String principalId = userData!['uid'] ?? 'principal_doc_id_123';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userData: userData!,
              userId: principalId,
            ),
          ),
        );
      }
    } else if (index == 2) {
      // Settings - Navigate to the Settings Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Handle null userData safely ---
    if (userData == null ||
        userData!['name'] == null ||
        userData!['schoolName'] == null ||
        userData!['nic'] == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 16),
              Text(
                'Could not load user data. Please ensure "name", "nic", and "schoolName" are available.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ⭐ EXTRACTED NIC: This line correctly extracts the NIC.
    final String userNic = userData!['nic'];
    final String principalName = userData!['name'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildWelcomeHeader(principalName),
              const SizedBox(height: 30),

              // Button 1: Add School Details
              _buildActionButton(
                icon: Icons.add,
                text: 'Add Your School Details',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddSchoolDetailsPage(
                        userNic: userNic,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              // Button 2: Navigate to Add Building Issues Page
              _buildActionButton(
                icon: Icons.build_outlined,
                text: 'Add Building Issues',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBuildingIssuesPage(
                        // ⭐ NIC IS ALREADY BEING PASSED HERE
                        userNic: userNic,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              // Button 3: Manage Master Plans with Navigation
              _buildActionButton(
                icon: Icons.map_outlined,
                text: 'Manage Master Plans',
                onTap: () {
                  final String schoolName = userData!['schoolName'];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMasterPlanScreen(
                        schoolName: schoolName,
                        userNic: userNic,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
              // 🚀 MODIFIED: Pass the userNic to the function
              _buildReportedIssuesSection(userNic),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 30), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 30),
              label: 'Settings'),
        ],
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS (kept as provided) ---

  Widget _buildWelcomeHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: _primaryColor,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Icon(icon, size: 30, color: _primaryColor),
                ),
                const SizedBox(width: 20),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //
  // 🚀 MODIFIED: This entire function is replaced with a StreamBuilder
  //
  Widget _buildReportedIssuesSection(String userNic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'My Reported Issues',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 15),
        
        // Use StreamBuilder to listen for data from Firestore
        StreamBuilder<QuerySnapshot>(
          // Create the query:
          // 1. Go to the 'issues' collection
          // 2. Filter where 'addedByNic' is equal to the logged-in user's NIC
          stream: FirebaseFirestore.instance
              .collection('issues')
              .where('addedByNic', isEqualTo: userNic)
              .snapshots(),
              
          builder: (context, snapshot) {
            // Show a loading circle while waiting
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show an error message if something went wrong
            if (snapshot.hasError) {
              return Center(
                  child: Text("Error loading issues: ${snapshot.error}"));
            }

            // Show a message if the user has no reported issues
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("You have not reported any issues yet."),
                ),
              );
            }

            // If we have data, get the list of documents
            final issues = snapshot.data!.docs;

            // Build a list of cards
            return ListView.builder(
              shrinkWrap: true, // Needed inside a SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Stops scrolling conflicts
              itemCount: issues.length,
              itemBuilder: (context, index) {
                // Get the data for the current issue
                final issueDoc = issues[index];
                final data = issueDoc.data() as Map<String, dynamic>;

                // Extract fields from the document (based on your screenshot)
                final String title = data['issueTitle'] ?? 'No Title';
                final String building = data['buildingName'] ?? 'N/A';
                final String status = data['status'] ?? 'N/A';
                
                // Safely get and format the date
                String formattedDate = 'Date N/A';
                if (data['dateOfOccurance'] != null) {
                  final Timestamp timestamp = data['dateOfOccurance'];
                  // Format date as YYYY-MM-DD
                  formattedDate = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
                }

                // Call the existing card widget with the live data
                return _buildIssueCard(
                  title: title,
                  status: '$building • $status', // Combine building and status
                  date: formattedDate,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildIssueCard({
    required String title,
    required String status,
    required String date,
  }) {
    // This widget is unchanged, as it's perfect for displaying the data
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      shadowColor: Colors.grey.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.home_work_outlined, size: 40, color: Colors.grey[700]),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(status,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[600])),
                  Text(date,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () {
                // TODO: Add navigation to a details page
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primaryColor),
                foregroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child:
                  const Text('View Details', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}