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
  // ====================================================================
  // EYE-CATCHING MODERN COLOR PALETTE
  // ====================================================================
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kPrimaryDark = Color(0xFF312E81); // Indigo 900
  static const Color kAccentColor = Color(0xFFEC4899); // Pink 500 (For badges)
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500

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
  // DATA FETCHING (Unchanged Logic)
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
            icon: Icons.home_work_rounded,
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
            icon: Icons.school_rounded,
            timestamp: (data['addedAt'] as Timestamp?)?.toDate() ?? now,
            type: 'school',
          ));
        }
      }
    } catch (e) {
      debugPrint("Error fetching schools: $e");
    }

    try {
      Query masterPlansQuery = FirebaseFirestore.instance.collection('schoolMasterPlans');
      if (userRole == 'Principal') {
        masterPlansQuery = masterPlansQuery.where('addedByNic', isEqualTo: userNic);
      }
      final masterPlansSnap = await masterPlansQuery.get();

      for (var doc in masterPlansSnap.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          allActivities.add(RecentActivityItem(
            id: doc.id,
            title: "Master Plan: ${data['schoolName'] ?? 'School'}",
            subtitle: "Uploaded on ${data['uploadDate'] ?? 'Unknown Date'}",
            icon: Icons.architecture_rounded,
            timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
            type: 'masterplan',
          ));
        }
      }
    } catch (e) {
      debugPrint("Error fetching master plans: $e");
    }

    allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allActivities.take(5).toList();
  }

  void _navigateToDetails(String type, String id) {
    Widget? page;
    switch (type) {
      case 'issue':
        page = IssueReportDetailsScreen(
            issueId: id, userNic: widget.userData['nic'] ?? '');
        break;
      case 'school':
        page = ManageSchoolsScreen(userNic: widget.userData['nic'] ?? '');
        break;
      case 'masterplan':
        page = ManageSchoolsScreen(userNic: widget.userData['nic'] ?? '');
        break;
    }
    if (page != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width >= 800;

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
      bottomNavigationBar: isLargeScreen
          ? null
          : Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: kPrimaryColor,
                unselectedItemColor: Colors.grey.shade400,
                onTap: _onItemTapped,
                backgroundColor: Colors.white,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
      body: isLargeScreen
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: kPrimaryColor),
                  unselectedIconTheme: IconThemeData(color: Colors.grey.shade400),
                  selectedLabelTextStyle: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  destinations: const [
                    NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Home')),
                    NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: Text('Profile')),
                    NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: Text('Settings')),
                  ],
                ),
                VerticalDivider(thickness: 1, width: 1, color: Colors.grey.shade200),
                Expanded(child: bodyContent),
              ],
            )
          : bodyContent,
    );
  }

  Widget _buildDashboardHome() {
    return SafeArea(
      child: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Quick Actions'),
                    const SizedBox(height: 16),
                    _buildGridMenu(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Recent Activity'),
                    const SizedBox(height: 16),
                    _buildRecentActivitySection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- STUNNING GRADIENT HEADER ---
  Widget _buildWelcomeHeader() {
    String userRole = widget.userData['userType'] ?? 'User';
    String userOffice = widget.userData['office'] ?? '';
    String displayRole = userRole;

    if (userRole == 'District Engineer' && userOffice.isNotEmpty) {
      displayRole = '$userRole - $userOffice District';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3), // Border width
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: kPrimaryDark,
              child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userData['name'] ?? 'User',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(displayRole,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      size: 26, color: Colors.white),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationScreen())),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .where('userId', isEqualTo: widget.userData['nic'] ?? '')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox();
                  }
                  return Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: kAccentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: kPrimaryDark, width: 2)),
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text('${snapshot.data!.docs.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
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

  // A reusable section title for consistency
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: kTextColor,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildGridMenu() {
    String userRole = widget.userData['userType'] ?? '';
    List<Widget> menuItems = [];

    menuItems.addAll([
      _buildMenuCard(
          icon: Icons.school_rounded,
          title: 'Manage\nSchool',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageSchoolsScreen(userNic: widget.userData['nic'] ?? '')))),
      _buildMenuCard(
          icon: Icons.assessment_rounded,
          title: 'Issues\nReport',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IssueReportListScreen(userNic: widget.userData['nic'] ?? '')))),
    ]);

    if (userRole == 'District Engineer' || userRole == 'Technical Officer') {
      menuItems.addAll([
        _buildMenuCard(
            icon: Icons.description_rounded,
            title: 'Contract\nDetails',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractDetailsScreen()))),
        _buildMenuCard(
            icon: Icons.business_center_rounded,
            title: 'Contractor\nDetails',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractorListScreen()))),
      ]);
    } else if (userRole == 'Principal') {
      menuItems.addAll([
        _buildMenuCard(
            icon: Icons.architecture_rounded,
            title: 'Master\nPlans',
            onTap: () {}),
        _buildMenuCard(
            icon: Icons.report_rounded,
            title: 'My\nReports',
            onTap: () {}),
      ]);
    }

    return GridView.extent(
      maxCrossAxisExtent: 180, // slightly narrower to look better on mobile
      childAspectRatio: 1.0, // perfect squares
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: menuItems,
    );
  }

  // --- MODERN GLASS/TINTED MENU CARDS ---
  Widget _buildMenuCard(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: kPrimaryColor.withOpacity(0.05),
          splashColor: kPrimaryColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: kPrimaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                    height: 1.2,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return FutureBuilder<List<RecentActivityItem>>(
      future: _recentActivitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(color: kPrimaryColor),
          ));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            width: double.infinity,
            decoration: BoxDecoration(
                color: kCardColor, 
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ]),
            child: Column(children: [
              Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('No recent activity found',
                  style: TextStyle(color: kSubTextColor, fontSize: 16, fontWeight: FontWeight.w500))
            ]),
          );
        }
        return Column(
          children: snapshot.data!
              .map((activity) => _buildActivityCard(
                    title: activity.title,
                    subtitle: activity.subtitle,
                    icon: activity.icon,
                    onTap: () => _navigateToDetails(activity.type, activity.id),
                  ))
              .toList(),
        );
      },
    );
  }

  // --- MODERN LIST TILES ---
  Widget _buildActivityCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: kPrimaryColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 13, color: kSubTextColor, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kPrimaryColor),
                    onPressed: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}