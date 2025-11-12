import 'package:flutter/material.dart';
// Remove external imports and define placeholders below
// import 'settings.dart'; 
// import 'profile.dart'; 
// import 'all_users.dart'; 

import 'package:cloud_firestore/cloud_firestore.dart';
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
  // This userData will be passed to the header
  final Map<String, dynamic>? userData;

  const ProvincialEngineerDashboard({super.key, this.userData});

  @override
  State<ProvincialEngineerDashboard> createState() =>
      _ProvincialEngineerDashboardState();
}

class _ProvincialEngineerDashboardState
    extends State<ProvincialEngineerDashboard> {
  // --- STATE VARIABLES for "Latest Updates" ---
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

  /// --- NEW FUNCTION: Initializes the combined stream (Unchanged) ---
  void _initializeActivityStream() {
    // 1. Define a stream for each collection
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
    _activityStream = CombineLatestStream.list<List<ActivityItem>>([
      issuesStream,
      schoolsStream,
      usersStream,
    ])
        .map((List<List<ActivityItem>> allLists) {
      // 3. Flatten the list (List<List<Item>> -> List<Item>)
      final List<ActivityItem> combinedList =
          allLists.expand((list) => list).toList();

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
            // 1. --- MODIFIED: Header Section ---
            // We now pass the widget.userData to the DashboardHeader
            DashboardHeader(userData: widget.userData),

            // 2. --- MODIFIED: User Management Grids (Card size reduced here) ---
            Padding(
                padding: const EdgeInsets.all(12.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.8,
                children: <Widget>[
                  // --- REPLACED with UserCountBuilder ---
                  UserCountBuilder(
                    title: 'Manage Chief eng:',
                    userType: 'Chief Engineer', // NOTE: Assumed 'userType' string
                    addPage: const AddCEPage(),
                  ),
                  // --- REPLACED with UserCountBuilder ---
                  UserCountBuilder(
                    title: 'Manage District eng:',
                    userType: 'District Engineer', // NOTE: Assumed 'userType' string
                    addPage: const AddDEPage(),
                  ),
                  // --- REPLACED with UserCountBuilder ---
                  UserCountBuilder(
                    title: 'Manage TO',
                    userType: 'Technical Officer', // From your request
                    addPage: const AddTOPage(),
                  ),
                  // --- REPLACED with UserCountBuilder ---
                  UserCountBuilder(
                    title: 'Manage Principal',
                    userType: 'Principal', // NOTE: Assumed 'userType' string
                    addPage: const AddPrincipalPage(),
                  ),
                ],
              ),
            ),

            // 3. --- UPDATED: "Latest Updates" Section (Unchanged logic) ---
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

                  // --- StreamBuilder for activities (Unchanged logic) ---
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
      // 4. --- MODIFIED: Bottom Navigation Bar ---
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

// -----------------------------------------------------------------------------
// --- ActivityItemCard (Unchanged logic) ---
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
// --- MODIFIED: DashboardHeader (Unchanged logic) ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  // --- ADDED ---
  // This will receive the user data map
  final Map<String, dynamic>? userData;

  // --- MODIFIED ---
  // Added userData to the constructor
  const DashboardHeader({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    // --- ADDED ---
    // Get the name and role from the userData, with fallbacks
    // Based on your screenshot, the role field is 'userType'
    final String userName = userData?['name'] ?? 'User';
    final String userRole =
        userData?['userType'] ?? 'Provincial Engineer';
    // --- END ADDED ---

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
          // --- MODIFIED ---
          // Removed 'const' to use dynamic text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome, $userName!', // Display dynamic user name
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                userRole, // Display dynamic user role
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          // --- END MODIFICATION ---
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- MODIFIED: UserCountBuilder (Unchanged logic) ---
// -----------------------------------------------------------------------------
/// This widget fetches user counts for a specific `userType`
/// and builds a `UserManagementCard` with that data.
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
      // 1. Stream data from Firebase where 'userType' matches
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: userType)
          .snapshots(),
      builder: (context, snapshot) {
        int activeCount = 0;
        int pendingCount = 0;
        String activeDisplay = '...';
        String pendingDisplay = '...';

        // 2. If data is loaded, process it
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              // Check 'isActive' field. If true, increment active.
              // Else (false, null, or missing), increment pending.
              if (data.containsKey('isActive') && data['isActive'] == true) {
                activeCount++;
              } else {
                pendingCount++;
              }
            } catch (e) {
              print('Error parsing user data for $userType: $e');
              pendingCount++; // Count as pending if data is malformed
            }
          }
          activeDisplay = activeCount.toString().padLeft(2, '0');
          pendingDisplay = pendingCount.toString().padLeft(2, '0');
        }
        // 3. If error, display "Err"
        else if (snapshot.hasError) {
          activeDisplay = 'Err';
          pendingDisplay = 'Err';
        }
        // 4. While loading, '...' is used by default

        // 5. Return the UserManagementCard with the counts and navigation
        return UserManagementCard(
          title: title,
          activeUsers: activeDisplay,
          pendingUsers: pendingDisplay,
          // --- MODIFICATION: Tap on card goes to AllUsersPage ---
          onCardPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Navigate to the NEW common page (Placeholder)
                builder: (context) => AllUsersPage(
                  // Pass the specific 'userType' for this card
                  userType: userType,
                ),
              ),
            );
          },
          // --- END MODIFICATION ---
          // Tap on the "Add" row -> go to the specific AddPage
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
// --- MODIFIED: UserManagementCard (Card size optimized) ---
// -----------------------------------------------------------------------------
class UserManagementCard extends StatelessWidget {
  final String title;
  final String activeUsers;
  final String pendingUsers;
  final VoidCallback onCardPressed; // <-- Callback for tapping the card
  final VoidCallback onAddPressed; // <-- Callback for tapping the "Add" row

  const UserManagementCard({
    super.key,
    required this.title,
    required this.activeUsers,
    required this.pendingUsers,
    required this.onCardPressed, // <-- Now required
    required this.onAddPressed, // <-- Now required
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
    // This GestureDetector handles taps on the entire card area
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distributes vertically
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
              // This GestureDetector handles taps ONLY on the "Add" row
              GestureDetector(
                onTap: onAddPressed,
                behavior: HitTestBehavior.opaque, // Makes the whole row tappable
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0), // Smaller vertical pad
                  child: Row(
                    children: [
                      Text(
                        'Add a ${_getInitials(title)}',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const Spacer(),
                      Icon(Icons.add_circle, color: Colors.blue.shade600, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5), // Reduced vertical space
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
// --- MODIFIED: CustomBottomNavBar (Unchanged logic) ---
// -----------------------------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Colors.blue.shade700;
    final Color inactiveColor = Colors.blue.shade400;

    return Container(
      height: 60, // You can adjust height
      decoration: BoxDecoration(
        color: Colors.white,
        // --- MODIFICATION: Added rounded corners to match image ---
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        // --- END MODIFICATION ---
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
                // Navigate to Dashboard
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
            // --- MODIFICATION: Added navigation to ProfilePage (Placeholder) ---
            onPressed: () {
              if (currentIndex != 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            },
            // --- END MODIFICATION ---
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
                  MaterialPageRoute(builder: (context) => const SettingsPage()), // Placeholder
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
// --- BlankActionPage (Unchanged) ---
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

// -----------------------------------------------------------------------------
// --- Placeholder Add-Form Pages (Unchanged) ---
// -----------------------------------------------------------------------------

/// Placeholder for "Add Chief Engineer" page
class AddCEPage extends StatelessWidget {
  const AddCEPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Chief Engineer'),
        backgroundColor: const Color(0xFFF4F6F8), // Match theme
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

/// Placeholder for "Add District Engineer" page
class AddDEPage extends StatelessWidget {
  const AddDEPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add District Engineer'),
        backgroundColor: const Color(0xFFF4F6F8), // Match theme
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

/// Placeholder for "Add Technical Officer" page
class AddTOPage extends StatelessWidget {
  const AddTOPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Technical Officer'),
        backgroundColor: const Color(0xFFF4F6F8), // Match theme
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

/// Placeholder for "Add Principal" page (was missing)
class AddPrincipalPage extends StatelessWidget {
  const AddPrincipalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Principal'),
        backgroundColor: const Color(0xFFF4F6F8), // Match theme
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

/// Placeholder for the Profile page used in the bottom navigation.
/// Added here so references to `ProfilePage` compile.
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
    );
  }
}

/// Placeholder for the Settings page used in the bottom navigation.
/// Added here so references to `SettingsPage` compile.
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
    );
  }
}

/// Placeholder for the AllUsers page used when tapping a user management card.
/// Accepts a `userType` parameter as required by the navigation call.
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