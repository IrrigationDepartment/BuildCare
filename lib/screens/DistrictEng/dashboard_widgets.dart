import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'manage_to_page.dart';
import 'manage_principals_page.dart';
import 'manage_schools_page.dart';
import 'damage_details_dialog.dart'; 
import 'SchoolDetailsDialog.dart'; 

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

class RecentIssuesSection extends StatelessWidget {
  const RecentIssuesSection({super.key});

  static const double _maxDisplayHeight = 240.0; 

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Recent Issues Reported'), 
          const SizedBox(height: 8),

          SizedBox(
            height: _maxDisplayHeight, 
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .orderBy('timestamp', descending: true) 
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
                
                return ListView.builder(
                  itemCount: issueDocs.length,
                  itemBuilder: (context, index) {
                    final issue = issueDocs[index].data() as Map<String, dynamic>;
                    final docId = issueDocs[index].id;

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

class RecentSchoolsSection extends StatelessWidget {
  const RecentSchoolsSection({super.key});

  static const double _maxDisplayHeight = 240.0; 

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Recent School Registrations'), 
          const SizedBox(height: 8),

          SizedBox(
            height: _maxDisplayHeight, 
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .orderBy('lastEditedAt', descending: true) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading schools: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent schools found.'));
                }

                final schoolDocs = snapshot.data!.docs;
                
                return ListView.builder(
                  itemCount: schoolDocs.length,
                  itemBuilder: (context, index) {
                    final school = schoolDocs[index].data() as Map<String, dynamic>;
                    final docId = schoolDocs[index].id;

                    final schoolName = school['schoolName'] ?? 'No Name';
                    final schoolType = school['schoolType'] ?? 'N/A';
                    final schoolAddress = school['schoolAddress'] ?? 'No Address';
                    
                    String formattedDate = 'No Date';
                    if (school['lastEditedAt'] is Timestamp) {
                      final timestamp = school['lastEditedAt'] as Timestamp;
                      final dateTime = timestamp.toDate();
                      formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
                    }

                    final title = schoolName;
                    final subtitle = '$schoolType - Added: $formattedDate';
                    
                    return Column(
                      children: [
                        _SchoolActivityItem(
                          title: title,
                          subtitle: subtitle,
                          address: schoolAddress,
                          docId: docId,
                        ),
                        if (index < schoolDocs.length - 1)
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

class RecentUsersSection extends StatelessWidget {
  const RecentUsersSection({super.key});
  
  static const double _maxDisplayHeight = 240.0; 

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Recent User Signups'),
          const SizedBox(height: 8),

          SizedBox(
            height: _maxDisplayHeight,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading users: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent users found.'));
                }

                // Filter users to show only Technical Officer and Principal
                final userDocs = snapshot.data!.docs.where((doc) {
                  final user = doc.data() as Map<String, dynamic>;
                  final userType = (user['userType'] as String?)?.toLowerCase().trim();
                  return userType == 'technical officer' || 
                         userType == 'principal';
                }).toList();

                if (userDocs.isEmpty) {
                  return const Center(child: Text('No Technical Officer or Principal users found.'));
                }

                // Show only up to 5 recent users in the list
                final displayUsers = userDocs.take(5).toList();

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: displayUsers.length,
                        itemBuilder: (context, index) {
                          final user = displayUsers[index].data() as Map<String, dynamic>;
                          final docId = displayUsers[index].id;

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
                                onTap: () {
                                  // Navigate to user profile when tapped
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(userId: docId),
                                    ),
                                  );
                                },
                              ),
                              if (index < displayUsers.length - 1)
                                const Divider(),
                            ],
                          );
                        },
                      ),
                    ),
                    
                    // "See More" button
                    if (userDocs.length > 5)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllUsersScreen(
                                  users: userDocs,
                                  title: 'Technical Officers & Principals',
                                ),
                              ),
                            );
                          },
                          child: const Text('See More'),
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

class _UserActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String docId;
  final VoidCallback? onTap;
  
  const _UserActivityItem({
    required this.title,
    required this.subtitle,
    required this.docId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar/icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AllUsersScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> users;
  final String title;

  const AllUsersScreen({
    super.key,
    required this.users,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = users[index].data() as Map<String, dynamic>;
          final docId = users[index].id;

          final name = user['name'] ?? 'No Name';
          final userType = user['userType'] ?? 'No Role';
          final email = user['email'] ?? 'No Email';
          final mobile = user['mobileNo'] ?? 'No Mobile';
          final isActive = user['isActive'] == true;
          final profileImage = user['profile_image'];

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: profileImage != null && profileImage.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profileImage),
                      )
                    : CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    userType,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mobile,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).primaryColor,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(userId: docId),
                  ),
                );
              },
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
  
  BuildContext? get context => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorState('User not found');
          }

          final user = snapshot.data!.data() as Map<String, dynamic>;
          return _buildUserProfile(context, user);
        },
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, Map<String, dynamic> user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(context, user),
          
          const SizedBox(height: 24),
          
          // Personal Information Card
          _buildInfoCard(
            context,
            'Personal Information',
            Icons.person_outline,
            [
              _buildInfoRow('Name', user['name'] ?? 'Not provided'),
              _buildInfoRow('NIC', user['nic'] ?? 'Not provided'),
              _buildInfoRow('Email', user['email'] ?? 'Not provided'),
              _buildInfoRow('User Type', user['userType'] ?? 'Not provided'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contact Information Card
          _buildInfoCard(
            context,
            'Contact Information',
            Icons.phone_android_outlined,
            [
              _buildInfoRow('Mobile', user['mobileNo'] ?? 'Not provided'),
              _buildInfoRow('Office', user['office'] ?? 'Not provided'),
              _buildInfoRow('Office Phone', user['officePhone'] ?? 'Not provided'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Account Information Card
          _buildInfoCard(
            context,
            'Account Information',
            Icons.account_circle_outlined,
            [
              _buildInfoRow('Account Status', 
                (user['isActive'] == true) ? 'Active' : 'Inactive'),
              _buildInfoRow('Last Updated', _formatTimestamp(user['updatedAt'])),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          _buildActionButtons(context, user),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final name = user['name'] ?? 'Unknown User';
    final email = user['email'] ?? 'No email';
    final userType = user['userType'] ?? 'No role';
    final profileImage = user['profile_image'];

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: profileImage != null && profileImage.isNotEmpty
                    ? CircleAvatar(
                        radius: 56,
                        backgroundImage: NetworkImage(profileImage),
                      )
                    : CircleAvatar(
                        radius: 56,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: theme.primaryColor,
                        ),
                      ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.primaryColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.verified,
                  size: 16,
                  color: (user['isActive'] == true) 
                      ? Colors.green 
                      : Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            email,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userType,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Not available';
    
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
      } else if (timestamp is String) {
        return timestamp;
      }
    } catch (e) {
      return 'Invalid date';
    }
    
    return 'Not available';
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> user) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.message_outlined),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context!);
            },
            child: const Text('Go Back'),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DamageDetailsDialog(issueId: docId),
                ),
              );
            },
            child: const Text('View Issue'),
          ),
        ],
      ),
    );
  }
}

class _SchoolActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String address;
  final String docId;

  const _SchoolActivityItem({
    required this.title,
    required this.subtitle,
    required this.address,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.indigo, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(address,
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SchoolDetailsPage(schoolId: docId),
                ),
              );
            },
            child: const Text('View School'),
          ),
        ],
      ),
    );
  }
}