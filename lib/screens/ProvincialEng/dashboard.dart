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
import 'schools_directory.dart'; // <-- ADDED: Import for the all schools/directory page

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
class ProvincialEngDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProvincialEngDashboard({super.key, this.userData});

  @override
  State<ProvincialEngDashboard> createState() =>
      _ProvincialEngineerDashboardState();
}

class _ProvincialEngineerDashboardState extends State<ProvincialEngDashboard> {
  late final Stream<List<ActivityItem>> _activityStream;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        .map((snapshot) => snapshot.docs.map((doc) {
              return ActivityItem(
                snapshot: doc,
                itemType: 'issue',
                timestamp: _safeExtractTimestamp(doc, 'timestamp'),
              );
            }).toList());

    Stream<List<ActivityItem>> schoolsStream = _firestore
        .collection('schools')
        .orderBy('addedAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return ActivityItem(
                snapshot: doc,
                itemType: 'school',
                timestamp: _safeExtractTimestamp(doc, 'addedAt'),
              );
            }).toList());

    Stream<List<ActivityItem>> usersStream = _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return ActivityItem(
                snapshot: doc,
                itemType: 'user',
                timestamp: _safeExtractTimestamp(doc, 'createdAt'),
              );
            }).toList());

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

  void _navigateToDetailPage(BuildContext context, ActivityItem item) {
    final data = item.snapshot.data() as Map<String, dynamic>;
    final docId = item.snapshot.id;

    switch (item.itemType) {
      case 'issue':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => IssueDetailPage(issueId: docId)));
        break;
      case 'school':
        // Note: You can replace this basic SchoolDetailPage with the new one
        // from schools_directory.dart if you want consistent UI. 
        // For now, it uses the local one defined at the bottom.
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    SchoolDetailPage(schoolId: docId, schoolData: data)));
        break;
      case 'user':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    UserDetailPage(userId: docId, userData: data)));
        break;
      default:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Details'),
            content: Text('Details for ${item.itemType}'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBackgroundColor = Color(0xFFF4F6F8);
    double screenWidth = MediaQuery.of(context).size.width;
    int gridCrossAxisCount =
        screenWidth > 1000 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardHeader(userData: widget.userData),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionTitle('User Management'),
                      const SizedBox(height: 16),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCount,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          mainAxisExtent: 240,
                        ),
                        children: const <Widget>[
                          UserCountBuilder(
                            title: 'Chief Engineer',
                            userType: 'Chief Engineer',
                            addPage: ChiefEngRegistrationPage(),
                            icon: Icons.engineering_outlined,
                            color: Colors.blue,
                          ),
                          UserCountBuilder(
                            title: 'District Engineer',
                            userType: 'District Engineer',
                            addPage: DistrictEngRegistrationPage(),
                            icon: Icons.map_outlined,
                            color: Colors.green,
                          ),
                          UserCountBuilder(
                            title: 'Technical Officer',
                            userType: 'Technical Officer',
                            addPage: TORegistrationPage(),
                            icon: Icons.handyman_outlined,
                            color: Colors.orange,
                          ),
                          UserCountBuilder(
                            title: 'Principals',
                            userType: 'Principal',
                            addPage: PrincipalRegistrationPage(),
                            icon: Icons.school_outlined,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Project Management'),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            return Row(
                              children: [
                                Expanded(child: _buildContractorCard(context)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildContractCard(context)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildContractorCard(context),
                                const SizedBox(height: 16),
                                _buildContractCard(context),
                                const SizedBox(height: 16),
                                // --- ADDED: Schools Directory Card ---
                                _buildSchoolsDirectoryCard(context), 
                              ],
                            );
                          }
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      // --- Analytics Section ---
                      _buildSectionTitle('Analytics & Reports'),
                      const SizedBox(height: 16),
                      _buildAnalyticsCard(context),

                      const SizedBox(height: 32),
                      _buildSectionTitle('System Alerts'),
                      const SizedBox(height: 16),
                      const IssueCountBuilder(title: 'Manage Issues'),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Latest Updates'),
                      const SizedBox(height: 16),
                      _buildLatestUpdates(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  // --- ADDED: Card specifically for routing to All Schools Page ---
  Widget _buildSchoolsDirectoryCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllSchoolsPage()), 
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.account_balance, color: Colors.blue, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('School Directory',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('View all schools, profiles, and master plans',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SchoolAnalysisPage()), 
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.analytics_outlined, color: Colors.deepPurple, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('School Analysis',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('View detailed school performance and comparisons',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContractorCard(BuildContext context) {
    return SimpleCountCard(
      title: 'Contractors',
      collectionName: 'contractor_details',
      icon: Icons.construction,
      color: Colors.teal,
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ContractorsListPage()));
      },
      onAdd: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddContractorScreen()));
      },
    );
  }

  Widget _buildContractCard(BuildContext context) {
    return SimpleCountCard(
      title: 'Contracts',
      collectionName: 'contracts',
      icon: Icons.description_outlined,
      color: Colors.indigo,
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ContractListPage()));
      },
      onAdd: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddContractScreen()));
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLatestUpdates() {
    return StreamBuilder<List<ActivityItem>>(
      stream: _activityStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200)),
            child: Text('Error loading updates: ${snapshot.error}',
                style: TextStyle(color: Colors.red.shade700)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(30),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)),
            child: const Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No recent updates found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        final latestActivities = snapshot.data!;
        return Column(
          children: latestActivities.map((item) {
            return ActivityItemCard(
              item: item,
              onTap: () => _navigateToDetailPage(context, item),
            );
          }).toList(),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// --- DashboardHeader ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const DashboardHeader({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final String userName = userData?['name'] ?? 'Engineer';
    final String userRole = userData?['userType'] ?? 'Provincial Dashboard';
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        image: DecorationImage(
          image: const NetworkImage(
              'https://www.transparenttextures.com/patterns/cubes.png'),
          colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.1), BlendMode.dstATop),
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String? imageUrl;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      imageUrl = data['profile_image'];
                    }
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.blue.shade200,
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? NetworkImage(imageUrl)
                                : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 40)
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,',
                          style: TextStyle(
                              color: Colors.blue.shade100, fontSize: 16)),
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(userRole,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                if (snapshot.hasData) {
                  unreadCount = snapshot.data!.docs.length;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_active_outlined,
                          color: Colors.blue.shade800),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotificationPage()),
                        );
                      },
                      tooltip: 'Notifications',
                    ),
                    
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5), 
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- UserCountBuilder ---
// -----------------------------------------------------------------------------
class UserCountBuilder extends StatelessWidget {
  final String userType;
  final String title;
  final Widget addPage;
  final IconData icon;
  final MaterialColor color;

