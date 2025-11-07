// In screens/TO/dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Screen Imports ---
// Manage Schools and Add School
import 'manage_schools_screen.dart';
import 'add_school_screen.dart'; // Retained, though not used in the dashboard menu

// Issue Reporting Screens
import 'issue_report_list_screen.dart';
import 'issue_report_details_screen.dart'; 

// --- NEW IMPORTS ---
import 'contract_details.dart'; // Import for Contract Details Screen
import 'contractor_details.dart'; // Import for Contractor Details Screen (New file)

// ====================================================================
// WIDGET
// ====================================================================

class TODashboard extends StatefulWidget {
  // Receive user data from the login page
  final Map<String, dynamic> userData;

  const TODashboard({super.key, required this.userData});

  @override
  State<TODashboard> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<TODashboard> {
  // --- Style & Color Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5); // Blue for icons/buttons
  static const Color kLightBlue = Color(0xFFE3F2FD); // Light blue for button border
  static const Color kBackgroundColor = Color(0xFFF5F7FA); // Light grey background
  static const Color kCardColor = Colors.white;
  static const Color kHeaderGrey = Color(0xFFF0F2F5); // Header card background
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  // --- Bottom Nav Bar State ---
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Placeholder for actual bottom navigation logic (Profile, Settings etc.)
    // For now, only the Home view is built out.
  }

// ====================================================================
// BUILD METHOD
// ====================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      // --- Main Body ---
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                _buildGridMenu(),
                const SizedBox(height: 24),
                _buildRecentActivityHeader(),
                const SizedBox(height: 16),
                _buildRecentActivityList(), // Firebase StreamBuilder
              ],
            ),
          ),
        ),
      ),
    );
  }

// ====================================================================
// HELPER WIDGETS
// ====================================================================

  /// 1. Builds the personalized welcome header.
  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: kHeaderGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: kPrimaryBlue,
            child: Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Use the user's name from the data
                  'Welcome, ${widget.userData['name'] ?? ''}!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'Technical Officer',
                  style: TextStyle(
                    fontSize: 16,
                    color: kSubTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Builds the 2x2 grid menu for main actions.
  Widget _buildGridMenu() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        // --- Manage School Card ---
        _buildMenuCard(
          icon: Icons.school,
          title: 'Manage School',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageSchoolsScreen(
                  userNic: widget.userData['nic'] ?? 'UNKNOWN_NIC',
                ),
              ),
            );
          },
        ),
        // --- Issues Report Card (Navigates to list) ---
        _buildMenuCard(
          icon: Icons.assessment,
          title: 'Issues Report',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IssueReportListScreen(
                  userNic: widget.userData['nic'] ?? 'UNKNOWN_NIC',
                ),
              ),
            );
          },
        ),
        // --- Contract Details Card (NAVIGATES TO ContractDetailsScreen) ---
        _buildMenuCard(
          icon: Icons.description,
          title: 'Contract Details',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContractDetailsScreen(),
              ),
            );
          },
        ),
        // --- Contractor Details Card (NAVIGATES TO ContractorDetailsScreen) ---
        _buildMenuCard(
          icon: Icons.business_center,
          title: 'Contractor Details',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContractorDetailsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Helper widget for the grid items (Menu Card)
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: kPrimaryBlue),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Builds the 'Recent Activity' section header.
  Widget _buildRecentActivityHeader() {
    return Row(
      children: [
        Icon(Icons.history, color: kSubTextColor),
        const SizedBox(width: 8),
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
      ],
    );
  }

  /// 4. Builds the list of recent issues using a Firebase StreamBuilder.
  Widget _buildRecentActivityList() {
    // Stream to fetch up to 5 most recent 'Pending Review' issues
    final Stream<QuerySnapshot> issuesStream = FirebaseFirestore.instance
        .collection('issues')
        .where('status', isEqualTo: 'Pending Review')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: issuesStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No pending reviews found.',
              style: TextStyle(color: kSubTextColor),
            ),
          );
        }

        // --- Data Loaded State ---
        return Column(
          children: snapshot.data!.docs
              .map((DocumentSnapshot document) {
                // Safely cast document data
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;

                String title = data['schoolName'] ?? 'Unknown School';
                String subtitle = data['issueTitle'] ?? 'No Title';
                String location = data['location'] ?? 'No Location';
                String status = data['status'] ?? 'No Status';

                return _buildActivityCard(
                  title: '$title - $subtitle',
                  subtitle: '$location - Status: $status',
                  onTap: () {
                    // Navigate to the Issue Details page, passing the document ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            IssueReportDetailsScreen(issueId: document.id),
                      ),
                    );
                  },
                );
              })
              .toList()
              .cast<Widget>(),
        );
      },
    );
  }

  /// Helper widget for the activity list items (Activity Card)
  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.home_work_outlined, color: kPrimaryBlue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: kSubTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryBlue,
                side: BorderSide(color: kLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}