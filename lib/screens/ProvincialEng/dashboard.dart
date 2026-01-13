import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

// --- PAGE IMPORTS ---
// Make sure these files exist in your project
import 'view_issues.dart';
import 'contractors_list.dart'; 
import 'contract_list.dart';

// --- REGISTRATION PAGE IMPORTS ---
import 'add_ce.dart';
import 'add_de.dart';
import 'add_to.dart';
import 'add_principal.dart';
import 'add_contractor_screen.dart';
import 'add_contract.dart';
import 'profile_management.dart';
import 'app_settings.dart';

// --- NEW NOTIFICATION IMPORT ---
import 'notification.dart';

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
  
  // --- Notification Badge Stream ---
  late Stream<int> _unreadNotificationsStream;

  @override
  void initState() {
    super.initState();
    _initializeActivityStream();
    _initializeNotificationStream();
  }

  void _initializeNotificationStream() {
    final String userNic = widget.userData?['nic'] ?? '';
    _unreadNotificationsStream = _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .where('userId', isEqualTo: userNic)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBackgroundColor = Color(0xFFF4F6F8);
    
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallMobile = screenWidth < 340; 
    final isSmallMobile = screenWidth < 380; 
    final isMediumMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        backgroundColor: pageBackgroundColor,
        toolbarHeight: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DashboardHeader(
                      userData: widget.userData,
                      unreadNotificationsStream: _unreadNotificationsStream,
                      isVerySmallMobile: isVerySmallMobile,
                      isSmallMobile: isSmallMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildSectionTitle('User Management', 
                      isVerySmallMobile: isVerySmallMobile, 
                      isSmallMobile: isSmallMobile
                    ),
                    _buildUserManagementGrid(
                      isVerySmallMobile: isVerySmallMobile,
                      isSmallMobile: isSmallMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildSectionTitle('Project Management', 
                      isVerySmallMobile: isVerySmallMobile, 
                      isSmallMobile: isSmallMobile
                    ),
                    _buildProjectManagementRow(
                      isVerySmallMobile: isVerySmallMobile,
                      isSmallMobile: isSmallMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildSectionTitle('System Alerts', 
                      isVerySmallMobile: isVerySmallMobile, 
                      isSmallMobile: isSmallMobile
                    ),
                    _buildSystemAlertsCard(
                      isVerySmallMobile: isVerySmallMobile,
                      isSmallMobile: isSmallMobile,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildUserManagementGrid({
    required bool isVerySmallMobile,
    required bool isSmallMobile,
  }) {
    final users = [
      {
        'title': 'Chief Engineer',
        'userType': 'Chief Engineer',
        'addPage': const ChiefEngRegistrationPage(),
        'icon': Icons.person_pin,
        'color': Colors.blue,
      },
      {
        'title': 'District Engineer',
        'userType': 'District Engineer',
        'addPage': const DistrictEngRegistrationPage(),
        'icon': Icons.engineering,
        'color': Colors.green,
      },
      {
        'title': 'Technical Officer',
        'userType': 'Technical Officer',
        'addPage': const TORegistrationPage(),
        'icon': Icons.build,
        'color': Colors.orange,
      },
      {
        'title': 'Principals',
        'userType': 'Principal',
        'addPage': const PrincipalRegistrationPage(),
        'icon': Icons.school,
        'color': Colors.purple,
      },
      // --- SCHOOLS CARD ---
      {
        'title': 'Schools',
        'userType': 'school',
        'addPage': null,
        'icon': Icons.location_city,
        'color': Colors.brown,
        'collectionName': 'schools',
        'customRoute': (BuildContext context) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Registered Schools'),
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                ),
                body: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('schools').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No schools found."));
                    }
                    final schools = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: schools.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final data = schools[index].data() as Map<String, dynamic>;
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.brown.shade100,
                              child: const Icon(Icons.school, color: Colors.brown),
                            ),
                            title: Text(
                              data['schoolName'] ?? data['name'] ?? 'Unknown School',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(data['address'] ?? data['district'] ?? 'No Address'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallMobile ? 6.0 : 
                   isSmallMobile ? 8.0 : 12.0,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isVerySmallMobile ? 1 : 2,
          crossAxisSpacing: isVerySmallMobile ? 6.0 : 
                          isSmallMobile ? 8.0 : 12.0,
          mainAxisSpacing: isVerySmallMobile ? 6.0 : 
                         isSmallMobile ? 8.0 : 12.0,
          childAspectRatio: isVerySmallMobile ? 2.5 : 1.8,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return CompactUserCard(
            title: user['title'] as String,
            userType: user['userType'] as String,
            addPage: user['addPage'] as Widget?,
            icon: user['icon'] as IconData,
            color: user['color'] as Color,
            collectionName: user.containsKey('collectionName') ? user['collectionName'] as String? : null,
            onCustomTap: user.containsKey('customRoute') ? user['customRoute'] as Function(BuildContext)? : null,
            isVerySmallMobile: isVerySmallMobile,
            isSmallMobile: isSmallMobile,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // --- PROJECT MANAGEMENT ROW (Updated for Contractors Count) ---
  // ---------------------------------------------------------------------------
  Widget _buildProjectManagementRow({
    required bool isVerySmallMobile,
    required bool isSmallMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallMobile ? 6.0 : 
                   isSmallMobile ? 8.0 : 12.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: CompactProjectCard(
              title: 'Contractors',
              // Matches collection in add_contractor_screen.dart
              collectionName: 'contractor_details', 
              icon: Icons.engineering,
              color: Colors.teal.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContractorsListPage(),
                  ),
                );
              },
              onAdd: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddContractorScreen(),
                  ),
                );
              },
              isVerySmallMobile: isVerySmallMobile,
              isSmallMobile: isSmallMobile,
            ),
          ),
          SizedBox(width: isVerySmallMobile ? 6.0 : 
                     isSmallMobile ? 8.0 : 10.0),
          Expanded(
            child: CompactProjectCard(
              title: 'Contracts',
              // Matches collection in add_contract.dart
              collectionName: 'contracts',
              icon: Icons.description,
              color: Colors.indigo.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContractListPage(),
                  ),
                );
              },
              onAdd: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddContractScreen(),
                  ),
                );
              },
              isVerySmallMobile: isVerySmallMobile,
              isSmallMobile: isSmallMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAlertsCard({
    required bool isVerySmallMobile,
    required bool isSmallMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallMobile ? 6.0 : 
                   isSmallMobile ? 8.0 : 12.0,
      ),
      child: CompactSystemAlertsCard(
        title: 'Manage Issues',
        isVerySmallMobile: isVerySmallMobile,
        isSmallMobile: isSmallMobile,
      ),
    );
  }

  Widget _buildSectionTitle(String title, {
    required bool isVerySmallMobile, 
    required bool isSmallMobile
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isVerySmallMobile ? 8.0 : 
        isSmallMobile ? 10.0 : 12.0,
        0,
        isVerySmallMobile ? 8.0 : 
        isSmallMobile ? 10.0 : 12.0,
        6.0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isVerySmallMobile ? 14 : 
                   isSmallMobile ? 16 : 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D3436),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- DashboardHeader (Compact Version) ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Stream<int> unreadNotificationsStream;
  final bool isVerySmallMobile;
  final bool isSmallMobile;
  
  const DashboardHeader({
    super.key, 
    this.userData,
    required this.unreadNotificationsStream,
    required this.isVerySmallMobile,
    required this.isSmallMobile,
  });

  @override
  Widget build(BuildContext context) {
    final String userName = userData?['name'] ?? 'Engineer';
    final String userRole = userData?['userType'] ?? 'Provincial Dashboard';
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isVerySmallMobile ? 12.0 : 14.0,
        isVerySmallMobile ? 25.0 : 30.0,
        isVerySmallMobile ? 12.0 : 14.0,
        isVerySmallMobile ? 12.0 : 16.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isVerySmallMobile ? 16 : 20),
          bottomRight: Radius.circular(isVerySmallMobile ? 16 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              String? imageUrl;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                imageUrl = data['profile_image'];
              }
              return CircleAvatar(
                radius: isVerySmallMobile ? 20 : 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                    ? NetworkImage(imageUrl)
                    : null,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? Icon(
                        Icons.person,
                        color: Colors.white,
                        size: isVerySmallMobile ? 22 : 26,
                      )
                    : null,
              );
            },
          ),
          SizedBox(width: isVerySmallMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome, $userName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isVerySmallMobile ? 14 : 
                             isSmallMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userRole,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isVerySmallMobile ? 10 : 
                             isSmallMobile ? 12 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: isVerySmallMobile ? 18 : 20,
                  ),
                  padding: EdgeInsets.all(isVerySmallMobile ? 6 : 8),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                right: -3,
                top: -3,
                child: StreamBuilder<int>(
                  stream: unreadNotificationsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == 0) {
                      return const SizedBox();
                    }
                    return Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: isVerySmallMobile ? 12 : 14,
                        minHeight: isVerySmallMobile ? 12 : 14,
                      ),
                      child: Text(
                        '${snapshot.data! > 9 ? '9+' : snapshot.data}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isVerySmallMobile ? 7 : 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- COMPACT WIDGETS ---
// -----------------------------------------------------------------------------
class CompactUserCard extends StatelessWidget {
  final String userType;
  final String title;
  final Widget? addPage;
  final IconData icon;
  final Color color;
  final bool isVerySmallMobile;
  final bool isSmallMobile;
  final String? collectionName;
  final Function(BuildContext)? onCustomTap;

  const CompactUserCard({
    super.key,
    required this.userType,
    required this.title,
    this.addPage,
    required this.icon,
    required this.color,
    required this.isVerySmallMobile,
    required this.isSmallMobile,
    this.collectionName,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> getStream() {
      if (collectionName != null) {
        return FirebaseFirestore.instance.collection(collectionName!).snapshots();
      } else {
        return FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: userType)
          .snapshots();
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: getStream(),
      builder: (context, snapshot) {
        int total = 0;
        int active = 0;
        int pending = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (collectionName != null) {
               active++;
            } else {
              if (data['isActive'] == true) {
                active++;
              } else {
                pending++;
              }
            }
          }
        }

        return Container(
          height: isVerySmallMobile ? 60 : 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (onCustomTap != null) {
                  onCustomTap!(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserListPage(
                        userType: userType,
                        title: title,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: EdgeInsets.all(isVerySmallMobile ? 6.0 : 8.0),
                child: Row(
                  children: [
                    Container(
                      width: isVerySmallMobile ? 30 : 36,
                      height: isVerySmallMobile ? 30 : 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: isVerySmallMobile ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: isVerySmallMobile ? 8 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isVerySmallMobile ? 11 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$total ${collectionName == 'schools' ? 'Schools' : 'users'}',
                            style: TextStyle(
                              fontSize: isVerySmallMobile ? 9 : 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isVerySmallMobile ? 4 : 6),
                    if (collectionName == null) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: isVerySmallMobile ? 2 : 3),
                              Text(
                                '$active',
                                style: TextStyle(
                                  fontSize: isVerySmallMobile ? 9 : 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: isVerySmallMobile ? 2 : 3),
                              Text(
                                '$pending',
                                style: TextStyle(
                                  fontSize: isVerySmallMobile ? 9 : 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                    SizedBox(width: isVerySmallMobile ? 6 : 8),
                    if (addPage != null)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => addPage!),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallMobile ? 8 : 10,
                            vertical: isVerySmallMobile ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: isVerySmallMobile ? 12 : 14,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
// --- COMPACT PROJECT CARD (With Counters) ---
// -----------------------------------------------------------------------------
class CompactProjectCard extends StatelessWidget {
  final String title;
  final String collectionName;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool isVerySmallMobile;
  final bool isSmallMobile;

  const CompactProjectCard({
    super.key,
    required this.title,
    required this.collectionName,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onAdd,
    required this.isVerySmallMobile,
    required this.isSmallMobile,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }

        return Container(
          height: isVerySmallMobile ? 75 : 85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(isVerySmallMobile ? 8.0 : 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isVerySmallMobile ? 4 : 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: isVerySmallMobile ? 16 : 18,
                          ),
                        ),
                        Text(
                          count,
                          style: TextStyle(
                            fontSize: isVerySmallMobile ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isVerySmallMobile ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: onAdd,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallMobile ? 8 : 10,
                              vertical: isVerySmallMobile ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+ Add',
                              style: TextStyle(
                                fontSize: isVerySmallMobile ? 9 : 11,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
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

class CompactSystemAlertsCard extends StatelessWidget {
  final String title;
  final bool isVerySmallMobile;
  final bool isSmallMobile;

  const CompactSystemAlertsCard({
    super.key,
    required this.title,
    required this.isVerySmallMobile,
    required this.isSmallMobile,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('issues').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
        }

        return Container(
          height: isVerySmallMobile ? 65 : 75,
          padding: EdgeInsets.all(isVerySmallMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isVerySmallMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: isVerySmallMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isVerySmallMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isVerySmallMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3436),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total reported issues',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isVerySmallMobile ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isVerySmallMobile ? 6 : 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ViewIssuesPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallMobile ? 8 : 10,
                    vertical: isVerySmallMobile ? 6 : 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: isVerySmallMobile ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// --- CustomBottomNavBar (Compact Version) ---
// -----------------------------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallMobile = screenWidth < 340;
    final isSmallMobile = screenWidth < 380;
    
    return Container(
      height: isVerySmallMobile ? 50 : 56,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Home',
              isActive: currentIndex == 0,
              isVerySmallMobile: isVerySmallMobile,
              isSmallMobile: isSmallMobile,
              onTap: () => _navigateTo(context, 0),
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              isActive: currentIndex == 1,
              isVerySmallMobile: isVerySmallMobile,
              isSmallMobile: isSmallMobile,
              onTap: () => _navigateTo(context, 1),
            ),
            _buildNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              isActive: currentIndex == 2,
              isVerySmallMobile: isVerySmallMobile,
              isSmallMobile: isSmallMobile,
              onTap: () => _navigateTo(context, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isVerySmallMobile,
    required bool isSmallMobile,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallMobile ? 8 : 12,
          vertical: isVerySmallMobile ? 6 : 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.blue.shade800 : Colors.grey.shade400,
              size: isVerySmallMobile ? 18 : 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isVerySmallMobile ? 8 : 9,
                color: isActive ? Colors.blue.shade800 : Colors.grey.shade400,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    if (currentIndex == index) return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ProvincialEngDashboard(),
          ),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileManagementPage(),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
        break;
    }
  }
}