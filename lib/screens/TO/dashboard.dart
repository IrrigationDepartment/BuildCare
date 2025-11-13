// In screens/TO/dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the new Manage Schools Screen
import 'manage_schools_screen.dart'; // <-- Correct import

// --- 1. IMPORT THE NEW ISSUE REPORT SCREEN ---
import 'issue_report_list_screen.dart';

// --- 2. THIS IS THE FIX ---
// This line was missing, causing the error on line 307
import 'issue_report_details_screen.dart'; 

class TODashboard extends StatefulWidget {
  // 3. --- RECEIVE USER DATA ---
  // This receives the data from the login page
  final Map<String, dynamic> userData;

  // 4. --- UPDATE THE CONSTRUCTOR ---
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
    // Add navigation logic here
    // if (index == 1) { /* Navigate to Profile */ }
    // if (index == 2) { /* Navigate to Settings */ }
  }

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
                _buildRecentActivityList(), // <-- Firebase StreamBuilder is here
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Welcome Header Widget (WITH OVERFLOW FIX) ---
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
                SizedBox(height: 4),
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

  // --- 2. Grid Menu Widget (WITH NAVIGATION) ---
  Widget _buildGridMenu() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMenuCard(
          icon: Icons.school,
          title: 'Manage School',
          onTap: () {
            // --- NAVIGATION LOGIC (CORRECTED) ---
            Navigator.push(
              context,
              MaterialPageRoute(
                // This now points to your new ManageSchoolsScreen
                builder: (context) => ManageSchoolsScreen(
                  // Pass the user's NIC to the next screen
                  userNic: widget.userData['nic'] ?? 'UNKNOWN_NIC',
                ),
              ),
            );
          },
        ),
        _buildMenuCard(
          icon: Icons.assessment, // Changed from settings_applications
          title: 'Issues Report',
          onTap: () {
            // --- 2. ADD NAVIGATION FOR ISSUES REPORT ---
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
        _buildMenuCard(
          icon: Icons.description,
          title: 'Contract Details',
          onTap: () {
            // TODO: Navigate to Contract Details page
            print('Contract Details tapped');
          },
        ),
        _buildMenuCard(
          icon: Icons.business_center,
          title: 'Contractor Details',
          onTap: () {
            // TODO: Navigate to Contractor Details page
            print('Contractor Details tapped');
          },
        ),
      ],
    );
  }

  // Helper widget for the grid items
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

  // --- 3. Recent Activity Header ---
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

  // --- 4. Recent Activity List (with Firebase) ---
  Widget _buildRecentActivityList() {
    // This stream is already set up for 'issues' which is perfect
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
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;

                String title = data['schoolName'] ?? 'Unknown School';
                String subtitle = data['issueTitle'] ?? 'No Title';
                String location = data['location'] ?? 'No Location';
                String status = data['status'] ?? 'No Status';

                return _buildActivityCard(
                  title: '$title - $subtitle',
                  subtitle: '$location - Status, $status',
                  onTap: () {
                    // --- 3. LINK RECENT ACTIVITY TO DETAILS PAGE ---
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            // This line is now fixed because of the import
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

  // Helper widget for the activity list items
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