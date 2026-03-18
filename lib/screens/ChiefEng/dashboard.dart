import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

// --- PAGE IMPORTS ---
import 'view_issues.dart';
import 'contractors_list.dart';
import 'contract_list.dart';
import 'notifications.dart'; 
import 'school_analysis.dart'; 
import 'schools_directory.dart'; 

// --- REGISTRATION PAGE IMPORTS ---
import 'add_ce.dart';
import 'add_de.dart';
import 'add_to.dart';
import 'add_principal.dart';
import 'add_contractor_screen.dart';
import 'add_contract.dart';
import 'profile_management.dart';
import 'app_settings.dart';

import 'user_management/user_list_page.dart';

// -----------------------------------------------------------------------------
// --- HELPER CLASS: ActivityItem ---
// -----------------------------------------------------------------------------
class ActivityItem {
  final DocumentSnapshot snapshot;
  final String itemType;
  final DateTime timestamp;

  ActivityItem({
    required this.snapshot,
    required this.itemType,
    required this.timestamp,
  });
}

// -----------------------------------------------------------------------------
// --- Dashboard Screen (Main Dashboard) ---
// -----------------------------------------------------------------------------
class ChiefEngDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ChiefEngDashboard({super.key, this.userData});

  @override
  State<ChiefEngDashboard> createState() => _ChiefEngDashboardState();
}

class _ChiefEngDashboardState extends State<ChiefEngDashboard> {
  late final Stream<List<ActivityItem>> _activityStream;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ultra-modern background color (Soft airy blue/gray)
  final Color pageBackgroundColor = const Color(0xFFF3F6F9); 
  final Color textPrimary = const Color(0xFF111827); // Deep Charcoal

  @override
  void initState() {
    super.initState();
    _initializeActivityStream();
  }

