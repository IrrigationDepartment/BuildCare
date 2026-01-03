import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

// --- PAGE IMPORTS ---
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
    // This stream initialization can be removed since we're not using it anymore
    // But keeping it for future use if needed
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
    final isSmallMobile = screenWidth < 360; // For very small devices
    final isMobile = screenWidth < 600;

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DashboardHeader(
                userData: widget.userData,
                unreadNotificationsStream: _unreadNotificationsStream,
                isMobile: isMobile,
                isSmallMobile: isSmallMobile,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('User Management', isMobile: isMobile),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 8.0 : 12.0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = isSmallMobile ? 1 : 2;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: isSmallMobile ? 8.0 : 12.0,
                      mainAxisSpacing: isSmallMobile ? 8.0 : 12.0,
                      childAspectRatio: _getChildAspectRatio(screenWidth),
                      children: const <Widget>[
                        UserCountBuilder(
                          title: 'Chief Engineer',
                          userType: 'Chief Engineer',
                          addPage: ChiefEngRegistrationPage(),
                          icon: Icons.person_pin,
                          color: Colors.blue,
                        ),
                        UserCountBuilder(
                          title: 'District Engineer',
                          userType: 'District Engineer',
                          addPage: DistrictEngRegistrationPage(),
                          icon: Icons.engineering,
                          color: Colors.green,
                        ),
                        UserCountBuilder(
                          title: 'Technical Officer',
                          userType: 'Technical Officer',
                          addPage: TORegistrationPage(),
                          icon: Icons.build,
                          color: Colors.orange,
                        ),
                        UserCountBuilder(
                          title: 'Principals',
                          userType: 'Principal',
                          addPage: PrincipalRegistrationPage(),
                          icon: Icons.school,
                          color: Colors.purple,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Project Management', isMobile: isMobile),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 8.0 : 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SimpleCountCard(
                        title: 'Contractors',
                        collectionName: 'contractors',
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
                        isSmallMobile: isSmallMobile,
                      ),
                    ),
                    SizedBox(width: isSmallMobile ? 8.0 : 10.0),
                    Expanded(
                      child: SimpleCountCard(
                        title: 'Contracts',
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
                        isSmallMobile: isSmallMobile,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('System Alerts', isMobile: isMobile),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 8.0 : 16.0,
                ),
                child: IssueCountBuilder(
                  title: 'Manage Issues',
                  isSmallMobile: isSmallMobile,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth < 360) return 1.3; // Very small devices
    if (screenWidth < 400) return 1.2; // Small devices
    return 1.1; // Normal devices
  }

  Widget _buildSectionTitle(String title, {required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12.0 : 16.0,
        0,
        isMobile ? 12.0 : 16.0,
        10.0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 18 : 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2D3436),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- DashboardHeader (Updated with Notification Bell) ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Stream<int> unreadNotificationsStream;
  final bool isMobile;
  final bool isSmallMobile;
  
  const DashboardHeader({
    super.key, 
    this.userData,
    required this.unreadNotificationsStream,
    required this.isMobile,
    required this.isSmallMobile,
  });

  @override
  Widget build(BuildContext context) {
    final String userName = userData?['name'] ?? 'Engineer';
    final String userRole = userData?['userType'] ?? 'Provincial Dashboard';
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16.0 : 20.0,
        isMobile ? 40.0 : 50.0,
        isMobile ? 16.0 : 20.0,
        isMobile ? 20.0 : 30.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    radius: isSmallMobile ? 25 : 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? Icon(
                            Icons.person,
                            color: Colors.white,
                            size: isSmallMobile ? 30 : 35,
                          )
                        : null,
                  );
                },
              ),
              SizedBox(width: isSmallMobile ? 12 : 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $userName',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallMobile ? 18 : 22,
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
                        fontSize: isSmallMobile ? 12 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // --- NOTIFICATION BELL WITH BADGE ---
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: isSmallMobile ? 20 : 24,
                      ),
                      padding: const EdgeInsets.all(8),
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
                  // Badge for unread notifications
                  Positioned(
                    right: 4,
                    top: 4,
                    child: StreamBuilder<int>(
                      stream: unreadNotificationsStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == 0) {
                          return const SizedBox();
                        }
                        return Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${snapshot.data! > 9 ? '9+' : snapshot.data}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallMobile ? 8 : 10,
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
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- CustomBottomNavBar (Shared Navigation Widget) ---
// -----------------------------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = MediaQuery.of(context).size.width < 360;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade800,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: isSmallMobile ? 10 : 12,
          unselectedFontSize: isSmallMobile ? 10 : 12,
          iconSize: isSmallMobile ? 20 : 24,
          onTap: (index) => _onTabTapped(context, index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
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
        if (currentIndex == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileManagementPage(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileManagementPage(),
            ),
          );
        }
        break;
      case 2:
        if (currentIndex == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ),
          );
        }
        break;
    }
  }
}

