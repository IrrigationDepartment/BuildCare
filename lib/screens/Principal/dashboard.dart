import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:intl/intl.dart';

// Import your application pages
import 'add_school_details_page.dart';
import 'add_building_issues_page.dart';
import 'add_school_master_plan_page.dart';
import 'profile.dart';
import 'settings_page.dart'; 
import 'IssueDetailScreen.dart';
import 'notification_page.dart';

class PrincipalDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const PrincipalDashboard({super.key, required this.userData});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  // Using blueAccent consistently across the dashboard
  static const Color _themeColor = Colors.blueAccent;
  static const Color _accentCyan = Color(0xFF00E5FF); 
  int _previousUnreadCount = -1; 

  // Function to show a snackbar when a new notification arrives
  void _triggerNewNotificationAlert(String message) {
    SystemSound.play(SystemSoundType.click);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text("New Notification: $message")),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.indigo[900],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: _accentCyan,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen(loggedNic: widget.userData!['nic'])));
          },
        ),
      ),
    );
  }

  // Handle Bottom Navigation Bar taps
  void _onItemTapped(BuildContext context, int index) {
    if (index == 1) { // Profile Page
      final String principalId = widget.userData!['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      
      if (principalId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Cannot identify user.")));
        return;
      }
      
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userData: widget.userData!, userId: principalId)));
    } else if (index == 2) { // Settings Page
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userData == null) return const Scaffold(body: Center(child: Text("Error loading data")));

    final String userNic = widget.userData!['nic'];
    final String schoolName = widget.userData!['schoolName'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isLargeScreen = constraints.maxWidth > 800;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isLargeScreen ? 1000 : double.infinity),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Real-time Header section (Blue Accent Background)
                      _buildWelcomeHeader(context, userNic),
                      const SizedBox(height: 30),

                      // Quick Action Buttons (Icons updated to Blue Accent)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isLargeScreen ? 3 : 1,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: isLargeScreen ? 2.5 : 4.5,
                        children: [
                          _buildActionButton(
                            icon: Icons.add_circle_outline,
                            text: 'School Details',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddSchoolDetailsPage(userNic: userNic))),
                          ),
                          _buildActionButton(
                            icon: Icons.build_outlined,
                            text: 'Building Issues',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddBuildingIssuesPage(userNic: userNic))),
                          ),
                          _buildActionButton(
                            icon: Icons.map_outlined,
                            text: 'Master Plans',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddMasterPlanScreen(schoolName: schoolName, userNic: userNic))),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      _buildReportedIssuesSection(userNic, isLargeScreen),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: _themeColor, // Bottom navigation home icon color updated
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }

  // Header UI: Styled with blueAccent background and white fonts/icons
  Widget _buildWelcomeHeader(BuildContext context, String userNic) {
    final String userId = widget.userData!['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        
        String fullName = widget.userData!['name'] ?? 'User';
        String? imageUrl = widget.userData!['profile_image'];

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final liveData = userSnapshot.data!.data() as Map<String, dynamic>;
          fullName = liveData['name'] ?? fullName;
          imageUrl = liveData['profile_image'] ?? imageUrl;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeColor, 
            borderRadius: BorderRadius.circular(20), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35, 
                backgroundColor: Colors.white24, 
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null, 
                child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 35) : null
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text(
                      'Welcome Back!', 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullName, 
                      style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Principal', 
                      style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('receiverNic', isEqualTo: userNic)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    int unreadCount = snapshot.data!.docs.length;
                    
                    if (_previousUnreadCount != -1 && unreadCount > _previousUnreadCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _triggerNewNotificationAlert(snapshot.data!.docs.first['message'] ?? "New update received");
                      });
                    }
                    _previousUnreadCount = unreadCount;

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, size: 28, color: Colors.white), 
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen(loggedNic: userNic)))
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 12, 
                            top: 12,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.redAccent, 
                                shape: BoxShape.circle,
                                border: Border.all(color: _themeColor, width: 2)
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.notifications_none, size: 28, color: Colors.white),
                  );
                },
              ),
            ],
          ),
        );
      }
    );
  }

  // Updated Action card builder with blueAccent icons
  Widget _buildActionButton({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: Colors.grey.withOpacity(0.1))
        ),
        child: Row(
          children: [
            Icon(icon, color: _themeColor, size: 28), // Icon color updated to blueAccent
            const SizedBox(width: 15),
            Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportedIssuesSection(String userNic, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reported Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('issues').where('addedByNic', isEqualTo: userNic).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            var issues = snapshot.data!.docs;
            return isLargeScreen 
              ? Wrap(
                  spacing: 20, runSpacing: 20,
                  children: issues.map((doc) => SizedBox(width: 450, child: _issueItem(doc))).toList(),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: issues.length,
                  itemBuilder: (context, index) => _issueItem(issues[index]),
                );
          },
        ),
      ],
    );
  }

  Widget _issueItem(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.report_problem_outlined, color: _themeColor), // Added icon for visual appeal
        title: Text(data['issueTitle'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${data['buildingName']} • ${data['status']}"),
        trailing: const Icon(Icons.chevron_right, color: _themeColor), // Chevron updated to theme color
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => IssueDetailScreen(issueData: data, issueId: doc.id, userNic: widget.userData!['nic']))),
      ),
    );
  }
}