  const UserCountBuilder({
    super.key,
    required this.userType,
    required this.title,
    required this.addPage,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: userType)
          .snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int active = 0;
        int pending = 0;

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

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            UserListPage(userType: userType, title: title)));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: color.shade50, shape: BoxShape.circle),
                      child: Icon(icon, size: 26, color: color.shade700),
                    ),
                    Text(
                      total.toString(),
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusBadge(active, Colors.green, 'Active'),
                          const SizedBox(width: 6),
                          _buildStatusBadge(pending, Colors.orange, 'Pending'),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => addPage));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: color.shade200),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 16, color: color.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Add New',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: color.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(int count, Color badgeColor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(
            "$count $label",
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- SimpleCountCard ---
// -----------------------------------------------------------------------------
class SimpleCountCard extends StatelessWidget {
  final String title;
  final String collectionName;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const SimpleCountCard({
    super.key,
    required this.title,
    required this.collectionName,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) count = snapshot.data!.docs.length.toString();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                          const SizedBox(height: 4),
                          Text(count,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: Icon(Icons.add_circle, color: color, size: 32),
                        onPressed: onAdd,
                        tooltip: 'Add $title'),
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
// --- ActivityItemCard ---
// -----------------------------------------------------------------------------
class ActivityItemCard extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback onTap;

  const ActivityItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final data = item.snapshot.data() as Map<String, dynamic>;

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    switch (item.itemType) {
      case 'issue':
        icon = Icons.warning_rounded;
        iconColor = Colors.orange;
        title = '${data['schoolName'] ?? 'Unknown'} - Issue';
        subtitle = '${data['issueTitle'] ?? 'No Title'}';
        break;
      case 'school':
        icon = Icons.domain;
        iconColor = Colors.blue;
        title = data['schoolName'] ?? 'New School';
        subtitle = 'Added to zone: ${data['educationalZone'] ?? 'Unknown'}';
        break;
      case 'user':
        icon = Icons.person_add_alt_1;
        iconColor = Colors.green;
        title = data['name'] ?? 'New User';
        subtitle = 'Role: ${data['userType'] ?? data['role'] ?? 'N/A'}';
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        title = 'Activity';
        subtitle = 'Update received';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatTimeAgo(item.timestamp),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}y ago';
    if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}mo ago';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}

// -----------------------------------------------------------------------------
// --- IssueCountBuilder ---
// -----------------------------------------------------------------------------
class IssueCountBuilder extends StatelessWidget {
  final String title;
  const IssueCountBuilder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('issues').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        if (snapshot.hasData) total = snapshot.data!.docs.length;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.red.shade50, Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ViewIssuesPage(currentUserNic: FirebaseAuth.instance.currentUser?.uid ?? '')));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.red.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.warning_amber_rounded,
                          color: Colors.red.shade700, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text('$total issues need attention',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('View All',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
// --- CustomBottomNavBar ---
// -----------------------------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade800,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => _onTabTapped(context, index),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    if (currentIndex == index) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const ProvincialEngDashboard();
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
          (route) => false);
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => destination));
    }
  }
}

// -----------------------------------------------------------------------------
// --- LOCAL DETAIL PAGES FOR ACTIVITY FEED FALLBACK ---
// -----------------------------------------------------------------------------
class IssueDetailPage extends StatelessWidget {
  final String issueId;
  const IssueDetailPage({super.key, required this.issueId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Issue Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Issue not found'));
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['issueTitle'] ?? 'No Title',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('School: ${data['schoolName'] ?? 'Unknown'}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Text(data['description'] ?? 'No description available',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SchoolDetailPage extends StatelessWidget {
  final String schoolId;
  final Map<String, dynamic> schoolData;
  const SchoolDetailPage(
      {super.key, required this.schoolId, required this.schoolData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("School Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schoolData['schoolName'] ?? 'Unknown School',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDetailRow(
                    'Zone:', schoolData['educationalZone'] ?? 'N/A'),
                _buildDetailRow('Address:', schoolData['address'] ?? 'N/A'),
                _buildDetailRow(
                    'Contact:', schoolData['contactNumber'] ?? 'N/A'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class UserDetailPage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  const UserDetailPage(
      {super.key, required this.userId, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: userData['profile_image'] != null
                        ? NetworkImage(userData['profile_image']!)
                        : null,
                    child: userData['profile_image'] == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                    child: Text(userData['name'] ?? 'Unknown User',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                _buildDetailRow('User Type:', userData['userType'] ?? 'N/A'),
                _buildDetailRow('Email:', userData['email'] ?? 'N/A'),
                _buildDetailRow('Status:',
                    userData['isActive'] == true ? 'Active' : 'Inactive'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}