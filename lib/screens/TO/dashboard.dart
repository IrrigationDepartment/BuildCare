// In screens/TO/dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Screen Imports ---
import 'manage_schools_screen.dart';
import 'issue_report_list_screen.dart';
import 'issue_report_details_screen.dart';
import 'contract_details.dart';
import 'contractor_list_screen.dart';
import 'view_details.dart'; 
import 'view_contractor_screen.dart'; 

// --- Settings Import ---
import 'settings.dart';

// ====================================================================
// DATA MODEL
// ====================================================================
class RecentActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime timestamp;
  final String type; 

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
// MAIN WIDGET
// ====================================================================

class TODashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const TODashboard({super.key, required this.userData});

  @override
  State<TODashboard> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<TODashboard> {
  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kLightBlue = Color(0xFFE3F2FD); 
  static const Color kBackgroundColor = Color(0xFFF5F7FA); 
  static const Color kCardColor = Colors.white;
  static const Color kHeaderGrey = Color(0xFFF0F2F5); 
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  int _selectedIndex = 0;
  late Future<List<RecentActivityItem>> _recentActivitiesFuture;

  @override
  void initState() {
    super.initState();
    _recentActivitiesFuture = _fetchRecentActivities();
  }

  // Refresh function to reload data when pulling down or returning to screen
  Future<void> _refreshData() async {
    setState(() {
      _recentActivitiesFuture = _fetchRecentActivities();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _goToHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  // ====================================================================
  // FIXED DATA FETCHING LOGIC
  // ====================================================================
  Future<List<RecentActivityItem>> _fetchRecentActivities() async {
    final String userNic = widget.userData['nic'] ?? '';
    List<RecentActivityItem> allActivities = [];
    final now = DateTime.now();

    debugPrint("Fetching activities for NIC: $userNic");

    // 1. Fetch Issues (Filtered by NIC)
    // Note: Removed .orderBy in Query to prevent Index Errors. We sort later.
    try {
      final issuesSnap = await FirebaseFirestore.instance
          .collection('issues')
          .where('addedByNic', isEqualTo: userNic)
          .get();

      for (var doc in issuesSnap.docs) {
        var data = doc.data();
        allActivities.add(RecentActivityItem(
          id: doc.id,
          title: "${data['schoolName'] ?? 'School'} - ${data['issueTitle'] ?? 'Issue'}",
          subtitle: "${data['location'] ?? 'No Location'} - ${data['status'] ?? 'Pending'}",
          icon: Icons.home_work_outlined, 
          // Safety check: If timestamp is null, use current time so it doesn't crash
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? now,
          type: 'issue',
        ));
      }
      debugPrint("Issues found: ${issuesSnap.docs.length}");
    } catch (e) { 
      debugPrint("Error fetching issues: $e"); 
    }

    // 2. Fetch Schools (Filtered by NIC)
    try {
      final schoolsSnap = await FirebaseFirestore.instance
          .collection('schools')
          .where('addedByNic', isEqualTo: userNic)
          .get();

      for (var doc in schoolsSnap.docs) {
        var data = doc.data();
        allActivities.add(RecentActivityItem(
          id: doc.id,
          title: data['schoolName'] ?? 'Unnamed School',
          subtitle: data['schoolAddress'] ?? 'No Address',
          icon: Icons.school, 
          timestamp: (data['addedAt'] as Timestamp?)?.toDate() ?? now,
          type: 'school',
        ));
      }
      debugPrint("Schools found: ${schoolsSnap.docs.length}");
    } catch (e) { 
      debugPrint("Error fetching schools: $e"); 
    }

    // 3. Fetch Contracts (All)
    try {
      final contractsSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .limit(20) // Limit to 20 to prevent loading too much
          .get();

      for (var doc in contractsSnap.docs) {
        var data = doc.data();
        allActivities.add(RecentActivityItem(
          id: doc.id,
          title: data['contractorName'] ?? 'Unknown Contractor',
          subtitle: "Contract: ${data['typeOfContract'] ?? 'N/A'}",
          icon: Icons.description, 
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? now,
          type: 'contract',
        ));
      }
    } catch (e) { 
      debugPrint("Error fetching contracts: $e"); 
    }

    // 4. Fetch Contractors (All)
    try {
      final contractorsSnap = await FirebaseFirestore.instance
          .collection('contractor_details')
          .limit(20)
          .get();

      for (var doc in contractorsSnap.docs) {
        var data = doc.data();
        allActivities.add(RecentActivityItem(
          id: doc.id,
          title: data['companyName'] ?? 'Unknown Company',
          subtitle: "Contractor: ${data['contractorName'] ?? 'N/A'}",
          icon: Icons.business_center, 
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? now,
          type: 'contractor',
        ));
      }
    } catch (e) { 
      debugPrint("Error fetching contractors: $e"); 
    }

    // 5. MERGE AND SORT (Client Side)
    // This ensures the newest items are at the top, regardless of where they came from
    allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Return only the top 5 most recent
    return allActivities.take(5).toList();
  }

  // ====================================================================
  // NAVIGATION HELPER
  // ====================================================================
  void _navigateToDetails(String type, String id) {
     Widget? page;
    switch (type) {
      case 'issue':
        page = IssueReportDetailsScreen(issueId: id, userNic: widget.userData['nic'] ?? '');
        break;
      case 'contract':
        page = ViewContractDetailsScreen(contractId: id);
        break;
      case 'contractor':
        page = ViewContractorScreen(contractorId: id);
        break;
      case 'school':
        page = ManageSchoolsScreen(userNic: widget.userData['nic'] ?? '');
        break;
    }
    if (page != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
    }
  }

  // ====================================================================
  // BUILD METHOD
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    
    if (_selectedIndex == 0) {
      bodyContent = _buildDashboardHome();
    } else if (_selectedIndex == 1) {
      bodyContent = const Center(child: Text("Profile Page Coming Soon"));
    } else {
      bodyContent = SettingsScreen(onBackTap: _goToHome);
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      body: bodyContent,
    );
  }
  
  Widget _buildDashboardHome() {
    return SafeArea(
      child: RefreshIndicator( // Added Pull-to-Refresh
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                const Text(
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
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ManageSchoolsScreen(userNic: widget.userData['nic'] ?? ''),
            )).then((_) => _refreshData()); // Refresh when coming back
          },
        ),
        _buildMenuCard(
          icon: Icons.assessment,
          title: 'Issues Report',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => IssueReportListScreen(userNic: widget.userData['nic'] ?? ''),
            )).then((_) => _refreshData());
          },
        ),
        _buildMenuCard(
          icon: Icons.description,
          title: 'Contract Details',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const ContractDetailsScreen(),
            )).then((_) => _refreshData());
          },
        ),
        _buildMenuCard(
          icon: Icons.business_center,
          title: 'Contractor Details',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const ContractorListScreen(),
            )).then((_) => _refreshData());
          },
        ),
      ],
    );
  }

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
              style: const TextStyle(
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

  Widget _buildRecentActivityHeader() {
    return const Row(
      children: [
        Icon(Icons.history, color: kSubTextColor),
        SizedBox(width: 8),
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

  Widget _buildRecentActivitySection() {
    return FutureBuilder<List<RecentActivityItem>>(
      future: _recentActivitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Show detailed error in UI for easier debugging
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No recent activity found.\nCreate a school or report an issue to see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kSubTextColor),
                ),
              ],
            ),
          );
        }
        final activities = snapshot.data!;
        return Column(
          children: activities.map((activity) {
            return _buildActivityCard(
              title: activity.title,
              subtitle: activity.subtitle,
              icon: activity.icon,
              onTap: () {
                _navigateToDetails(activity.type, activity.id);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required IconData icon,
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
            Icon(icon, color: kPrimaryBlue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
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
                    style: const TextStyle(
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
                side: const BorderSide(color: kLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}