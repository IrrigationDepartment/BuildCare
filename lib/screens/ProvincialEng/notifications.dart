import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for user logic
import 'package:intl/intl.dart';

// Updated imports to match your provided file names
import 'issue_report_details_screen.dart'; 
import 'school_details_page.dart';   
import 'view_contractor_screen.dart';      

class NotificationPage extends StatelessWidget { 
  const NotificationPage({super.key});

  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF1877F2); // Facebook-style Messenger Blue
  static const Color kUnreadBackground = Color(0xFFE7F3FF); // Light blue tint for unread
  static const Color kBackgroundColor = Color(0xFFF0F2F5); // Facebook-style page background
  static const Color kTextColor = Color(0xFF050505);
  static const Color kSubTextColor = Color(0xFF65676B);

  @override
  Widget build(BuildContext context) {
    // 1. GET THE CURRENT USER INFO
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final DateTime? userCreationTime = currentUser?.metadata.creationTime;
    final String currentUserId = currentUser?.uid ?? '';

    // 2. BUILD THE QUERY DYNAMICALLY
    Query notificationsQuery = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    // 3. APPLY THE FILTER: Only show notifications created AFTER the user registered
    if (userCreationTime != null) {
      notificationsQuery = notificationsQuery.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(userCreationTime));
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: kTextColor, 
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Flat design
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () => _markAllAsRead(currentUserId),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600),
              ),
            ),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          // Makes the UI look like a centered feed on web/desktop monitors
          constraints: const BoxConstraints(maxWidth: 750), 
          child: StreamBuilder<QuerySnapshot>(
            stream: notificationsQuery.snapshots(), // Using dynamic query
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              return Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    String docId = snapshot.data!.docs[index].id;
                    
                    // --- NEW LOGIC: Check if this specific user has read it ---
                    List<dynamic> readByUsers = data['readBy'] ?? [];
                    bool isRead = readByUsers.contains(currentUserId);
                    
                    // Routing metadata
                    String? type = data['type']; 
                    String? schoolId = data['schoolId'];
                    String? issueId = data['issueId'];
                    String? contractorId = data['contractorId'];
                    String userNic = data['userNic'] ?? ''; 

                    return Material(
                      color: isRead ? Colors.white : kUnreadBackground,
                      child: InkWell(
                        onTap: () async {
                          // --- NEW LOGIC: Add this user's ID to the readBy array ---
                          if (currentUserId.isNotEmpty && !isRead) {
                            FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(docId)
                                .update({
                                  'readBy': FieldValue.arrayUnion([currentUserId])
                                });
                          }

                          if (!context.mounted) return;

                          // Navigation logic based on the uploaded files
                          if (type == 'issue' && issueId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IssueReportDetailsScreen(
                                  issueId: issueId, 
                                  userNic: userNic,
                                  isAdminView: true, 
                                ),
                              ),
                            );
                          } else if (type == 'contractor' && contractorId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewContractorScreen(contractorId: contractorId),
                              ),
                            );
                          } else if (type == 'school' && schoolId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SchoolDetailsPage(schoolId: schoolId),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Link destination not found.")),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon Avatar
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: isRead ? Colors.grey.shade200 : kPrimaryBlue.withOpacity(0.15),
                                    child: Icon(
                                      _getIconForType(type),
                                      color: isRead ? kSubTextColor : kPrimaryBlue,
                                      size: 26,
                                    ),
                                  ),
                                  if (!isRead)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: kPrimaryBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              
                              // Text Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: kTextColor,
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                          height: 1.3,
                                        ),
                                        children: [
                                          TextSpan(text: data['title'] ?? 'Notification'),
                                          if (data['subtitle'] != null && data['subtitle'].toString().isNotEmpty)
                                            TextSpan(
                                              text: ' • ${data['subtitle']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                color: isRead ? kSubTextColor : kTextColor.withOpacity(0.8),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _timeAgo(data['timestamp']),
                                      style: TextStyle(
                                        fontSize: 13, 
                                        color: isRead ? kSubTextColor : kPrimaryBlue,
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Trailing Indicator
                              if (!isRead) ...[
                                const SizedBox(width: 12),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: kPrimaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'issue': return Icons.report_problem_rounded;
      case 'contract': return Icons.assignment_rounded;
      case 'contractor': return Icons.business_center_rounded;
      case 'school':
      default: return Icons.school_rounded;
    }
  }

  // Converts Timestamp to a "Facebook style" time ago format
  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime notificationTime;
    if (timestamp is Timestamp) {
      notificationTime = timestamp.toDate();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(notificationTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Icon(Icons.notifications_active_outlined, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor),
          ),
          const SizedBox(height: 8),
          const Text(
            "When you get notifications, they'll show up here.", 
            style: TextStyle(fontSize: 15, color: kSubTextColor),
          ),
        ],
      ),
    );
  }

  // --- NEW LOGIC: Mark All as Read ---
  Future<void> _markAllAsRead(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final DateTime? userCreationTime = currentUser?.metadata.creationTime;
    
    // Fetch all notifications
    Query query = FirebaseFirestore.instance.collection('notifications');
        
    if (userCreationTime != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(userCreationTime));
    }

    final querySnapshot = await query.get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final readBy = data['readBy'] as List<dynamic>? ?? [];
      
      // If this user hasn't read it yet, add them to the array
      if (!readBy.contains(currentUserId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUserId])
        });
      }
    }
    
    await batch.commit();
  }
}