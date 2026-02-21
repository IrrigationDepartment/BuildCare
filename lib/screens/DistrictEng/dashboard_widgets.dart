import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'manage_to_page.dart';
import 'manage_principals_page.dart';
import 'manage_schools_page.dart';
import 'damage_details_dialog.dart'; 
import 'SchoolDetailsDialog.dart'; 

// -----------------------------------------------------------------------------
//                                THEME CONSTANTS
// -----------------------------------------------------------------------------
const Color primaryColor = Color(0xFF1E3A8A); // Deep Indigo
const Color secondaryColor = Color(0xFF0D9488); // Teal
const Color cardColor = Colors.white;
const Color textPrimary = Color(0xFF111827);
const Color textSecondary = Color(0xFF6B7280);

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

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: const Icon(Icons.person_rounded, size: 30, color: primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
              ),
              Text(
                userName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary, height: 1.2),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                userType,
                style: const TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardOverview extends StatelessWidget {
  final bool isLoading;
  final int totalSchools;
  final int totalTOs;
  final int totalPrincipals; 
  final String userNic;

  const DashboardOverview({
    super.key,
    required this.isLoading,
    required this.totalSchools,
    required this.totalTOs,
    required this.totalPrincipals,
    required this.userNic,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const DashboardCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: primaryColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Overview'),
        const SizedBox(height: 16),
        
        // --- BALANCED METRICS LAYOUT ---
        // Top Card: Full Width (Total Schools)
        _buildHighlightCard(
          title: 'Total Schools',
          count: totalSchools.toString(),
          icon: Icons.school_rounded,
          color: const Color(0xFF4F46E5), // Indigo
        ),
        const SizedBox(height: 12),
        
        // Bottom Cards: 50/50 Split (TOs and Principals)
        Row(
          children: [
            Expanded(
              child: _buildStandardCard(
                title: 'Tech Officers',
                count: totalTOs.toString(),
                icon: Icons.engineering_rounded,
                color: const Color(0xFF0EA5E9), // Sky Blue
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStandardCard(
                title: 'Principals',
                count: totalPrincipals.toString(),
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFF10B981), // Emerald
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const SectionTitle('Quick Actions'),
        const SizedBox(height: 16),
        
        // --- QUICK ACTIONS ROW ---
        DashboardCard(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionIcon(
                label: 'Schools',
                icon: Icons.domain_rounded,
                color: const Color(0xFF4F46E5),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSchoolsPage(userNic: userNic))),
              ),
              _ActionIcon(
                label: 'Officers',
                icon: Icons.engineering_rounded,
                color: const Color(0xFF0EA5E9),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageTechnicalOfficersPage())),
              ),
              _ActionIcon(
                label: 'Principals',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePrincipalsPage())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Large Highlight Card
  Widget _buildHighlightCard({required String title, required String count, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color, height: 1.0)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
        ],
      ),
    );
  }

  // Half-width Standard Card
  Widget _buildStandardCard({required String title, required String count, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, height: 1.0)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//                            RECENT SECTIONS
// -----------------------------------------------------------------------------

class RecentIssuesSection extends StatelessWidget {
  const RecentIssuesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Recent Issues'),
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 280, 
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .orderBy('timestamp', descending: true) 
                  .limit(10) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No recent issues.', style: TextStyle(color: textSecondary)));

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final issue = doc.data() as Map<String, dynamic>;
                    
                    String formattedDate = 'No Date';
                    if (issue['timestamp'] is Timestamp) {
                      formattedDate = DateFormat('MMM d, h:mm a').format((issue['timestamp'] as Timestamp).toDate());
                    }

                    return _IssueActivityItem(
                      title: issue['issueTitle'] ?? 'No Title',
                      subtitle: '${issue['damageType'] ?? 'Unknown'} • ${issue['schoolName'] ?? 'Unknown'}',
                      status: issue['status'] ?? 'Pending',
                      timestamp: formattedDate,
                      docId: doc.id,
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

class RecentSchoolsSection extends StatelessWidget {
  const RecentSchoolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('New Schools'), 
          const SizedBox(height: 12),

          SizedBox(
            height: 250, 
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .orderBy('lastEditedAt', descending: true) 
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No schools found.', style: TextStyle(color: textSecondary)));

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final school = doc.data() as Map<String, dynamic>;
                    
                    String date = 'N/A';
                    if (school['lastEditedAt'] is Timestamp) {
                      date = DateFormat('MMM d, yyyy').format((school['lastEditedAt'] as Timestamp).toDate());
                    }

                    return _SchoolActivityItem(
                      title: school['schoolName'] ?? 'No Name',
                      subtitle: '${school['schoolType'] ?? 'N/A'} • Added $date',
                      docId: doc.id,
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

class RecentUsersSection extends StatelessWidget {
  const RecentUsersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Recent User Signups'),
          const SizedBox(height: 12),

          SizedBox(
            height: 250,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No recent users.', style: TextStyle(color: textSecondary)));

                final userDocs = snapshot.data!.docs.where((doc) {
                  final type = ((doc.data() as Map<String, dynamic>)['userType'] as String?)?.toLowerCase().trim();
                  return type == 'technical officer' || type == 'principal';
                }).take(5).toList();

                if (userDocs.isEmpty) return const Center(child: Text('No TO or Principal users found.', style: TextStyle(color: textSecondary)));

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: userDocs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        itemBuilder: (context, index) {
                          final user = userDocs[index].data() as Map<String, dynamic>;
                          String date = 'N/A';
                          if (user['createdAt'] is Timestamp) date = DateFormat('MMM d, yyyy').format((user['createdAt'] as Timestamp).toDate());

                          return _UserActivityItem(
                            title: user['name'] ?? 'No Name',
                            subtitle: '${user['userType'] ?? 'No Role'} • $date',
                            docId: userDocs[index].id,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: userDocs[index].id))),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//                              HELPER COMPONENTS
// -----------------------------------------------------------------------------

class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DashboardCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
    );
  }
}

class _IssueActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String timestamp;
  final String docId;

  const _IssueActivityItem({required this.title, required this.subtitle, required this.status, required this.timestamp, required this.docId});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'pending': statusColor = const Color(0xFFF59E0B); break; 
      case 'approved': 
      case 'resolved': statusColor = const Color(0xFF10B981); break; 
      case 'rejected': statusColor = const Color(0xFFEF4444); break; 
      default: statusColor = const Color(0xFF6366F1); break; 
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      leading: Container(
        height: 44, width: 44,
        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.assignment_late_rounded, color: statusColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(timestamp, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DamageDetailsDialog(issueId: docId))),
    );
  }
}

class _SchoolActivityItem extends StatelessWidget {
  final String title, subtitle, docId;
  const _SchoolActivityItem({required this.title, required this.subtitle, required this.docId});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        height: 44, width: 44,
        decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.domain_rounded, color: primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 14)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: const TextStyle(fontSize: 12, color: textSecondary)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SchoolDetailsPage(schoolId: docId))),
    );
  }
}

