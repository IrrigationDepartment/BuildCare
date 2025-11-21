import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  final String userNic; // This is the Current Logged in User's NIC

  const NotificationPage({super.key, required this.userNic});

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
            .where('receiverNic', isEqualTo: userNic) // Only show my notifications
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Empty State
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
              final String docId = docs[index].id;

              // Safely get data
              final String title = data['title'] ?? 'Notification';
              final String message = data['message'] ?? 'You have a new update';
              final bool isRead = data['isRead'] ?? false;
              final String type = data['type'] ?? 'general';
              
              // Format Timestamp
              String timeAgo = 'Just now';
              if (data['timestamp'] != null) {
                Timestamp t = data['timestamp'];
                timeAgo = DateFormat('MMM d, h:mm a').format(t.toDate());
              }

              // Distinguish Review vs General Icons
              IconData iconData = Icons.notifications;
              Color iconColor = const Color(0xFF53BDFF);
              
              if (type == 'review') {
                iconData = Icons.rate_review;
                iconColor = Colors.orange;
              }

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
                  // Mark as read when clicked
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(docId)
                      .update({'isRead': true});
                  
                  // Optional: Navigate to the plan details if needed
                  // if (data['relatedPlanId'] != null) { ... }
                },
              );
            },
          );
        },
      ),
    );
  }
}