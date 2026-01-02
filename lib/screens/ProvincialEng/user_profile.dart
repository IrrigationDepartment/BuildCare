import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:rxdart/rxdart.dart'; // For combining streams

// -----------------------------------------------------------------------------
// --- HELPER CLASS: ActivityLogItem ---
// -----------------------------------------------------------------------------
/// A helper class to hold combined activity data
class ActivityLogItem {
  final DocumentSnapshot snapshot;
  final String itemType; // 'issue' or 'contract'
  final DateTime timestamp;

  ActivityLogItem({
    required this.snapshot,
    required this.itemType,
    required this.timestamp,
  });
}

// -----------------------------------------------------------------------------
// --- User Profile Page ---
// -----------------------------------------------------------------------------
class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // A Future to fetch the user's data
  late final Future<DocumentSnapshot> _userFuture;

  // --- ADDED ---
  // A Stream to hold the combined activity list
  late Stream<List<ActivityLogItem>> _activityStream;
  // A flag to ensure the stream is only initialized once
  bool _streamInitialized = false;
  // --- END ADDED ---

  @override
  void initState() {
    super.initState();
    // Initialize the future in initState
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  // --- ADDED ---
  /// Helper function to safely extract a DateTime from a snapshot
  DateTime _safeExtractTimestamp(DocumentSnapshot doc, String fieldName) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey(fieldName) && data[fieldName] is Timestamp) {
        return (data[fieldName] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error extracting timestamp: $e');
    }
    // Return a very old date if not found
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Initializes the combined activity stream for the given NIC
  Stream<List<ActivityLogItem>> _initializeActivityStream(String nic) {
    final firestore = FirebaseFirestore.instance;

    // 1. Stream for 'issues' created by this user
    Stream<List<ActivityLogItem>> issuesStream = firestore
        .collection('issues')
        .where('addedByNic', isEqualTo: nic) // Based on your screenshot
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return ActivityLogItem(
                snapshot: doc,
                itemType: 'issue',
                timestamp: _safeExtractTimestamp(doc, 'timestamp'),
              );
            }).toList());

    // 2. Stream for 'contract_details' submitted by this user
    Stream<List<ActivityLogItem>> contractsStream = firestore
        .collection('contract_details')
        .where('submitBy', isEqualTo: nic) // Based on your screenshot
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return ActivityLogItem(
                snapshot: doc,
                itemType: 'contract',
                timestamp: _safeExtractTimestamp(doc, 'timestamp'),
              );
            }).toList());

    // 3. Combine the two streams
    return CombineLatestStream.list<List<ActivityLogItem>>([
      issuesStream,
      contractsStream,
    ])
        .map((List<List<ActivityLogItem>> allLists) {
      // 4. Flatten the list (List<List<Item>> -> List<Item>)
      final List<ActivityLogItem> combinedList =
          allLists.expand((list) => list).toList();

      // 5. Sort the combined list by timestamp (newest first)
      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 6. Take the top 5 most recent items from all collections
      return combinedList.take(5).toList();
    });
  }
  // --- END ADDED ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          // 1. Show loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Show error
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data.'));
          }

          // 3. Check if user exists
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          // 4. If data is loaded, extract it
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          // Extract data with fallbacks
          final String name = userData['name'] ?? 'No Name';
          final String email = userData['email'] ?? 'No Email';
          final String nic = userData['nic'] ?? 'No NIC'; // <-- IMPORTANT
          final String mobile = userData['mobilePhone'] ?? 'No Phone';
          final String userType = userData['userType'] ?? 'No Role';
          final String schoolName = userData['schoolName'] ?? 'No School';
          final bool isActive = userData['isActive'] ?? false;
          final String profileImageUrl = userData['profile_image'] ?? '';

          // --- MODIFIED ---
          // Initialize the stream ONCE, now that we have the NIC
          if (nic.isNotEmpty && !_streamInitialized) {
            _activityStream = _initializeActivityStream(nic);
            _streamInitialized = true;
          } else if (!_streamInitialized) {
            // No NIC or already tried, set to empty stream
            _activityStream = Stream.value([]);
            _streamInitialized = true;
          }
          // --- END MODIFIED ---

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // <-- MODIFIED
              children: [
                // --- Profile Image ---
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: (profileImageUrl.isNotEmpty)
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: (profileImageUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center( // <-- Added Center
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center( // <-- Added Center
                  child: Text(
                    userType,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // --- Active Status Badge ---
                Center( // <-- Added Center
                  child: Chip(
                    label: Text(
                      isActive ? 'Active' : 'Deactivated',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: isActive ? Colors.green : Colors.red,
                    avatar: Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                // --- User Details List ---
                _buildDetailRow(Icons.email, 'Email', email),
                _buildDetailRow(Icons.phone, 'Mobile Phone', mobile),
                _buildDetailRow(Icons.badge, 'NIC', nic),
                _buildDetailRow(Icons.school, 'School', schoolName),

                // --- ADDED: Recent Activity Section ---
                const SizedBox(height: 24),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<ActivityLogItem>>(
                  stream: _activityStream,
                  builder: (context, activitySnapshot) {
                    // 1. Show loading spinner
                    if (activitySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // 2. Show error
                    if (activitySnapshot.hasError) {
                      print('Activity Stream Error: ${activitySnapshot.error}');
                      return const Center(
                          child: Text('Error loading activity.'));
                    }

                    // 3. Show message if no activities are found
                    if (!activitySnapshot.hasData ||
                        activitySnapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No recent activity found.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      );
                    }

                    // 4. Build the list
                    final activities = activitySnapshot.data!;
                    return Column(
                      children: activities
                          .map((item) => _buildActivityItem(item))
                          .toList(),
                    );
                  },
                ),
                // --- END ADDED ---
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to build detail rows (Unchanged)
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600),
          const SizedBox(width: 16),
          // Use Flexible to prevent overflow if value is too long
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle long text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ADDED ---
  /// Helper widget to build an activity list item
  Widget _buildActivityItem(ActivityLogItem item) {
    IconData icon;
    String title;
    String subtitle;
    final data = item.snapshot.data() as Map<String, dynamic>;

    switch (item.itemType) {
      case 'issue':
        icon = Icons.error_outline;
        title = 'Submitted Issue';
        subtitle = data['issueTitle'] ?? 'Unknown Issue';
        break;
      case 'contract':
        icon = Icons.assignment;
        title = 'Submitted Contract';
        subtitle = data['contractorName'] ?? 'Unknown Contract';
        break;
      default:
        icon = Icons.history;
        title = 'Unknown Activity';
        subtitle = 'An action was recorded.';
    }

    return Card(
      elevation: 1,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade600),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(
          DateFormat.yMd().format(item.timestamp), // e.g., "11/7/2025"
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
  // --- END ADDED ---
}