
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  final String userNic;

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
            .where('receiverNic', isEqualTo: userNic) // Filter by User NIC
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
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
              final String title = data['title'] ?? 'Notification';
              final String message = data['message'] ?? '';
              final bool isRead = data['isRead'] ?? false;
              
              // Format Timestamp
              String timeAgo = '';
              if (data['timestamp'] != null) {
                Timestamp t = data['timestamp'];
                timeAgo = DateFormat('MMM d, h:mm a').format(t.toDate());
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                tileColor: isRead ? Colors.white : Colors.blue[50], // Highlight unread
                leading: CircleAvatar(
                  backgroundColor: isRead ? Colors.grey[200] : const Color(0xFF53BDFF),
                  child: Icon(Icons.notifications, 
                    color: isRead ? Colors.grey : Colors.white),
                ),
                title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 4),
                    Text(timeAgo, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
                onTap: () {
                  // Mark as read when clicked
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(docs[index].id)
                      .update({'isRead': true});
                },
              );
            },
          );
        },
      ),
    );
  }
}