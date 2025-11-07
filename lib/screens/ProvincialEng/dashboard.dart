import 'package:flutter/material.dart';
// Import ManageUsersPage from manage_users.dart
import 'manage_users.dart';
// Import SettingsPage from settings.dart
import 'settings.dart';

// --- ADDED THIS IMPORT ---
import 'package:cloud_firestore/cloud_firestore.dart';

// --- ADD RXDART IMPORT FOR COMBINING STREAMS ---
import 'package:rxdart/rxdart.dart';

// -----------------------------------------------------------------------------
// --- HELPER CLASS: ActivityItem (Unchanged) ---
// -----------------------------------------------------------------------------
class ActivityItem {
  final DocumentSnapshot snapshot;
  final String itemType; // 'issue', 'school', or 'user'
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
  // --- STATE VARIABLES for "Latest Updates" ---
  // We no longer need _isLoading or _latestActivities
  // Instead, we will define a final Stream
  late final Stream<List<ActivityItem>> _activityStream;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeActivityStream();
  }

  /// Helper function to safely extract a DateTime from a snapshot (Unchanged)
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

  /// --- NEW FUNCTION: Initializes the combined stream ---
  void _initializeActivityStream() {
    // 1. Define a stream for each collection
    //    We use .snapshots() instead of .get() to listen for live updates
    Stream<List<ActivityItem>> issuesStream = _firestore
        .collection('issues')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots() // <-- Real-time listener
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
        .snapshots() // <-- Real-time listener
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
        .snapshots() // <-- Real-time listener
        .map((snapshot) => snapshot.docs.map((doc) {
              return ActivityItem(
                snapshot: doc,
                itemType: 'user',
                timestamp: _safeExtractTimestamp(doc, 'createdAt'),
              );
            }).toList());

    // 2. Combine the three streams into one
    //    This uses the rxdart package
    _activityStream = CombineLatestStream.list<List<ActivityItem>>([
      issuesStream,
      schoolsStream,
      usersStream,
    ])
        .map((List<List<ActivityItem>> allLists) {
      // 3. Flatten the list (List<List<Item>> -> List<Item>)
      final List<ActivityItem> combinedList = allLists.expand((list) => list).toList();
      
      // 4. Sort the combined list by timestamp (newest first)
      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // 5. Take the top 5 most recent items from all collections
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
            // 1. Header Section
            const DashboardHeader(),

            // 2. User Management Grids
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.9,
                children: <Widget>[
                  UserManagementCard(
                    title: 'Manage Chief eng:',
                    activeUsers: '04',
                    pendingUsers: '04',
                  ),
                  UserManagementCard(
                    title: 'Manage District eng:',
                    activeUsers: '10',
                    pendingUsers: '04',
                  ),
                  UserManagementCard(
                    title: 'Manage TO',
                    activeUsers: '10',
                    pendingUsers: '04',
                  ),
                  UserManagementCard(
                    title: 'Manage Principal',
                    activeUsers: '10',
                    pendingUsers: '04',
                  ),
                ],
              ),
            ),

            // 3. --- UPDATED: "Latest Updates" Section ---
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

                  // --- REPLACED with StreamBuilder ---
                  // This widget will now automatically rebuild
                  // whenever the _activityStream emits new data
                  StreamBuilder<List<ActivityItem>>(
                    stream: _activityStream,
                    builder: (context, snapshot) {
                      // 1. Show loading spinner
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 2. Show error if one occurs
                      if (snapshot.hasError) {
                        print('StreamBuilder Error: ${snapshot.error}');
                        return const Center(
                            child: Text('Error loading updates.'));
                      }

                      // 3. Show message if no updates are found
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

                      // 4. Build the list using the data from the stream
                      final latestActivities = snapshot.data!;
                      return Column(
                        children: latestActivities.map((item) {
                          return ActivityItemCard(item: item);
                        }).toList(),
                      );
                    },
                  ),
                  // --- End of StreamBuilder ---
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      // 4. Bottom Navigation Bar
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

// -----------------------------------------------------------------------------
// --- ActivityItemCard (Unchanged) ---
// -----------------------------------------------------------------------------
class ActivityItemCard extends StatelessWidget {
  final ActivityItem item;

  const ActivityItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.snapshot.data() as Map<String, dynamic>;

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
        final role = data['role'] ?? 'New User';
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
                  // TODO: Navigate to details page for this issue
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
// --- DashboardHeader (Unchanged) ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 30.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome !',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Provincial Engineer',
                style: TextStyle(
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
// --- UserManagementCard (Unchanged) ---
// -----------------------------------------------------------------------------
class UserManagementCard extends StatelessWidget {
  final String title;
  final String activeUsers;
  final String pendingUsers;

  const UserManagementCard({
    super.key,
    required this.title,
    required this.activeUsers,
    required this.pendingUsers,
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageUsersPage(
              roleTitle: title,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
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
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Add a ${_getInitials(title)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const Spacer(),
                  Icon(Icons.add_circle, color: Colors.blue.shade600, size: 22),
                ],
              ),
              const SizedBox(height: 10),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
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
// --- CustomBottomNavBar (Unchanged) ---
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
              // TODO: Profile Page navigation logic goes here
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
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
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
// --- Blank Pages (Unchanged, hidden for brevity) ---
// -----------------------------------------------------------------------------
class BlankActionPage extends StatelessWidget {
  final String action;
  final String target;

  const BlankActionPage({super.key, required this.action, required this.target});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(action),
        backgroundColor: const Color(0xFFE8F2FF),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'This is the blank page for the "$action" action on user: $target.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}