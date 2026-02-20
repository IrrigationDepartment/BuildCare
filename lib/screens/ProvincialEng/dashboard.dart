import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

// --- PAGE IMPORTS ---
import 'view_issues.dart';
<<<<<<< HEAD
import 'contractors_list.dart';
import 'contract_list.dart';
=======
import 'contractors_list.dart'; 
import 'contract_list.dart';
import 'school_analysis.dart';
import 'school_details_page.dart';
>>>>>>> main

// --- REGISTRATION PAGE IMPORTS ---
import 'add_ce.dart';
import 'add_de.dart';
import 'add_to.dart';
import 'add_principal.dart';
import 'add_contractor_screen.dart';
import 'add_contract.dart';
<<<<<<< HEAD
import 'profile_management.dart'; // Ensure this is imported
import 'app_settings.dart'; // Ensure this is imported
=======
import 'profile_management.dart';
import 'app_settings.dart';

// --- NEW NOTIFICATION IMPORT ---
import 'notification.dart';
>>>>>>> main

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
<<<<<<< HEAD
=======
  
  late Stream<int> _unreadNotificationsStream;
>>>>>>> main

  @override
  void initState() {
    super.initState();
    _initializeActivityStream();
<<<<<<< HEAD
=======
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
>>>>>>> main
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
<<<<<<< HEAD

  // Function to handle item click navigation
  void _navigateToDetailPage(BuildContext context, ActivityItem item) {
    final data = item.snapshot.data() as Map<String, dynamic>;
    final docId = item.snapshot.id;

    switch (item.itemType) {
      case 'issue':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IssueDetailPage(issueId: docId),
          ),
        );
        break;
      
      case 'school':
        // Navigate to school details page
        // You might need to create this page or use an existing one
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SchoolDetailPage(schoolId: docId, schoolData: data),
          ),
        );
        break;
      
      case 'user':
        // Navigate to user details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailPage(userId: docId, userData: data),
          ),
        );
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
                child: const Text('OK'),
              ),
            ],
          ),
        );
    }
  }
