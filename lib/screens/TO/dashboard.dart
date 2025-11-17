// In screens/TO/dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Screen Imports ---
// Manage Schools and Add School
import 'manage_schools_screen.dart';
// Issue Reporting Screens
import 'issue_report_list_screen.dart';
import 'issue_report_details_screen.dart';
// Contract and Contractor Imports
import 'contract_details.dart';
import 'contractor_list_screen.dart';
// --- Import Details Screens for Navigation ---
import 'view_details.dart'; // For Contract details
import 'view_contractor_screen.dart'; // For Contractor details

// ====================================================================
// UNIFIED DATA MODEL FOR RECENT ACTIVITY
// ====================================================================
class RecentActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime timestamp;
  final String type; // 'issue', 'school', 'contract', 'contractor'

  RecentActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.timestamp,
    required this.type,
  });
}

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
  static const Color kLightBlue =
      Color(0xFFE3F2FD); // Light blue for button border
  static const Color kBackgroundColor =
      Color(0xFFF5F7FA); // Light grey background
  static const Color kCardColor = Colors.white;
  static const Color kHeaderGrey = Color(0xFFF0F2F5); // Header card background
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  // --- State ---
  int _selectedIndex = 0;
  late final Future<List<RecentActivityItem>> _recentActivitiesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the merged activity list when the widget is first built
    _recentActivitiesFuture = _fetchRecentActivities();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ====================================================================
  // DATA FETCHING (MERGED)
  // ====================================================================
  Future<List<RecentActivityItem>> _fetchRecentActivities() async {
    final String userNic = widget.userData['nic'] ?? '';
    List<RecentActivityItem> allActivities = [];
    final now = DateTime.now(); // Fallback timestamp

    // 1. Fetch Issues (filtered by user)
    try {
      final issuesSnap = await FirebaseFirestore.instance
          .collection('issues')
          .where('addedByNic', isEqualTo: userNic)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      for (var doc in issuesSnap.docs) {
        var data = doc.data();
        allActivities.add(RecentActivityItem(
          id: doc.id,
          title:
              "${data['schoolName'] ?? 'School'} - ${data['issueTitle'] ?? 'Issue'}",
          subtitle:
              "${data['location'] ?? 'No Location'} - Status: ${data['status'] ?? 'No Status'}",
          icon: Icons.home_work_outlined, // Icon from your image
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? now,
          type: 'issue',
        ));
      }
    } catch (e) {
      debugPrint("Error fetching issues: $e");
    }

    // 2. Fetch Schools (filtered by user)
    try {
      final schoolsSnap = await FirebaseFirestore.instance
          .collection('schools')
          .where('addedByNic', isEqualTo: userNic)
          .orderBy('addedAt', descending: true)
          .limit(5)
          .get();

      for (var doc in schoolsSnap.docs) {
        var data = doc.data();
        allActivities.add(RecentActivityItem(
          id: doc.id,
          title: data['schoolName'] ?? 'Unnamed School',
          subtitle: data['schoolAddress'] ?? 'No Address',
          icon: Icons.school, // Icon from your menu
          timestamp: (data['addedAt'] as Timestamp?)?.toDate() ?? now,
          type: 'school',
        ));
      }
    } catch (e) {
      debugPrint("Error fetching schools: $e");
    }

    // 3. Fetch Contracts (Global)
    try {
      final contractsSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      for (var doc in contractsSnap.docs) {
        var data = doc.data();
        allActivities.add(RecentActivityItem(
          id: doc.id,
          title: data['contractorName'] ?? 'Unknown Contractor',
          subtitle: "Contract: ${data['typeOfContract'] ?? 'N/A'}",
          icon: Icons.description, // Icon from your menu
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? now,
          type: 'contract',
        ));
      }
    } catch (e) {
      debugPrint("Error fetching contracts: $e");
    }

    // 4. Fetch Contractors (Global)
    try {
      final contractorsSnap = await FirebaseFirestore.instance
          .collection('contractor_details')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      for (var doc in contractorsSnap.docs) {
        var data = doc.data();
        allActivities.add(RecentActivityItem(
          id: doc.id,
          title: data['companyName'] ?? 'Unknown Company',
          subtitle: "Contractor: ${data['contractorName'] ?? 'N/A'}",
          icon: Icons.business_center, // Icon from your menu
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? now,
          type: 'contractor',
        ));
      }
    } catch (e) {
      debugPrint("Error fetching contractors: $e");
    }

    // 5. Sort all activities by date and take the top 5
    allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allActivities.take(5).toList();
  }

  // ====================================================================
  // NAVIGATION HELPER
  // ====================================================================
  void _navigateToDetails(String type, String id) {
    Widget? page;
    switch (type) {
      case 'issue':
        page = IssueReportDetailsScreen(
          issueId: id,
          userNic: widget.userData['nic'] ?? 'UNKNOWN_NIC',
        );
        break;
      case 'contract':
        page = ViewContractDetailsScreen(contractId: id);
        break;
      case 'contractor':
        page = ViewContractorScreen(contractorId: id);
        break;
      case 'school':
        // Placeholder: Navigates to the school list.
        // Replace with 'ViewSchoolScreen(schoolId: id)' when you build it.
        page = ManageSchoolsScreen(
            userNic: widget.userData['nic'] ?? 'UNKNOWN_NIC');
        debugPrint(
            "Navigate to school details for ID: $id (showing list as placeholder)");
        break;
      default:
        debugPrint("Unknown activity type: $type");
    }

    if (page != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page!),
      );
    }
  }

// ====================================================================
// BUILD METHOD
// ====================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
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
                // --- THIS IS THE NEW WIDGET ---
                _buildRecentActivitySection(),
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
        _buildMenuCard(
          icon: Icons.business_center,
          title: 'Contractor Details',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContractorListScreen(),
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

  // --- 4. NEW: Builds the merged activity list ---
  Widget _buildRecentActivitySection() {
    return FutureBuilder<List<RecentActivityItem>>(
      future: _recentActivitiesFuture, // Use the future defined in initState
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading activity: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No recent activities found.',
              style: TextStyle(color: kSubTextColor),
            ),
          );
        }

        // --- Data Loaded State ---
        final activities = snapshot.data!;
        return Column(
          children: activities.map((activity) {
            return _buildActivityCard(
              title: activity.title,
              subtitle: activity.subtitle,
              icon: activity.icon, // Pass the correct icon
              onTap: () {
                _navigateToDetails(activity.type, activity.id);
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// Helper widget for the activity list items (Activity Card)
  /// --- UPDATED to match screenshot ---
  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required IconData icon, // Accepts icon from the activity item
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
            Icon(icon, color: kPrimaryBlue, size: 28), // Use the passed icon
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: kSubTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