// -----------------------------------------------------------------------------
// --- OTHER WIDGETS ---
// -----------------------------------------------------------------------------
class UserCountBuilder extends StatelessWidget {
  final String userType;
  final String title;
  final Widget addPage;
  final IconData icon;
  final Color color;

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
    final isSmallMobile = MediaQuery.of(context).size.width < 360;
    
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserListPage(
                      userType: userType,
                      title: title,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallMobile ? 12.0 : 16.0,
                  horizontal: isSmallMobile ? 6.0 : 8.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(
                      icon,
                      size: isSmallMobile ? 28 : 32,
                      color: color,
                    ),
                    Text(
                      total.toString(),
                      style: TextStyle(
                        fontSize: isSmallMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(Colors.green, isSmallMobile),
                        Text(
                          " $active  ",
                          style: TextStyle(
                            fontSize: isSmallMobile ? 9 : 11,
                            color: Colors.grey,
                          ),
                        ),
                        _buildDot(Colors.orange, isSmallMobile),
                        Text(
                          " $pending",
                          style: TextStyle(
                            fontSize: isSmallMobile ? 9 : 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => addPage),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallMobile ? 16 : 20,
                          vertical: isSmallMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '+ Add',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 10 : 12,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildDot(Color color, bool isSmallMobile) {
    return Container(
      width: isSmallMobile ? 5 : 6,
      height: isSmallMobile ? 5 : 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class SimpleCountCard extends StatelessWidget {
  final String title;
  final String collectionName;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool isSmallMobile;

  const SimpleCountCard({
    super.key,
    required this.title,
    required this.collectionName,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onAdd,
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
          height: isSmallMobile ? 110 : 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(isSmallMobile ? 10.0 : 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallMobile ? 6 : 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: isSmallMobile ? 18 : 22,
                          ),
                        ),
                        Text(
                          count,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Center(
                      child: InkWell(
                        onTap: onAdd,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallMobile ? 16 : 20,
                            vertical: isSmallMobile ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '+ Add',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 10 : 12,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
}

class ActivityItemCard extends StatelessWidget {
  final ActivityItem item;
  const ActivityItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.snapshot.data() as Map<String, dynamic>;
    final issueId = item.snapshot.id;

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;
    bool showButton = false;

    switch (item.itemType) {
      case 'issue':
        icon = Icons.warning_rounded;
        iconColor = Colors.orange;
        title = '${data['schoolName'] ?? 'Unknown'} - Issue';
        subtitle = '${data['issueTitle'] ?? 'No Title'}';
        showButton = true;
        break;
      case 'school':
        icon = Icons.domain;
        iconColor = Colors.blue;
        title = data['schoolName'] ?? 'New School';
        subtitle = 'Added to zone: ${data['educationalZone'] ?? 'Unknown'}';
        showButton = false;
        break;
      case 'user':
        icon = Icons.person_add_alt_1;
        iconColor = Colors.green;
        title = data['name'] ?? 'New User';
        subtitle = 'Role: ${data['userType'] ?? data['role'] ?? 'N/A'}';
        showButton = false;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        title = 'Activity';
        subtitle = 'Update received';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 6.0,
        ),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: showButton
            ? IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IssueDetailPage(issueId: issueId),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}

class IssueCountBuilder extends StatelessWidget {
  final String title;
  final bool isSmallMobile;

  const IssueCountBuilder({
    super.key,
    required this.title,
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
          padding: EdgeInsets.all(isSmallMobile ? 14 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: isSmallMobile ? 24 : 30,
                ),
              ),
              SizedBox(width: isSmallMobile ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                    Text(
                      '$total reported issues',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isSmallMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 12 : 16,
                    vertical: isSmallMobile ? 8 : 10,
                  ),
                  textStyle: TextStyle(
                    fontSize: isSmallMobile ? 12 : 14,
                  ),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class IssueDetailPage extends StatelessWidget {
  final String issueId;
  const IssueDetailPage({super.key, required this.issueId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Details")),
      body: Center(child: Text("Details for $issueId")),
    );
  }
}