class _UserActivityItem extends StatelessWidget {
  final String title, subtitle, docId;
  final VoidCallback? onTap;
  const _UserActivityItem({required this.title, required this.subtitle, required this.docId, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        height: 44, width: 44,
        decoration: BoxDecoration(color: secondaryColor.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.person_add_alt_1_rounded, color: secondaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 14)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: const TextStyle(fontSize: 12, color: textSecondary)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

// -----------------------------------------------------------------------------
//                        FULL PAGES (All Users & Profile)
// -----------------------------------------------------------------------------

class AllUsersScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> users;
  final String title;

  const AllUsersScreen({super.key, required this.users, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(title: Text(title, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, centerTitle: true, elevation: 1, iconTheme: const IconThemeData(color: primaryColor)),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = users[index].data() as Map<String, dynamic>;
          final isActive = user['isActive'] == true;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage: user['profile_image'] != null && user['profile_image'].isNotEmpty ? NetworkImage(user['profile_image']) : null,
                child: user['profile_image'] == null || user['profile_image'].isEmpty ? const Icon(Icons.person, color: primaryColor) : null,
              ),
              title: Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(user['userType'] ?? 'No Role', style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.w500)),
                  Text(user['email'] ?? 'No Email', style: const TextStyle(fontSize: 13)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.grey)),
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: users[index].id))),
            ),
          );
        },
      ),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(title: const Text('User Profile', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, centerTitle: true, elevation: 1, iconTheme: const IconThemeData(color: primaryColor)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('User not found'));

          final user = snapshot.data!.data() as Map<String, dynamic>;
          
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildProfileHeader(context, user),
                    const SizedBox(height: 32),
                    _buildInfoCard(context, 'Personal Information', Icons.person_outline_rounded, [
                      _buildInfoRow('Name', user['name'] ?? 'Not provided'),
                      _buildInfoRow('NIC', user['nic'] ?? 'Not provided'),
                      _buildInfoRow('Email', user['email'] ?? 'Not provided'),
                      _buildInfoRow('Role', user['userType'] ?? 'Not provided'),
                    ]),
                    const SizedBox(height: 20),
                    _buildInfoCard(context, 'Contact Information', Icons.contact_phone_outlined, [
                      _buildInfoRow('Mobile', user['mobileNo'] ?? 'Not provided'),
                      _buildInfoRow('Office', user['office'] ?? 'Not provided'),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [primaryColor, secondaryColor])),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white,
            backgroundImage: user['profile_image'] != null && user['profile_image'].isNotEmpty ? NetworkImage(user['profile_image']) : null,
            child: user['profile_image'] == null || user['profile_image'].isEmpty ? const Icon(Icons.person, size: 50, color: primaryColor) : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 4),
        Text(user['email'] ?? 'No email', style: const TextStyle(fontSize: 16, color: textSecondary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(user['userType'] ?? 'No role', style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary))),
        ],
      ),
    );
  }
}