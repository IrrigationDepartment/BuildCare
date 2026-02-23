import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import destination screens
import 'add_school_details_page.dart';
import 'IssueDetailScreen.dart';

class NotificationScreen extends StatelessWidget {
  final String currentUserNic; // Log wela inna user ge NIC eka (Principal/Engineer/Admin)

  const NotificationScreen({super.key, required this.currentUserNic});

  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);
  static const Color kReviewColor = Color(0xFFFF9800); // Review walata orange paata

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
        // Me user ta adaala notifications witarak fetch karanawa
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('targetNic', isEqualTo: currentUserNic)
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
              
              String? type = data['type']; // 'issue', 'seen_receipt', 'review'
              String? schoolId = data['schoolId'];
              String? issueId = data['issueId'];
              String? addedByNic = data['addedByNic'] ?? ''; // Notification eka dapu kena

              return Container(
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : kPrimaryBlue.withOpacity(0.05),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getIconColor(type, isRead).withOpacity(0.1),
                    child: Icon(
                      _getIconData(type),
                      color: _getIconColor(type, isRead),
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
                    // 1. Mark as read
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(docId)
                        .update({'isRead': true});

                    // 2. TRIGGER SEEN NOTIFICATION (If Engineer/Admin views Principal's Issue)
                    // Principal ge issue ekak nam, eyata "Seen" notification ekak yawanna
                    if (isRead == false && type == 'issue' && addedByNic != null) {
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'title': 'Issue Viewed',
                        'subtitle': 'An official viewed your report: ${data['title']}',
                        'timestamp': FieldValue.serverTimestamp(),
                        'isRead': false,
                        'type': 'seen_receipt',
                        'targetNic': addedByNic, // Principal ge NIC eka
                        'addedByNic': currentUserNic, // Admin/Engineer NIC
                      });
                    }

                    if (!context.mounted) return;

                    // 3. Navigation
                    if ((type == 'issue' || type == 'review' || type == 'seen_receipt') && issueId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IssueDetailScreen(
                            issueData: data,
                            issueId: issueId,
                            userNic: currentUserNic,
                          ),
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

  // Helpers for UI
  IconData _getIconData(String? type) {
    switch (type) {
      case 'seen_receipt': return Icons.visibility_rounded;
      case 'review': return Icons.rate_review_rounded;
      case 'issue': return Icons.report_problem_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String? type, bool isRead) {
    if (isRead) return Colors.grey;
    switch (type) {
      case 'seen_receipt': return Colors.green;
      case 'review': return kReviewColor;
      default: return kPrimaryBlue;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat.yMMMd().add_jm().format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .where('targetNic', isEqualTo: currentUserNic)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}