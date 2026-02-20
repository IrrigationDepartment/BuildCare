import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Screen Imports ---
import 'manage_schools_screen.dart';
import 'issue_report_list_screen.dart';
import 'issue_report_details_screen.dart';
import 'contract_details.dart';
import 'contractor_list_screen.dart';

// --- New Notification Import ---
import 'notification.dart';

// --- Settings & Profile Import ---
import 'app_settings.dart';
import 'profile.dart';

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
  // DATA FETCHING (Filtering by Role)
  // ====================================================================
  Future<List<RecentActivityItem>> _fetchRecentActivities() async {
    final String userNic = widget.userData['nic'] ?? '';
    final String userRole = widget.userData['userType'] ?? '';
    final String userOffice = widget.userData['office'] ?? '';
    
    List<RecentActivityItem> allActivities = [];
    final now = DateTime.now();

    try {
      Query issuesQuery = FirebaseFirestore.instance.collection('issues');
      
      if (userRole == 'District Engineer') {
        issuesQuery = issuesQuery.where('office', isEqualTo: userOffice);
      } else if (userRole == 'Principal') {
        issuesQuery = issuesQuery.where('addedByNic', isEqualTo: userNic);
      }
      
      final issuesSnap = await issuesQuery.get();
      for (var doc in issuesSnap.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          allActivities.add(RecentActivityItem(
            id: doc.id,
            title: "${data['schoolName'] ?? 'School'} - ${data['issueTitle'] ?? 'Issue'}",
            subtitle: "${data['location'] ?? 'No Location'} - ${data['status'] ?? 'Pending'}",
            icon: Icons.home_work_outlined,
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? now,
            type: 'issue',
          ));
        }
      }
    } catch (e) {
      debugPrint("Error fetching issues: $e");
    }

    try {
      Query schoolsQuery = FirebaseFirestore.instance.collection('schools');
      if (userRole == 'District Engineer') {
        schoolsQuery = schoolsQuery.where('educationalZone', isEqualTo: userOffice);
      } else if (userRole == 'Principal') {
        schoolsQuery = schoolsQuery.where('addedByNic', isEqualTo: userNic);
      }
      
      final schoolsSnap = await schoolsQuery.get();
      for (var doc in schoolsSnap.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          allActivities.add(RecentActivityItem(
            id: doc.id,
            title: data['schoolName'] ?? 'Unnamed School',
            subtitle: data['schoolAddress'] ?? 'No Address',
            icon: Icons.school,
            timestamp: (data['addedAt'] as Timestamp?)?.toDate() ?? now,
            type: 'school',
          ));
        }
      }
    } catch (e) {
      debugPrint("Error fetching schools: $e");
    }

    allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allActivities.take(5).toList();
  }

  void _navigateToDetails(String type, String id) {
    Widget? page;
    switch (type) {
      case 'issue':
        page = IssueReportDetailsScreen(issueId: id, userNic: widget.userData['nic'] ?? '');
        break;
      case 'school':
        page = ManageSchoolsScreen(userNic: widget.userData['nic'] ?? '');
        break;
    }
    if (page != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    if (_selectedIndex == 0) {
      bodyContent = _buildDashboardHome();
    } else if (_selectedIndex == 1) {
      bodyContent = const ProfilePage();
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
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
      body: bodyContent,
    );
  }

  Widget _buildDashboardHome() {
    return SafeArea(
      child: RefreshIndicator(
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

  // --- HEADER SECTION ---
  Widget _buildWelcomeHeader() {
    String userRole = widget.userData['userType'] ?? 'User';
    String userOffice = widget.userData['office'] ?? '';
    String displayRole = userRole;
    String userNic = widget.userData['nic'] ?? '';
    
    if (userRole == 'District Engineer' && userOffice.isNotEmpty) {
      displayRole = '$userRole - $userOffice District';
    }
    
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(displayRole, style: const TextStyle(fontSize: 16, color: kSubTextColor)),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 28, color: kTextColor),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen())),
              ),
              // මැන බලන Stream එක 'addedByNic' ලෙස යාවත්කාලීන කර ඇත
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .where('addedByNic', isEqualTo: userNic)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
                  
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${snapshot.data!.docs.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu() {
    String userRole = widget.userData['userType'] ?? '';
    List<Widget> menuItems = [
      _buildMenuCard(
          icon: Icons.school,
          title: 'Manage School',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageSchoolsScreen(userNic: widget.userData['nic'] ?? '')))),
      _buildMenuCard(
          icon: Icons.assessment,
          title: 'Issues Report',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IssueReportListScreen(userNic: widget.userData['nic'] ?? '')))),
    ];

    if (userRole == 'District Engineer' || userRole == 'Technical Officer') {
      menuItems.addAll([
        _buildMenuCard(icon: Icons.description, title: 'Contract Details', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractDetailsScreen()))),
        _buildMenuCard(icon: Icons.business_center, title: 'Contractor Details', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractorListScreen()))),
      ]);
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: menuItems,
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required VoidCallback onTap}) {
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
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextColor))
          ]
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader() {
    return const Row(children: [
      Icon(Icons.history, color: kSubTextColor),
      SizedBox(width: 8),
      Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor))
    ]);
  }

  Widget _buildRecentActivitySection() {
    return FutureBuilder<List<RecentActivityItem>>(
      future: _recentActivitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Column(children: [
              Icon(Icons.inbox, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('No recent activity found.', style: TextStyle(color: kSubTextColor))
            ]),
          );
        }
        return Column(
          children: snapshot.data!.map((activity) => _buildActivityCard(
            title: activity.title,
            subtitle: activity.subtitle,
            icon: activity.icon,
            onTap: () => _navigateToDetails(activity.type, activity.id),
          )).toList(),
        );
      },
    );
  }

  Widget _buildActivityCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryBlue, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: kSubTextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(foregroundColor: kPrimaryBlue, side: const BorderSide(color: kLightBlue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}