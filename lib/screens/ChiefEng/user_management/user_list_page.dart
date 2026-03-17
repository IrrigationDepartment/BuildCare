import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'user_profile_page.dart';

class UserListPage extends StatefulWidget {
  final String userType;
  final String title;

  const UserListPage({
    super.key,
    required this.userType,
    required this.title,
  });

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getUsersStream() {
    Query query = _firestore
        .collection('users')
        .where('userType', isEqualTo: widget.userType);

    if (_searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          // The '\uf8ff' character is a very high Unicode value, 
          // making it a more robust string boundary than 'z' for Firestore searches.
          .where('name', isLessThan: '$_searchQuery\uf8ff');
    }

    return query.orderBy('name').snapshots();
  }

  Color _getStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.orange;
  }

  String _getStatusText(bool isActive) {
    return isActive ? 'Active' : 'Inactive';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      // We center the entire body and give it a max width for ultra-wide screens
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  // Constrain search bar width so it doesn't look absurd on web
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No ${widget.title.toLowerCase()} found',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data!.docs;

                    // Replaced ListView.builder with GridView.builder for responsiveness
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 450, // The max width of a single card
                        mainAxisExtent: 90, // The fixed height of the card
                        crossAxisSpacing: 16.0, // Space between columns
                        mainAxisSpacing: 16.0, // Space between rows
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final userData =
                            userDoc.data() as Map<String, dynamic>;
                        final userId = userDoc.id;
                        final userName = userData['name'] ?? 'No Name';
                        final userEmail = userData['email'] ?? 'No Email';
                        final isActive = userData['isActive'] ?? false;
                        final createdAt = userData['createdAt'] != null
                            ? (userData['createdAt'] as Timestamp).toDate()
                            : null;
                        final profileImageUrl =
                            userData['profile_image'] ?? '';

                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.zero, // Margins handled by GridSpacing now
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(
                            child: ListTile(
                              leading:
                                  _buildUserAvatar(profileImageUrl, userName),
                              title: Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (createdAt != null)
                                    Text(
                                      'Joined: ${DateFormat('dd MMM yyyy').format(createdAt)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(isActive).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getStatusColor(isActive),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(isActive),
                                  style: TextStyle(
                                    color: _getStatusColor(isActive),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfilePage(
                                      userId: userId,
                                      userData: userData,
                                      userType: widget.userType,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String profileImageUrl, String userName) {
    if (profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.blue.shade50,
        backgroundImage: NetworkImage(profileImageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback handled nicely natively
        },
        child: profileImageUrl.isEmpty
            ? Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
      );
    } else {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.blue.shade50,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
  }
}