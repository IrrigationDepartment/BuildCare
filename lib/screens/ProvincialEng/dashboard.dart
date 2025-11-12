// lib/provincial_engineer_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
// NEW IMPORT: Issues View link 
import 'view_issues.dart'; 

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
class ProvincialEngineerDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProvincialEngineerDashboard({super.key, this.userData});

  @override
  State<ProvincialEngineerDashboard> createState() =>
      _ProvincialEngineerDashboardState();
}

class _ProvincialEngineerDashboardState
    extends State<ProvincialEngineerDashboard> {
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
      print('Error extracting timestamp: $e');
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
    ])
        .map((List<List<ActivityItem>> allLists) {
      final List<ActivityItem> combinedList =
          allLists.expand((list) => list).toList();

      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return combinedList.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBackgroundColor = Color(0xFFF4F6F8);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        backgroundColor: pageBackgroundColor,
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. --- Dashboard Header Section ---
            DashboardHeader(userData: widget.userData),

            // 2. --- User Management Grids (Group 1) ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'User Management', 
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 1.8,
                children: const <Widget>[
                  // --- User Management Cards (Unchanged Logic) ---
                  UserCountBuilder(
                    title: 'Manage Chief eng:',
                    userType: 'Chief Engineer', 
                    addPage: AddCEPage(),
                  ),
                  UserCountBuilder(
                    title: 'Manage District eng:',
                    userType: 'District Engineer', 
                    addPage: AddDEPage(),
                  ),
                  UserCountBuilder(
                    title: 'Manage TO',
                    userType: 'Technical Officer', 
                    addPage: AddTOPage(),
                  ),
                  UserCountBuilder(
                    title: 'Manage Principal',
                    userType: 'Principal', 
                    addPage: AddPrincipalPage(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3.  MANAGE ISSUES SECTION 
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Manage Issues', 
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  IssueCountBuilder(
                    title: 'Manage Issues',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. --- "Latest Updates" Section (Group 3) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Updates',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<ActivityItem>>(
                    stream: _activityStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        print('StreamBuilder Error: ${snapshot.error}');
                        return const Center(
                            child: Text('Error loading updates.'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No recent updates found.',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 16),
                            ),
                          ),
                        );
                      }
                      final latestActivities = snapshot.data!;
                      return Column(
                        children: latestActivities.map((item) {
                          return ActivityItemCard(item: item);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // 5. --- Bottom Navigation Bar ---
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

// -----------------------------------------------------------------------------
// --- ActivityItemCard (UPDATED NAVIGATION LOGIC) ---
// -----------------------------------------------------------------------------
class ActivityItemCard extends StatelessWidget {
  final ActivityItem item;

  const ActivityItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.snapshot.data() as Map<String, dynamic>;
    final issueId = item.snapshot.id; // Get the ID for navigation

    IconData icon;
    String title;
    String subtitle;
    bool showButton = false;

    switch (item.itemType) {
      case 'issue':
        icon = Icons.apartment;
        final schoolName = data['schoolName'] ?? 'Unknown School';
        final issueTitle = data['issueTitle'] ?? 'No Title';
        final city = data['educationalZone'] ?? 'Unknown Location';
        final status = data['status'] ?? 'No Status';

        title = '$schoolName - $issueTitle';
        subtitle = '$city - Status, $status';
        showButton = true;
        break;

      case 'school':
        icon = Icons.school;
        title = data['schoolName'] ?? 'Unknown School';
        final city = data['educationalZone'] ?? 'Unknown Location';
        subtitle = '$city - New school added';
        showButton = false;
        break;

      case 'user':
        icon = Icons.person_add;
        title = data['name'] ?? 'Unknown User';
        final role = data['role'] ?? 'New User'; // Assuming 'role' field
        final status = data['isActive'] == true ? 'Active' : 'Pending';
        subtitle = '$role - Status, $status';
        showButton = false;
        break;

      default:
        icon = Icons.info;
        title = 'New Activity';
        subtitle = 'A new item was added.';
        showButton = false;
    }

    return Card(
      elevation: 1,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 40,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (showButton)
              OutlinedButton(
                onPressed: () {
                  // UPDATED: Navigate to IssueDetailPage with the issueId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IssueDetailPage(issueId: issueId),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(width: 80),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- DashboardHeader (Unchanged logic) ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const DashboardHeader({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final String userName = userData?['name'] ?? 'User';
    final String userRole =
        userData?['userType'] ?? 'Provincial Engineer';

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 30.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.lightBlue.shade200,
                  Colors.blue.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 55,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome, $userName!', 
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                userRole, 
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
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
// --- IssueCountBuilder (NAVIGATION TO view_issues.dart) ---
// -----------------------------------------------------------------------------
class IssueCountBuilder extends StatelessWidget {
  final String title;

  const IssueCountBuilder({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('issues').snapshots(),
      builder: (context, snapshot) {
        int totalIssues = 0;
        int pendingIssues = 0;
        String totalDisplay = '...';
        String pendingDisplay = '...';

        if (snapshot.hasData) {
          totalIssues = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('status') &&
                  (data['status'] == 'Pending' || data['status'] == 'New')) {
                pendingIssues++;
              }
            } catch (e) {
              print('Error parsing issue data: $e');
            }
          }
          totalDisplay = totalIssues.toString().padLeft(2, '0');
          pendingDisplay = pendingIssues.toString().padLeft(2, '0');
        }
        else if (snapshot.hasError) {
          totalDisplay = 'Err';
          pendingDisplay = 'Err';
        }

        return IssuesManagementCard(
          title: title,
          totalIssues: totalDisplay,
          pendingIssues: pendingDisplay,
          onCardPressed: () {
            // Correctly navigating to ViewIssuesPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ViewIssuesPage(),
              ),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// --- IssuesManagementCard (Card UI) ---
// -----------------------------------------------------------------------------
class IssuesManagementCard extends StatelessWidget {
  final String title;
  final String totalIssues;
  final String pendingIssues;
  final VoidCallback onCardPressed;

  const IssuesManagementCard({
    super.key,
    required this.title,
    required this.totalIssues,
    required this.pendingIssues,
    required this.onCardPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardPressed,
      child: Card(
        elevation: 2,
        color: const Color(0xFFFFFCDE), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.warning_amber,
                      size: 24, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepOrange, 
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text(
                    'Total Issues',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    totalIssues,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Pending Issues',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    pendingIssues,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Highlight pending issues in red
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- UserCountBuilder (Unchanged logic) ---
// -----------------------------------------------------------------------------
class UserCountBuilder extends StatelessWidget {
  final String userType;
  final String title;
  final Widget addPage;

  const UserCountBuilder({
    super.key,
    required this.userType,
    required this.title,
    required this.addPage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: userType)
          .snapshots(),
      builder: (context, snapshot) {
        int activeCount = 0;
        int pendingCount = 0;
        String activeDisplay = '...';
        String pendingDisplay = '...';

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('isActive') && data['isActive'] == true) {
                activeCount++;
              } else {
                pendingCount++;
              }
            } catch (e) {
              print('Error parsing user data for $userType: $e');
              pendingCount++; 
            }
          }
          activeDisplay = activeCount.toString().padLeft(2, '0');
          pendingDisplay = pendingCount.toString().padLeft(2, '0');
        }
        else if (snapshot.hasError) {
          activeDisplay = 'Err';
          pendingDisplay = 'Err';
        }

        return UserManagementCard(
          title: title,
          activeUsers: activeDisplay,
          pendingUsers: pendingDisplay,
          onCardPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllUsersPage(
                  userType: userType,
                ),
              ),
            );
          },
          onAddPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => addPage),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// --- UserManagementCard (Unchanged logic) ---
// -----------------------------------------------------------------------------
class UserManagementCard extends StatelessWidget {
  final String title;
  final String activeUsers;
  final String pendingUsers;
  final VoidCallback onCardPressed; 
  final VoidCallback onAddPressed; 

  const UserManagementCard({
    super.key,
    required this.title,
    required this.activeUsers,
    required this.pendingUsers,
    required this.onCardPressed, 
    required this.onAddPressed, 
  });

  String _getInitials(String title) {
    if (title.contains('Chief')) return 'C.E.';
    if (title.contains('District')) return 'D.E.';
    if (title.contains('TO')) return 'TO';
    if (title.contains('Principal')) return 'Principal';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardPressed,
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, 
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.person_outline,
                      size: 20, color: Colors.black54),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onAddPressed,
                behavior: HitTestBehavior.opaque, 
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4.0), 
                  child: Row(
                    children: [
                      Text(
                        'Add a ${_getInitials(title)}',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const Spacer(),
                      Icon(Icons.add_circle,
                          color: Colors.blue.shade600, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5), 
              Row(
                children: [
                  const Text(
                    'Active Users',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    activeUsers,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Text(
                    'Pending Users',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    pendingUsers,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 92, 172, 241),
                      fontSize: 16,
                    ),
                    
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- MODIFIED: CustomBottomNavBar (Completed logic) ---
// -----------------------------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Colors.blue.shade700;
    final Color inactiveColor = Colors.blue.shade400;

    return Container(
      height: 60, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.home,
              color: currentIndex == 0 ? activeColor : inactiveColor,
              size: 30,
            ),
            onPressed: () {
              if (currentIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const ProvincialEngineerDashboard()), 
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              color: currentIndex == 1 ? activeColor : inactiveColor,
              size: 30,
            ),
            onPressed: () {
              if (currentIndex != 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: currentIndex == 2 ? activeColor : inactiveColor,
              size: 30,
            ),
            onPressed: () {
              if (currentIndex != 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsPage()), 
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- MODIFIED: Issue Detail Page (Functional Implementation) ---
// -----------------------------------------------------------------------------

/// The detail page that fetches and displays a single issue's details and image.
class IssueDetailPage extends StatelessWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

  // Helper method to determine color based on status
  Color _getStatusColor(String status) {
    if (status == 'Resolved' || status == 'Completed') {
      return Colors.green.shade600;
    } else if (status == 'Pending' || status == 'New') {
      return Colors.red.shade700;
    } else if (status == 'Ongoing' || status == 'In Progress') {
      return Colors.orange.shade600;
    } else {
      return Colors.grey.shade600;
    }
  }

  // Helper widget for detail rows
  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
        backgroundColor: const Color(0xFFE8F2FF),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the specific document using the issueId
        future: FirebaseFirestore.instance.collection('issues').doc(issueId).get(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 3. Document Not Found
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Issue not found.'));
          }

          // 4. Data Loaded State
          final issueData = snapshot.data!.data() as Map<String, dynamic>;
          
          final String issueTitle = issueData['issueTitle'] ?? 'No Title Provided';
          final String schoolName = issueData['schoolName'] ?? 'N/A';
          final String status = issueData['status'] ?? 'N/A';
          final String description = issueData['description'] ?? 'No description available.';
          // Assuming the image URL is stored in a field called 'imageUrl'
          final String imageUrl = issueData['imageUrl'] ?? ''; 
          
          Color statusColor = _getStatusColor(status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Display the Image
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.infinity,
                      // --- Image Loading and Error Handling Logic ---
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 250,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                             color: Colors.grey[200],
                             borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          ),
                        );
                      },
                      // --- End Image Loading/Error Handling ---
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Placeholder for no image
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Center(child: Text('No Image Attached')),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // --- Details ---
                Text(
                  issueTitle,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                _buildDetailRow('School Name:', schoolName, Colors.black54),
                _buildDetailRow('Issue ID:', issueId, Colors.black54),
                const SizedBox(height: 10),
                
                // Status Section
                Row(
                  children: [
                    const Text('Status:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 30),
                
                // Description Section
                const Text(
                  'Description:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                ),
                
                // Add more details here if needed (e.g., reporter, date, location)
              ],
            ),
          );
        },
      ),
    );
  }
}


class AddCEPage extends StatelessWidget {
  const AddCEPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Chief Engineer'),
        backgroundColor: const Color(0xFFF4F6F8), 
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Add C.E. Form Goes Here',
          style: TextStyle(fontSize: 20, color: Colors.black54),
        ),
      ),
    );
  }
}

class AddDEPage extends StatelessWidget {
  const AddDEPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add District Engineer'),
        backgroundColor: const Color(0xFFF4F6F8), 
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Add D.E. Form Goes Here',
          style: TextStyle(fontSize: 20, color: Colors.black54),
        ),
      ),
    );
  }
}

class AddTOPage extends StatelessWidget {
  const AddTOPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Technical Officer'),
        backgroundColor: const Color(0xFFF4F6F8), 
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Add T.O. Form Goes Here',
          style: TextStyle(fontSize: 20, color: Colors.black54),
        ),
      ),
    );
  }
}

class AddPrincipalPage extends StatelessWidget {
  const AddPrincipalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Principal'),
        backgroundColor: const Color(0xFFF4F6F8), 
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Add Principal Form Goes Here',
          style: TextStyle(fontSize: 20, color: Colors.black54),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Profile Page Placeholder',
          style: TextStyle(fontSize: 20, color: Colors.black54),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1), 
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Settings Page Placeholder',
          style: TextStyle(fontSize: 20, color: Colors.black54),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2), 
    );
  }
}

class AllUsersPage extends StatelessWidget {
  final String userType;

  const AllUsersPage({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Users - $userType'),
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'List of users for: $userType',
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }
}