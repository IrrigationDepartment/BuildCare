import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  final String userNic; // This is the Current Logged in User's NIC

  const NotificationPage({super.key, required this.userNic});

  // --- 1. New function to show the review details dialog ---
  void _showReviewDetailsDialog(BuildContext context, String planId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          // Modern, rounded design
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Review Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
                ),
                const Divider(height: 15, color: Colors.grey),
                
                // Fetch and display the review details
                _buildReviewFetcher(planId), 
                
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 2. Widget to fetch the latest review from Firestore ---
  Widget _buildReviewFetcher(String planId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schoolMasterPlans')
          .doc(planId)
          .collection('reviews')
          // Assuming you want to show the latest review
          .orderBy('reviewedAt', descending: true) 
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("Review details not available or deleted.", style: TextStyle(color: Colors.red));
        }

        final reviewData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        
        final String note = reviewData['note'] ?? 'No note provided.';
        final String reviewerName = reviewData['reviewerName'] ?? 'Anonymous';
        final Timestamp? ts = reviewData['reviewedAt'];
        final String dateStr = ts != null 
            ? DateFormat('MMM dd, yyyy h:mm a').format(ts.toDate()) 
            : 'Unknown Date';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              '"$note"',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text("By: $reviewerName", style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text("On: $dateStr", style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverNic', isEqualTo: userNic) 
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ... (Loading, Error, Empty State logic remains the same) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("No notifications yet",
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String notificationDocId = docs[index].id;

              // Data needed for navigation
              final String type = data['type'] ?? 'general';
              final String? relatedPlanId = data['relatedPlanId']; // IMPORTANT!

              // --- (Formatting and UI variables remain the same) ---
              final String title = data['title'] ?? 'Notification';
              final String message = data['message'] ?? 'You have a new update';
              final bool isRead = data['isRead'] ?? false;
              
              String timeAgo = 'Just now';
              if (data['timestamp'] != null) {
                Timestamp t = data['timestamp'];
                timeAgo = DateFormat('MMM d, h:mm a').format(t.toDate());
              }

              IconData iconData = Icons.notifications;
              Color iconColor = const Color(0xFF53BDFF);
              
              if (type == 'review') {
                iconData = Icons.rate_review;
                iconColor = Colors.orange;
              }
              // --- (End Formatting) ---

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                tileColor: isRead ? Colors.white : Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: CircleAvatar(
                  backgroundColor: isRead ? Colors.grey[200] : iconColor,
                  child: Icon(iconData,
                      color: isRead ? Colors.grey : Colors.white),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(timeAgo,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                onTap: () {
                  // 1. Mark notification as read
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notificationDocId)
                      .update({'isRead': true});
                  
                  // 2. Check type and navigate/show dialog
                  if (type == 'review' && relatedPlanId != null) {
                    _showReviewDetailsDialog(context, relatedPlanId);
                  } 
                  // Add else if for other notification types here
                },
              );
            },
          );
        },
      ),
    );
  }
}