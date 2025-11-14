// lib/provincial_engineer_dashboard.dart (or dashboard.dart)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
// NEW IMPORT: Issues View link
import 'view_issues.dart';
// IMPORT FOR DATE FORMATTING
import 'package:intl/intl.dart'; 
// ADDED IMPORT FOR SETTINGS PAGE
import 'settings.dart'; 

// -----------------------------------------------------------------------------
// --- HELPER CLASS: ActivityItem (For Dashboard Activity Stream) ---
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
  
  // Placeholder user data extraction
  String get _userName => widget.userData?['name'] ?? 'Engineer';

  @override
  void initState() {
    super.initState();
    _initializeActivityStream();
  }
  
  // Helper function for safe timestamp extraction
  DateTime _safeExtractTimestamp(DocumentSnapshot doc, String fieldName) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey(fieldName) && data[fieldName] is Timestamp) {
        return (data[fieldName] as Timestamp).toDate();
      }
    } catch (e) {
      // In a real app, you might log this error
    }
    return DateTime.fromMillisecondsSinceEpoch(0); // Fallback date
  }


  void _initializeActivityStream() {
    // 1. Get streams for Issues
    final issuesStream = _firestore
        .collection('issues')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityItem(
              snapshot: doc,
              itemType: 'Issue',
              timestamp: _safeExtractTimestamp(doc, 'timestamp'), // Use helper
            )).toList());

    // 2. Combine all streams into one sorted list (using rxdart)
    _activityStream = issuesStream.map((issues) {
      final allItems = [...issues];
      // Sort all items by timestamp
      allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allItems;
    });
  }

  // Helper function to build the main grid item
  Widget _buildGridItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFFE8F2FF),
        elevation: 1,
        automaticallyImplyLeading: false, // Prevents back button on main screen
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Message
            Text(
              'Welcome, $_userName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 2. Quick Access Grid
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildGridItem(
                  title: 'View All Issues',
                  icon: Icons.list_alt,
                  color: Colors.blue.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewIssuesPage(),
                      ),
                    );
                  },
                ),
                _buildGridItem(
                  title: 'Manage Users',
                  icon: Icons.group,
                  color: Colors.green.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllUsersPage(userType: 'Provincial Engineer'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 3. Recent Activity Stream
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<ActivityItem>>(
              stream: _activityStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading activity: ${snapshot.error}'));
                }
                final activityList = snapshot.data ?? [];

                if (activityList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Text('No recent activity found.'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activityList.length,
                  itemBuilder: (context, index) {
                    final item = activityList[index];
                    final data = item.snapshot.data() as Map<String, dynamic>;
                    final title = data['issueTitle'] ?? data['name'] ?? 'Untitled Item';
                    final date = DateFormat('MMM d, h:mm a').format(item.timestamp);
                    final subtitle = item.itemType == 'Issue'
                        ? 'New Issue: ${data['schoolName'] ?? 'N/A'}'
                        : 'New User: ${data['userType'] ?? 'N/A'}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      child: ListTile(
                        leading: Icon(
                          item.itemType == 'Issue' ? Icons.warning_amber : Icons.person_add,
                          color: item.itemType == 'Issue' ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$subtitle\n$date'),
                        isThreeLine: true,
                        onTap: () {
                          if (item.itemType == 'Issue') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IssueDetailPage(issueId: item.snapshot.id),
                              ),
                            );
                          }
                          // Add navigation for other item types if needed
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      // Custom Bottom Nav Bar
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

// -----------------------------------------------------------------------------
// --- IssueDetailPage (Issue Details Viewer - UPDATED IMAGE SIZE 100x100) ---
// -----------------------------------------------------------------------------
class IssueDetailPage extends StatelessWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

  // Helper function to determine status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
      case 'Pending':
        return Colors.orange.shade700;
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Resolved':
        return Colors.green.shade700;
      case 'Closed':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Helper: To build styled read-only fields
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100], // Background color for the field
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Helper for bottom details
  Widget _buildDetailRow(String label, String value, {Color valueColor = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor,
                fontWeight: FontWeight.normal,
              ),
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
        future: FirebaseFirestore.instance.collection('issues').doc(issueId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Issue not found.'));
          }

          final issueData = snapshot.data!.data() as Map<String, dynamic>;
          
          final issueTitle = issueData['issueTitle'] ?? 'N/A';
          final damageType = issueData['damageType'] ?? 'N/A';
          final description = issueData['description'] ?? 'No description provided.';
          final status = issueData['status'] ?? 'N/A';
          final List<String> imageUrls = List<String>.from(issueData['imageUrls'] ?? []);
          
          // Date formatting logic
          String damageDateStr = 'N/A';
          Timestamp? dateTimestamp;
          if (issueData.containsKey('damageDate') && issueData['damageDate'] is Timestamp) {
            dateTimestamp = issueData['damageDate'] as Timestamp;
          } else if (issueData.containsKey('timestamp') && issueData['timestamp'] is Timestamp) {
            dateTimestamp = issueData['timestamp'] as Timestamp;
          }
          if (dateTimestamp != null) {
            damageDateStr = DateFormat('yyyy/MM/dd').format(dateTimestamp.toDate());
          }
          // End Date formatting logic
          
          Color statusColor = _getStatusColor(status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 1. Issue Title Field
                _buildReadOnlyField(
                  label: 'Report Title/ID',
                  value: issueTitle,
                ),
                // 2. Type of Damage
                _buildReadOnlyField(
                  label: 'Type Of Damage',
                  value: damageType,
                ),
                // 3. Description of Issue (Multilinie)
                _buildReadOnlyField(
                  label: 'Description of Issue',
                  value: description,
                  maxLines: 5,
                ),
                // 4. Date of Damage Occurance
                _buildReadOnlyField(
                  label: 'Date of Damage Occurance',
                  value: damageDateStr,
                ),
                
                // --- Other Details ---
                const SizedBox(height: 10),
                _buildDetailRow('School Name', issueData['schoolName'] ?? 'N/A'),
                _buildDetailRow('Reported By', issueData['reportedBy'] ?? 'N/A'),
                _buildDetailRow('Zone', issueData['educationalZone'] ?? 'N/A'),
                _buildDetailRow('Status', status, valueColor: statusColor),
                
                const Divider(height: 40),
                
                // 6. Attached Images Section
                const Text(
                  'Attached Images:', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10),

                if (imageUrls.isNotEmpty)
                  Wrap( 
                    spacing: 8.0, 
                    runSpacing: 8.0,
                    children: imageUrls.map((url) {
                      return InkWell( 
                        onTap: () {
                          // Implement full-screen image viewer here if needed
                        },
                        child: Container(
                          //UPDATE: REDUCED HEIGHT AND WIDTH TO 100x100 FOR COMPACT VIEW
                          width: 100, 
                          height: 100, 
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text('Image Load Failed', textAlign: TextAlign.center),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ) 
                else 
                  // Placeholder if no images are present
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
                
                // --- Action Buttons (Optional) ---
                
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- Placeholder Pages (Used in Navigation) ---
// -----------------------------------------------------------------------------

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

// REMOVED: SettingsPage placeholder class is removed here. 
// We are now importing and using the real SettingsPage from 'settings.dart'.

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
          'All Users Page Placeholder for $userType',
          style: const TextStyle(fontSize: 20, color: Colors.black54),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1), // Assuming this navigates to the Profile tab index
    );
  }
}

// -----------------------------------------------------------------------------
// --- Custom Bottom Navigation Bar ---
// -----------------------------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    // Prevent navigating away from the current tab unless necessary
    if (index == currentIndex) return;

    Widget newPage;
    switch (index) {
      case 0:
        // Dashboard
        newPage = const ProvincialEngineerDashboard();
        break;
      case 1:
        // Profile Page
        newPage = const ProfilePage();
        break;
      case 2:
        // 🚀 UPDATED: Navigating to the actual SettingsPage
        // NOTE: settings.dart must be imported at the top of this file.
        newPage = const SettingsPage(); 
        break;
      default:
        return;
    }
    
    // Use pushReplacement to replace the current screen in the navigation stack
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => newPage),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Home icon
          IconButton(
            icon: Icon(
              Icons.home_outlined, 
              color: currentIndex == 0 ? Colors.blue : Colors.black54, 
              size: 30
            ),
            onPressed: () => _onItemTapped(context, 0),
          ),
          // Profile icon
          IconButton(
            icon: Icon(
              Icons.person_outline, 
              color: currentIndex == 1 ? Colors.blue : Colors.black54, 
              size: 30
            ),
            onPressed: () => _onItemTapped(context, 1),
          ),
          // Settings icon
          IconButton(
            icon: Icon(
              Icons.settings_outlined, 
              color: currentIndex == 2 ? Colors.blue : Colors.black54, 
              size: 30
            ),
            onPressed: () => _onItemTapped(context, 2),
          ),
        ],
      ),
    );
  }
}