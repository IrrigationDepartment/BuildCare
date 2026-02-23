import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import destination screens
import 'add_school_details_page.dart';
import 'IssueDetailScreen.dart';
 
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(),
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to notifications ordered by most recent
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String docId = snapshot.data!.docs[index].id;
              bool isRead = data['isRead'] ?? false;
              
              // Extract metadata for routing and seen-receipts
              String? type = data['type']; // 'school', 'issue', or 'seen_receipt'
              String? schoolId = data['schoolId'];
              String? issueId = data['issueId'];
              String? userNic = data['addedByNic'] ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : kPrimaryBlue.withOpacity(0.05),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    // Different colors based on read status and notification type
                    backgroundColor: isRead 
                        ? Colors.grey[200] 
                        : (type == 'seen_receipt' ? Colors.green.withOpacity(0.1) : kPrimaryBlue.withOpacity(0.1)),
                    child: Icon(
                      type == 'seen_receipt' 
                          ? Icons.done_all_rounded // Double tick for seen status
                          : (type == 'issue' ? Icons.report_problem_rounded : Icons.school_rounded),
                      color: isRead 
                          ? Colors.grey 
                          : (type == 'seen_receipt' ? Colors.green : kPrimaryBlue),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['subtitle'] ?? '',
                        style: const TextStyle(fontSize: 13, color: kSubTextColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(data['timestamp']),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  onTap: () async {
                    // 1. Mark notification as read in Admin's view
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(docId)
                        .update({'isRead': true});

                    // 2. TRIGGER SEEN NOTIFICATION FOR PRINCIPAL
                    // Only send if it hasn't been read before
                    if (isRead == false && type != 'seen_receipt') {
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'title': 'Report Seen by Admin',
                        'subtitle': 'Admin viewed: ${data['title']}',
                        'timestamp': FieldValue.serverTimestamp(),
                        'isRead': false,
                        'type': 'seen_receipt',
                        'targetNic': userNic, // The Principal who will see this
                        'addedByNic': 'ADMIN',
                      });
                    }

                    if (!context.mounted) return;

                    // 3. Navigation Logic
                    if (type == 'issue' && issueId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IssueDetailScreen(
                            issueData: data,
                            issueId: issueId,
                            userNic: userNic!,
                          ),
                        ),
                      );
                    } else if (type == 'school' && schoolId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddSchoolDetailsPage(userNic: userNic!),
                        ),
                      );
                    }
                  },
                  trailing: !isRead 
                      ? const Icon(Icons.circle, size: 12, color: kPrimaryBlue) 
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper: Convert Firestore Timestamp to readable string
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat.yMMMd().add_jm().format(date);
  }

  // UI for empty list state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Batch update all unread notifications to read status
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