import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// NOTE: You must have these pages in your project for navigation to work.
import 'manage_to_page.dart';
import 'manage_principals_page.dart';
import 'manage_schools_page.dart';
import 'pending_approvals_page.dart';

// -----------------------------------------------------------------------------
//                                MAIN WIDGETS
// -----------------------------------------------------------------------------

class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DashboardHeader({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final userName = userData['name'] ?? 'User';
    final userType = userData['userType'] ?? 'District Engineer';

    return DashboardCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $userName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userType,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardOverview extends StatelessWidget {
  final bool isLoading;
  final int totalSchools;
  final int activeTOs;
  final int pendingRequests;
  final String userNic;

  const DashboardOverview({
    super.key,
    required this.isLoading,
    required this.totalSchools,
    required this.activeTOs,
    required this.pendingRequests,
    required this.userNic,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const DashboardCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _OverviewCard('Total Schools', totalSchools.toString()),
              _OverviewCard('Active TOs', activeTOs.toString()),
              _OverviewCard('Pending', pendingRequests.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ManageButton('Manage Schools', userNic: userNic),
              _ManageButton('Manage TOs', userNic: userNic),
              _ManageButton('Manage Principals', userNic: userNic),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔥 SECTION: Recent Issues (MODIFIED FOR FIXED SCROLLABLE HEIGHT)
class RecentIssuesSection extends StatelessWidget {
  const RecentIssuesSection({super.key});

  // Approximate height of one list item including padding/dividers
  static const double _itemHeight = 80.0; 
  // Maximum items to display (3) * item height = 240.0
  static const double _maxDisplayHeight = _itemHeight * 3; 

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The title is placed here, outside the fixed-height scroll area
          const SectionTitle('Recent Issues Reported'), 
          const SizedBox(height: 8),

          // 1. Set a fixed height for the scrollable area
          SizedBox(
            height: _maxDisplayHeight, 
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .orderBy('timestamp', descending: true) 
                  // Do NOT limit the query here, ListView handles scroll limit
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading issues: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent issues found.'));
                }

                final issueDocs = snapshot.data!.docs;
                
                // 2. Use ListView.builder to handle the potentially long list and scrolling
                return ListView.builder(
                  // physics: const ClampingScrollPhysics(), // Optional: use to prevent "bouncing" 
                  itemCount: issueDocs.length,
                  itemBuilder: (context, index) {
                    final issue = issueDocs[index].data() as Map<String, dynamic>;
                    final docId = issueDocs[index].id;

                    // Extract Issue details
                    final issueTitle = issue['issueTitle'] ?? 'No Title';
                    final damageType = issue['damageType'] ?? 'Unknown Damage';
                    final schoolName = issue['schoolName'] ?? 'Unknown School';
                    final status = issue['status'] ?? 'Pending';
                    
                    String formattedDate = 'No Date/Time';
                    if (issue['timestamp'] is Timestamp) {
                      final timestamp = issue['timestamp'] as Timestamp;
                      final dateTime = timestamp.toDate();
                      formattedDate = DateFormat('MMM d, yyyy h:mm a').format(dateTime);
                    }

                    final title = issueTitle;
                    final subtitle = '$damageType at $schoolName - $status';
                    
                    // 3. Render the item and a divider
                    return Column(
                      children: [
                        _IssueActivityItem(
                          title: title,
                          subtitle: subtitle,
                          status: status,
                          timestamp: formattedDate,
                          docId: docId,
                        ),
                        if (index < issueDocs.length - 1)
                          const Divider(height: 1, thickness: 1),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🔥 SECTION: Recent Users
class RecentUsersSection extends StatelessWidget {
  const RecentUsersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Recent User Signups'),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(5) // Limiting this section to 5 items
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading users: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No recent users found.'));
              }

              final userDocs = snapshot.data!.docs;

              return Column(
                children: List.generate(userDocs.length, (index) {
                  final user = userDocs[index].data() as Map<String, dynamic>;
                  final docId = userDocs[index].id;

                  final name = user['name'] ?? 'No Name';
                  final userType = user['userType'] ?? 'No Role';
                  
                  String formattedDate = 'No Date';
                  if (user['createdAt'] is Timestamp) {
                    final timestamp = user['createdAt'] as Timestamp;
                    final dateTime = timestamp.toDate();
                    formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
                  }

                  final title = 'New User: $name';
                  final subtitle = '$userType - Joined: $formattedDate';

                  return Column(
                    children: [
                      _UserActivityItem(
                        title: title,
                        subtitle: subtitle,
                        docId: docId,
                      ),
                      if (index < userDocs.length - 1)
                        const Divider(),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ApprovalRequestSection extends StatelessWidget {
  const ApprovalRequestSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text('• Manel Withana requested to register as a TO.'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingApprovalsPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade300,
              foregroundColor: Colors.white,
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//                                HELPER WIDGETS
// -----------------------------------------------------------------------------

class DashboardCard extends StatelessWidget {
  final Widget child;
  const DashboardCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String count;
  const _OverviewCard(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ManageButton extends StatelessWidget {
  final String label;
  final String userNic;

  const _ManageButton(this.label, {required this.userNic});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            if (label == 'Manage Schools') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageSchoolsPage(userNic: userNic),
                ),
              );
            } else if (label == 'Manage TOs') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageTechnicalOfficersPage(),
                ),
              );
            } else if (label == 'Manage Principals') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManagePrincipalsPage(),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ),
      ),
    );
  }
}

// Helper widget to display recent issue activity
class _IssueActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String timestamp;
  final String docId;

  const _IssueActivityItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.timestamp,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the color and icon for the status
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case 'approved':
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.build;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(timestamp,
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement navigation to a specific issue details page using docId
              print('View details for issue: $docId');
            },
            child: const Text('View Issue'),
          ),
        ],
      ),
    );
  }
}

// Helper widget to display recent user sign-ups
class _UserActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String docId; 

  const _UserActivityItem({
    required this.title,
    required this.subtitle,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Icon representing a person
          const Icon(Icons.person_add_alt_1_outlined, color: Colors.teal, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement navigation to a user details page
              print('View details for user: $docId');
            },
            child: const Text('View User'),
          ),
        ],
      ),
    );
  }
}