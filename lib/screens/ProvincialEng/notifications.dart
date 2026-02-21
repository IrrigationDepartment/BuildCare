import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              onPressed: () => _markAllAsRead(),
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
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .snapshots(),
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
                    bool isRead = data['isRead'] ?? false;
                    
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
                          // Mark as read instantly in UI by updating Firestore
                          if (!isRead) {
                            FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(docId)
                                .update({'isRead': true});
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

  Future<void> _markAllAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}