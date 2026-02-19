import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Destination Imports ---
import 'school_details_page.dart';
import 'issue_report_details_screen.dart';
import 'view_details.dart'; 
import 'view_contractor_screen.dart'; 

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    // This triggers the logic immediately when the user opens the screen
    _checkIssuesRealTime();
  }

  /// Real-time check logic: This runs whenever the screen is opened
  /// to ensure the "5 month" and "6 month" rules are applied instantly.
  Future<void> _checkIssuesRealTime() async {
    final now = DateTime.now();
    final issues = await FirebaseFirestore.instance.collection('issues').get();
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in issues.docs) {
      final data = doc.data();
      Timestamp? ts = data['lastUpdatedTimestamp'] ?? data['timestamp'];
      if (ts == null) continue;

      DateTime addedDate = ts.toDate();
      int diffInMonths = (now.year - addedDate.year) * 12 + now.month - addedDate.month;

      // 1. EXPIRED (6 Months) -> Delete and Notify
      if (diffInMonths >= 6) {
        // Create Notification
        DocumentReference notifyRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifyRef, {
          'title': "Issue Expired",
          'subtitle': "Issue '${data['issueTitle']}' was automatically deleted (6 months old).",
          'type': 'issue_deleted',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'addedByNic': data['addedByNic'],
        });
        // Delete Issue
        batch.delete(doc.reference);
      } 
      // 2. EXPIRE SOON (5 Months) -> Notify only once
      else if (diffInMonths >= 5 && (data['expiryWarningSent'] != true)) {
        DocumentReference notifyRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifyRef, {
          'title': "Expiring Soon",
          'subtitle': "Issue '${data['issueTitle']}' will be deleted in 1 month.",
          'type': 'issue',
          'issueId': doc.id,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'addedByNic': data['addedByNic'],
        });
        // Update issue so we don't spam notifications
        batch.update(doc.reference, {'expiryWarningSent': true});
      }
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(),
            child: const Text('Mark all as read', style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String docId = snapshot.data!.docs[index].id;
              bool isRead = data['isRead'] ?? false;
              String? type = data['type'];

              return Container(
                color: isRead ? Colors.white : kPrimaryBlue.withOpacity(0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[200] : kPrimaryBlue.withOpacity(0.1),
                    child: Icon(_getIconForType(type), color: isRead ? Colors.grey : kPrimaryBlue),
                  ),
                  title: Text(data['title'] ?? 'Notification',
                      style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(data['subtitle'] ?? ''),
                  onTap: () => _handleNavigation(context, data, docId),
                  trailing: !isRead ? const Icon(Icons.circle, size: 12, color: kPrimaryBlue) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleNavigation(BuildContext context, Map<String, dynamic> data, String docId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});
    
    if (!mounted) return;
    String? type = data['type'];

    if (type == 'issue_deleted') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This issue has been deleted.")));
    } else if (type == 'issue' && data['issueId'] != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => 
        IssueReportDetailsScreen(issueId: data['issueId'], userNic: data['addedByNic'] ?? '')));
    }
    // ... Add other navigation types (contract, school) here as per your original code
  }

  IconData _getIconForType(String? type) {
    if (type == 'issue_deleted') return Icons.delete_forever;
    if (type == 'issue') return Icons.warning_amber_rounded;
    return Icons.notifications;
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No notifications yet", style: TextStyle(color: Colors.grey)));
  }

  Future<void> _markAllAsRead() async {
    final query = await FirebaseFirestore.instance.collection('notifications').where('isRead', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) { batch.update(doc.reference, {'isRead': true}); }
    await batch.commit();
  }
}