  DateTime _safeExtractTimestamp(DocumentSnapshot doc, String fieldName) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey(fieldName) && data[fieldName] is Timestamp) {
        return (data[fieldName] as Timestamp).toDate();
      }
    } catch (e) {
      debugPrint('Error extracting timestamp: $e');
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _initializeActivityStream() {
    Stream<List<ActivityItem>> issuesStream = _firestore
        .collection('issues').orderBy('timestamp', descending: true).limit(5).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityItem(snapshot: doc, itemType: 'issue', timestamp: _safeExtractTimestamp(doc, 'timestamp'))).toList());

    Stream<List<ActivityItem>> schoolsStream = _firestore
        .collection('schools').orderBy('addedAt', descending: true).limit(5).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityItem(snapshot: doc, itemType: 'school', timestamp: _safeExtractTimestamp(doc, 'addedAt'))).toList());

    Stream<List<ActivityItem>> usersStream = _firestore
        .collection('users').orderBy('createdAt', descending: true).limit(5).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityItem(snapshot: doc, itemType: 'user', timestamp: _safeExtractTimestamp(doc, 'createdAt'))).toList());

    _activityStream = CombineLatestStream.list<List<ActivityItem>>([
      issuesStream, schoolsStream, usersStream,
    ]).map((List<List<ActivityItem>> allLists) {
      final List<ActivityItem> combinedList = allLists.expand((list) => list).toList();
      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return combinedList.take(5).toList();
    }).shareValue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Floating Clean Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: DashboardHeader(userData: widget.userData),
                  ),
                ),
              ),
            ),
            
            // Bento Box Style Main Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // --- 1. SYSTEM ALERTS (Top priority, full width) ---
                        const IssueCountBuilder(title: 'Critical Issues'),
                        const SizedBox(height: 32),

                        _buildSectionTitle('Staff Overview'),
                        const SizedBox(height: 16),

                        // --- 2. USER STATS (Dark gradient bento cards) ---
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double width = constraints.maxWidth;
                            double itemWidth = width > 900 ? (width - 40) / 3 : (width > 600 ? (width - 20) / 2 : width);
                            return Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: [
                                SizedBox(width: itemWidth, child: _buildPremiumStatCard('District Engineer', 'District Engineer', const DistrictEngRegistrationPage(), const Color(0xFF0F2027), const Color(0xFF203A43))),
                                SizedBox(width: itemWidth, child: _buildPremiumStatCard('Technical Officer', 'Technical Officer', const TORegistrationPage(), const Color(0xFFF2994A), const Color(0xFFF2C94C))),
                                SizedBox(width: itemWidth, child: _buildPremiumStatCard('Principals', 'Principal', const PrincipalRegistrationPage(), const Color(0xFF4A00E0), const Color(0xFF8E2DE2))),
                              ],
                            );
                          }
                        ),

                        const SizedBox(height: 40),
                        _buildSectionTitle('Workspace'),
                        const SizedBox(height: 16),

                        // --- 3. QUICK ACTIONS (White floating tiles) ---
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double width = constraints.maxWidth;
                            double itemWidth = width > 900 ? (width - 40) / 3 : (width > 600 ? (width - 20) / 2 : width);
                            return Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: [
                                SizedBox(width: itemWidth, child: _buildActionTile('Contractors', 'contractor_details', Icons.architecture_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractorsListPage())))),
                                SizedBox(width: itemWidth, child: _buildActionTile('Contracts', 'contracts', Icons.description_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractListPage())))),
                                SizedBox(width: itemWidth, child: _buildSimpleActionTile('School Directory', 'View Master Plans', Icons.account_balance_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllSchoolsPage())))),
                                SizedBox(width: itemWidth, child: _buildSimpleActionTile('Analytics', 'Data & Reports', Icons.pie_chart_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SchoolAnalysisPage())))),
                              ],
                            );
                          }
                        ),

                        const SizedBox(height: 60), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -1.0),
    );
  }

  // A sleek, borderless tile for standard routing (Analytics, Directory)
  Widget _buildSimpleActionTile(String title, String subtitle, IconData icon, MaterialColor color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(24)),
                  child: Icon(icon, color: color.shade600, size: 32),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Action Tile with Count (Contracts, Contractors)
  Widget _buildActionTile(String title, String collectionName, IconData icon, MaterialColor color, VoidCallback onTap) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(24)),
                      child: Icon(icon, color: color.shade600, size: 32),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                          Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade300),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Premium Dark Gradient Stat Cards (User Counts)
  Widget _buildPremiumStatCard(String title, String userType, Widget addPage, Color colorStart, Color colorEnd) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('userType', isEqualTo: userType).snapshots(),
      builder: (context, snapshot) {
        int total = 0, active = 0, pending = 0;
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isActive'] == true) active++; else pending++;
          }
        }

        return Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colorStart, colorEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: colorStart.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserListPage(userType: userType, title: title))),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('$active Active', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => addPage)),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(total.toString(), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0, letterSpacing: -2)),
                        const SizedBox(height: 8),
                        Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7), letterSpacing: 1.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// --- Modern Header (Clean, floating style with Dynamic Time) ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const DashboardHeader({super.key, this.userData});

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = userData?['name'] ?? 'Chief Engineer';
    final String userRole = userData?['userType'] ?? 'Dashboard';
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    final DateTime? userCreationTime = currentUser?.metadata.creationTime;

    Query notificationsQuery = FirebaseFirestore.instance.collection('notifications');
    if (userCreationTime != null) {
      notificationsQuery = notificationsQuery.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(userCreationTime));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getGreeting(), style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(userName, style: const TextStyle(color: Color(0xFF111827), fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
              const SizedBox(height: 4),
              Text(userRole, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ],
          ),
        ),
        
        Row(
          children: [
            // Floating Notification Bell
            Container(
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
              child: StreamBuilder<QuerySnapshot>(
                stream: notificationsQuery.snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData && currentUserId.isNotEmpty) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (!(data['readBy'] ?? []).contains(currentUserId)) unreadCount++;
                    }
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Color(0xFF111827), size: 28),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage())),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 4, top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFFF43F5E), shape: BoxShape.circle),
                            child: Text(unreadCount > 9 ? '9+' : unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Profile Pic
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
              builder: (context, snapshot) {
                String? imageUrl;
                if (snapshot.hasData && snapshot.data!.exists) imageUrl = (snapshot.data!.data() as Map<String, dynamic>)['profile_image'];
                return Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE0E7FF),
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                    child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.person, color: Color(0xFF4F46E5), size: 30) : null,
                  ),
                );
              },
            ),
          ],
        )
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// --- Issue Banner (Glowing, Attention-Grabbing) ---
// -----------------------------------------------------------------------------
class IssueCountBuilder extends StatelessWidget {
  final String title;
  const IssueCountBuilder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('issues').snapshots(),
      builder: (context, snapshot) {
        int total = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2), // Very soft rose
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewIssuesPage(currentUserNic: FirebaseAuth.instance.currentUser?.uid ?? ''))),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Color(0xFFF43F5E), shape: BoxShape.circle), // Rose 500
                      child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF881337))), // Rose 900
                          const SizedBox(height: 6),
                          Text('$total active reports require your attention.', style: const TextStyle(fontSize: 15, color: Color(0xFFBE123C), fontWeight: FontWeight.w500)), // Rose 700
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: const Text('Review', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// --- Minimalist Floating Bottom Nav Bar ---
// -----------------------------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24), // Makes it float
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Dark grey/black
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey.shade600,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) => _onTabTapped(context, index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    if (currentIndex == index) return;
    Widget destination;
    switch (index) {
      case 0: destination = const ChiefEngDashboard(); break;
      case 1: destination = const ProfileManagementPage(); break;
      case 2: destination = const SettingsScreen(); break;
      default: return;
    }
    if (index == 0) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => destination), (route) => false);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
    }
  }
}

// --- LOCAL DETAIL PAGES FOR ACTIVITY FEED FALLBACK (Unchanged layout needed here) ---
class IssueDetailPage extends StatelessWidget {
  final String issueId;
  const IssueDetailPage({super.key, required this.issueId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Issue Details")), body: const Center(child: Text("Issue details placeholder")));
  }
}

class SchoolDetailPage extends StatelessWidget {
  final String schoolId;
  final Map<String, dynamic> schoolData;
  const SchoolDetailPage({super.key, required this.schoolId, required this.schoolData});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("School Details")), body: const Center(child: Text("School details placeholder")));
  }
}

class UserDetailPage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  const UserDetailPage({super.key, required this.userId, required this.userData});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("User Details")), body: const Center(child: Text("User details placeholder")));
  }
}