=======
>>>>>>> main

  @override
  Widget build(BuildContext context) {
    const Color pageBackgroundColor = Color(0xFFF4F6F8);
<<<<<<< HEAD
=======
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallMobile = screenWidth < 340; 
    final isSmallMobile = screenWidth < 380; 
>>>>>>> main

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        backgroundColor: pageBackgroundColor,
        toolbarHeight: 0,
        elevation: 0,
<<<<<<< HEAD
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DashboardHeader(userData: widget.userData),
            const SizedBox(height: 16),
            _buildSectionTitle('User Management'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.0,
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
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Project Management'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                                builder: (context) =>
                                    const ContractorsListPage()),
                          );
                        },
                        onAdd: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AddContractorScreen()),
                          );
                        }),
                  ),
                  const SizedBox(width: 10),
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
                                builder: (context) => const ContractListPage()),
                          );
                        },
                        onAdd: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AddContractScreen()),
                          );
                        }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('System Alerts'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: IssueCountBuilder(title: 'Manage Issues'),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Latest Updates'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreamBuilder<List<ActivityItem>>(
                stream: _activityStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator()));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('No recent updates found.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
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
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D3436),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- DashboardHeader (Updated) ---
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
      padding: const EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 30.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 35)
                        : null,
                  );
                },
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $userName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userRole,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_active, color: Colors.white),
                  onPressed: () {},
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
// --- CustomBottomNavBar (Shared Navigation Widget) ---
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) => _onTabTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
// --- UPDATED UserCountBuilder with Smaller Size ---
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
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(icon, size: 28, color: color),
                    Text(
                      total.toString(),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(Colors.green),
                        Text(" $active  ",
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey)),
                        _buildDot(Colors.orange),
                        Text(" $pending",
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => addPage));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '+ Add',
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.bold),
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

  Widget _buildDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- UPDATED SimpleCountCard with Smaller Size ---
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
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }

        return Container(
          height: 110,
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
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        Text(
                          count,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Center(
                      child: InkWell(
                        onTap: onAdd,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '+ Add',
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.bold),
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

// -----------------------------------------------------------------------------
// --- UPDATED ActivityItemCard with onTap ---
// -----------------------------------------------------------------------------
class ActivityItemCard extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback onTap;

  const ActivityItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = item.snapshot.data() as Map<String, dynamic>;
    final issueId = item.snapshot.id;

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;
    Color? textColor;

    switch (item.itemType) {
      case 'issue':
        icon = Icons.warning_rounded;
        iconColor = Colors.orange;
        title = '${data['schoolName'] ?? 'Unknown'} - Issue';
        subtitle = '${data['issueTitle'] ?? 'No Title'}';
        textColor = Colors.orange.shade800;
        break;
      case 'school':
        icon = Icons.domain;
        iconColor = Colors.blue;
        title = data['schoolName'] ?? 'New School';
        subtitle = 'Added to zone: ${data['educationalZone'] ?? 'Unknown'}';
        textColor = Colors.blue.shade800;
        break;
      case 'user':
        icon = Icons.person_add_alt_1;
        iconColor = Colors.green;
        title = data['name'] ?? 'New User';
        subtitle = 'Role: ${data['userType'] ?? data['role'] ?? 'N/A'}';
        textColor = Colors.green.shade800;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        title = 'Activity';
        subtitle = 'Update received';
        textColor = Colors.grey.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  radius: 22,
                  child: Icon(icon, color: iconColor, size: 22),
                ),
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
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeAgo(item.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
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

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
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
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 30),
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
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    Text(
                      '$total reported issues',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ViewIssuesPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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

// -----------------------------------------------------------------------------
// --- IssueDetailPage ---
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Issue not found'));
          }
          
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['issueTitle'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'School: ${data['schoolName'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['description'] ?? 'No description available',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                // Add more details as needed
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- SchoolDetailPage ---
// -----------------------------------------------------------------------------
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolData['schoolName'] ?? 'Unknown School',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Educational Zone:', schoolData['educationalZone'] ?? 'N/A'),
                    _buildDetailRow('Address:', schoolData['address'] ?? 'N/A'),
                    _buildDetailRow('Contact:', schoolData['contactNumber'] ?? 'N/A'),
                    // Add more school details as needed
=======
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
>>>>>>> main
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

  Widget _buildProjectManagementRow({
    required bool isVerySmallMobile,
    required bool isSmallMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallMobile ? 6.0 : (isSmallMobile ? 8.0 : 12.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CompactProjectCard(
                  title: 'Contractors',
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
              SizedBox(width: isVerySmallMobile ? 6.0 : (isSmallMobile ? 8.0 : 10.0)),
              Expanded(
                child: CompactProjectCard(
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
                  isVerySmallMobile: isVerySmallMobile,
                  isSmallMobile: isSmallMobile,
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmallMobile ? 8.0 : (isSmallMobile ? 10.0 : 12.0)),
          // FIXED: Increased height here as well for consistency (from 75/85 to 95/110)
          Container(
            height: isVerySmallMobile ? 95 : 110,
          Container(
            height: isVerySmallMobile ? 75 : 85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.1),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SchoolAnalysisPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(isVerySmallMobile ? 10.0 : 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: isVerySmallMobile ? 40 : 48,
                        height: isVerySmallMobile ? 40 : 48,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: Colors.deepPurple,
                          size: isVerySmallMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isVerySmallMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'School Analysis',
                              style: TextStyle(
                                fontSize: isVerySmallMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Analyze school information & statistics',
                              style: TextStyle(
                                fontSize: isVerySmallMobile ? 10 : 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.deepPurple,
                        size: isVerySmallMobile ? 20 : 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
              builder: (context) => const SearchableSchoolListPage(),
            ),
          );
        },
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallMobile ? 6.0 : (isSmallMobile ? 8.0 : 12.0),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isVerySmallMobile ? 1 : 2,
          crossAxisSpacing: isVerySmallMobile ? 6.0 : (isSmallMobile ? 8.0 : 12.0),
          mainAxisSpacing: isVerySmallMobile ? 6.0 : (isSmallMobile ? 8.0 : 12.0),
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

  Widget _buildSystemAlertsCard({
    required bool isVerySmallMobile,
    required bool isSmallMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallMobile
            ? 6.0
            : (isSmallMobile ? 8.0 : 12.0),
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
        isVerySmallMobile ? 8.0 : (isSmallMobile ? 10.0 : 12.0),
        0,
        isVerySmallMobile ? 8.0 : (isSmallMobile ? 10.0 : 12.0),
        6.0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 16 : 18),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D3436),
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
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
<<<<<<< HEAD
// --- UserDetailPage ---
// -----------------------------------------------------------------------------
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
                      child: Text(
                        userData['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('User Type:', userData['userType'] ?? 'N/A'),
                    _buildDetailRow('Email:', userData['email'] ?? 'N/A'),
                    _buildDetailRow('Status:', userData['isActive'] == true ? 'Active' : 'Inactive'),
                    _buildDetailRow('Created:', _formatDate(userData['createdAt'])),
                    // Add more user details as needed
                  ],
                ),
              ),
            ),
          ],
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
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
=======
// --- NEW SEARCHABLE SCHOOL LIST PAGE ---
// -----------------------------------------------------------------------------
class SearchableSchoolListPage extends StatefulWidget {
  const SearchableSchoolListPage({super.key});

  @override
  State<SearchableSchoolListPage> createState() => _SearchableSchoolListPageState();
}

class _SearchableSchoolListPageState extends State<SearchableSchoolListPage> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Schools'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search school name...',
                prefixIcon: const Icon(Icons.search, color: Colors.brown),
                suffixIcon: searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() { searchQuery = ""; });
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
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

          final filteredSchools = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final schoolName = (data['schoolName'] ?? data['name'] ?? '').toString().toLowerCase();
            return schoolName.contains(searchQuery);
          }).toList();

          if (filteredSchools.isEmpty) {
            return const Center(child: Text("No matching schools found."));
          }

          return ListView.builder(
            itemCount: filteredSchools.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = filteredSchools[index].data() as Map<String, dynamic>;
              final schoolId = filteredSchools[index].id;

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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SchoolDetailsPage(schoolId: schoolId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- OTHER WIDGETS (Header, Compact Cards, Nav Bar) ---
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome, $userName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 16 : 18),
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
                    fontSize: isVerySmallMobile ? 10 : (isSmallMobile ? 12 : 14),
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
>>>>>>> main
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
  
  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return '${date.toDate()}';
    } else if (date is String) {
      return date;
    }
    return 'N/A';
=======
}

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
                    const SizedBox(width: 8),
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
                    if (collectionName == null) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                              const SizedBox(width: 3),
                              Text('$active', style: TextStyle(fontSize: isVerySmallMobile ? 9 : 10, color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                              const SizedBox(width: 3),
                              Text('$pending', style: TextStyle(fontSize: isVerySmallMobile ? 9 : 10, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ],
                    if (addPage != null)
                      IconButton(
                        icon: Icon(Icons.add_box, color: color, size: 20),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => addPage!)),
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

        // FIXED: Increased height to prevent bottom overflow
        return Container(
          height: isVerySmallMobile ? 95 : 110, // Increased from 75/85
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Icon(icon, color: color, size: isVerySmallMobile ? 16 : 18),
                        ),
                        Text(count, style: TextStyle(fontSize: isVerySmallMobile ? 16 : 20, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, style: TextStyle(fontSize: isVerySmallMobile ? 12 : 14, fontWeight: FontWeight.w600, color: Colors.grey[800]), maxLines: 1)),
                        TextButton(onPressed: onAdd, child: Text('+ Add', style: TextStyle(fontSize: isVerySmallMobile ? 9 : 11, color: color, fontWeight: FontWeight.bold))),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(fontSize: isVerySmallMobile ? 12 : 14, fontWeight: FontWeight.w600)),
                    Text('$total reported issues', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewIssuesPage())),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                child: const Text('View All'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallMobile = screenWidth < 340;
    
    return Container(
      height: isVerySmallMobile ? 50 : 56,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
          _buildNavItem(context, 1, Icons.person_outline, Icons.person, 'Profile'),
          _buildNavItem(context, 2, Icons.settings_outlined, Icons.settings, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final isActive = currentIndex == index;
    return InkWell(
      onTap: () => _navigateTo(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? activeIcon : icon, color: isActive ? Colors.blue.shade800 : Colors.grey.shade400),
          Text(label, style: TextStyle(fontSize: 9, color: isActive ? Colors.blue.shade800 : Colors.grey.shade400)),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    if (currentIndex == index) return;
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ProvincialEngDashboard()), (route) => false);
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileManagementPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
        break;
    }
>>>>>>> main
  }
}