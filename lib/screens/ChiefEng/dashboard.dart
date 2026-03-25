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
import 'add_de.dart';
import 'add_to.dart';
import 'add_principal.dart';
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

  final Color bgColor = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);

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
        .collection('issues')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ActivityItem(
                  snapshot: doc,
                  itemType: 'issue',
                  timestamp: _safeExtractTimestamp(doc, 'timestamp'),
                ),
              )
              .toList(),
        );

    Stream<List<ActivityItem>> schoolsStream = _firestore
        .collection('schools')
        .orderBy('addedAt', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ActivityItem(
                  snapshot: doc,
                  itemType: 'school',
                  timestamp: _safeExtractTimestamp(doc, 'addedAt'),
                ),
              )
              .toList(),
        );

    Stream<List<ActivityItem>> usersStream = _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ActivityItem(
                  snapshot: doc,
                  itemType: 'user',
                  timestamp: _safeExtractTimestamp(doc, 'createdAt'),
                ),
              )
              .toList(),
        );

    _activityStream = CombineLatestStream.list<List<ActivityItem>>([
      issuesStream,
      schoolsStream,
      usersStream,
    ]).map((List<List<ActivityItem>> allLists) {
      final List<ActivityItem> combinedList =
          allLists.expand((list) => list).toList();
      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return combinedList.take(5).toList();
    }).shareValue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: false,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // HEADER
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: DashboardHeader(userData: widget.userData),
                  ),
                ),
              ),
            ),

            // MAIN CONTENT GRIDS
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const IssueCountBuilder(title: 'Action Required'),
                        const SizedBox(height: 32),

                        _buildSectionTitle('Staff & Personnel'),
                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            double width = constraints.maxWidth;
                            double itemWidth =
                                width > 800 ? (width - 40) / 3 : width;

                            return Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: [
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildUnifiedStatCard(
                                    'District Engineer',
                                    'District Engineer',
                                    const DistrictEngRegistrationPage(),
                                    const Color(0xFF0EA5E9),
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildUnifiedStatCard(
                                    'Technical Officer',
                                    'Technical Officer',
                                    const TORegistrationPage(),
                                    const Color(0xFFF59E0B),
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildUnifiedStatCard(
                                    'Principals',
                                    'Principal',
                                    const PrincipalRegistrationPage(),
                                    const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 40),
                        _buildSectionTitle('Project Hub'),
                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            double width = constraints.maxWidth;
                            double itemWidth =
                                width > 800 ? (width - 60) / 4 : (width - 20) / 2;

                            return Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: [
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildActionTile(
                                    'Contractors',
                                    'contractor_details',
                                    Icons.engineering_rounded,
                                    const Color(0xFF10B981),
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ContractorsListPage(),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildActionTile(
                                    'Contracts',
                                    'contracts',
                                    Icons.description_rounded,
                                    const Color(0xFF3B82F6),
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ContractListPage(),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildSimpleActionTile(
                                    'Directory',
                                    Icons.corporate_fare_rounded,
                                    const Color(0xFF6366F1),
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AllSchoolsPage(),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildSimpleActionTile(
                                    'Analytics',
                                    Icons.insights_rounded,
                                    const Color(0xFFEC4899),
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SchoolAnalysisPage(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),
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
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textDark,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildCardContainer({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  Widget _buildUnifiedStatCard(
    String title,
    String userType,
    Widget addPage,
    Color accentColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: userType)
          .snapshots(),
      builder: (context, snapshot) {
        int total = 0, active = 0, pending = 0;
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isActive'] == true) {
              active++;
            } else {
              pending++;
            }
          }
        }

        return _buildCardContainer(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserListPage(
                userType: userType,
                title: title,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_rounded,
                        color: Colors.grey.shade300,
                        size: 32,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => addPage),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  total.toString(),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatusPill(active, 'Active', const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _buildStatusPill(
                      pending,
                      'Pending',
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String collectionName,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '-';
        return _buildCardContainer(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleActionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return _buildCardContainer(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 20),
            const Text(
              'View',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.transparent,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- Premium Header (Dynamic Time) ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const DashboardHeader({super.key, this.userData});

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final String userName = userData?['name'] ?? 'Chief Engineer';
    final String userRole = userData?['userType'] ?? 'System Dashboard';

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    final DateTime? userCreationTime = currentUser?.metadata.creationTime;

    Query notificationsQuery =
        FirebaseFirestore.instance.collection('notifications');
    if (userCreationTime != null) {
      notificationsQuery = notificationsQuery.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(userCreationTime),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                userName,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  userRole.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: notificationsQuery.snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData && currentUserId.isNotEmpty) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (!(data['readBy'] ?? []).contains(currentUserId)) {
                        unreadCount++;
                      }
                    }
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF0F172A),
                          size: 26,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationPage(),
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                String? imageUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  imageUrl = (snapshot.data!.data() as Map<String, dynamic>)['profile_image'];
                }
                return Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF94A3B8),
                            size: 24,
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// --- Alert Banner (Soft Red Unified Card) ---
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
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFECACA),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewIssuesPage(
                    currentUserNic: FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$total active reports require attention',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFEF4444),
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
// --- Bottom Navigation Bar (Screenshot Style) ---
// -----------------------------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.settings_rounded,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(context, index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF9CA3AF),
                ),
              ),
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
      case 0:
        destination = const ChiefEngDashboard();
        break;
      case 1:
        destination = const ProfileManagementPage();
        break;
      case 2:
        destination = const SettingsScreen();
        break;
      default:
        return;
    }

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => destination),
        (route) => false,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }
}

// --- LOCAL DETAIL PAGES FOR ACTIVITY FEED FALLBACK ---
class IssueDetailPage extends StatelessWidget {
  final String issueId;
  const IssueDetailPage({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Issue Details")),
      body: const Center(child: Text("Placeholder")),
    );
  }
}

class SchoolDetailPage extends StatelessWidget {
  final String schoolId;
  final Map<String, dynamic> schoolData;

  const SchoolDetailPage({
    super.key,
    required this.schoolId,
    required this.schoolData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("School Details")),
      body: const Center(child: Text("Placeholder")),
    );
  }
}

class UserDetailPage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),
      body: const Center(child: Text("Placeholder")),
    );
  }
}