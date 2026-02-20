import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Sound
import 'add_school_details_page.dart';
import 'add_building_issues_page.dart';
import 'add_school_master_plan_page.dart';
import 'profile.dart';
import 'settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'IssueDetailScreen.dart';
import 'notification_page.dart';

class PrincipalDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PrincipalDashboard({super.key, required this.userData});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  static const Color _primaryColor = Color(0xFF53BDFF);
  
  // To track notification count for sound alert
  int _previousUnreadCount = -1; 

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      // Home
    } else if (index == 1) {
      // Profile
      if (widget.userData != null) {
        final String principalId = widget.userData!['uid'] ?? 'principal_doc_id_123';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userData: widget.userData!,
              userId: principalId,
            ),
          ),
        );
      }
    } else if (index == 2) {
      // Settings
      if (widget.userData != null) {
        final String principalId = widget.userData!['uid'] ?? 'principal_doc_id_123';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(
              userData: widget.userData!,
              userId: principalId,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userData == null ||
        widget.userData!['name'] == null ||
        widget.userData!['schoolName'] == null ||
        widget.userData!['nic'] == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Error loading data")),
      );
    }

    final String userNic = widget.userData!['nic'];
    final String principalName = widget.userData!['name'];
    final String schoolName = widget.userData!['schoolName'];
    final String? profileImageUrl = widget.userData!['profile_image'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Pass context and userNic to the header
              _buildWelcomeHeader(context, principalName, schoolName, profileImageUrl, userNic),
              
              const SizedBox(height: 30),

              _buildActionButton(
                icon: Icons.add,
                text: 'Add Your School Details',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddSchoolDetailsPage(
                        userNic: userNic,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              _buildActionButton(
                icon: Icons.build_outlined,
                text: 'Add Building Issues',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBuildingIssuesPage(
                        userNic: userNic,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              _buildActionButton(
                icon: Icons.map_outlined,
                text: 'Manage Master Plans',
                onTap: () {
                  final String schoolName = widget.userData!['schoolName'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMasterPlanScreen(
                        schoolName: schoolName,
                        userNic: userNic,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
              _buildReportedIssuesSection(userNic),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 30), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 30),
              label: 'Settings'),
        ],
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String fullName, String schoolName, String? imageUrl, String userNic) {
    String firstName = fullName;
    if (fullName.contains(' ')) {
      firstName = fullName.split(' ')[0];
    }
    if (firstName.isNotEmpty) {
      firstName = firstName[0].toUpperCase() + firstName.substring(1);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 60, 
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor,
              image: (imageUrl != null && imageUrl.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(Icons.person, size: 35, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 15),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back, $firstName!',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Principal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // --- NOTIFICATION ICON WITH BADGE AND SOUND ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('receiverNic', isEqualTo: userNic)
                .where('isRead', isEqualTo: false) 
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
                
                // SOUND LOGIC: If count increased, play sound
                if (_previousUnreadCount != -1 && unreadCount > _previousUnreadCount) {
                   // Play system sound (Click/Alert)
                   SystemSound.play(SystemSoundType.click); 
                }
                // Update tracker
                _previousUnreadCount = unreadCount;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 30, color: Colors.black54),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    },
                  ),
                  // Red Badge
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
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
        ],
      ),
    );
  }

  // ... (Keep your other helper widgets: _buildActionButton, _buildIssueCard, etc. exactly as they were) ...
  
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Icon(icon, size: 30, color: _primaryColor),
                ),
                const SizedBox(width: 20),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCard({
    required BuildContext context,
    required String issueId,
    required Map<String, dynamic> issueData,
    required String userNic,
    required String title,
    required String status,
    required String date,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      shadowColor: Colors.grey.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.home_work_outlined, size: 40, color: Colors.grey[700]),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(status,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[600])),
                  Text(date,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => IssueDetailScreen(
                      issueData: issueData,
                      issueId: issueId,
                      userNic: userNic,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child:
                  const Text('View Details', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportedIssuesSection(String userNic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'My Reported Issues',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('issues')
              .where('addedByNic', isEqualTo: userNic)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text("Error loading issues: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("You have not reported any issues yet."),
                ),
              );
            }

            final issues = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issueDoc = issues[index];
                final data = issueDoc.data() as Map<String, dynamic>;
                final String issueId = issueDoc.id;
                final Map<String, dynamic> issueData = data;

                final String title = data['issueTitle'] ?? 'No Title';
                final String building = data['buildingName'] ?? 'N/A';
                final String status = data['status'] ?? 'N/A';

                String formattedDate = 'Date N/A';
                if (data['dateOfOccurance'] != null) {
                  final Timestamp timestamp = data['dateOfOccurance'];
                  formattedDate =
                      DateFormat('yyyy-MM-dd').format(timestamp.toDate());
                }

                return _buildIssueCard(
                  title: title,
                  status: '$building • $status',
                  date: formattedDate,
                  context: context,
                  issueId: issueId,
                  issueData: issueData,
                  userNic: userNic,
                );
              },
            );
          },
        ),
      ],
    );
  }
}