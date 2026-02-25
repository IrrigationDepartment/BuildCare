import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for user logic
import 'package:intl/intl.dart';

import 'damage_details_dialog.dart'; 
import 'view_details_screen.dart';   
import 'view_contractor.dart';      
import 'SchoolDetailsDialog.dart';    

class NotificationPage extends StatelessWidget { 
  const NotificationPage({super.key});

  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

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
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(currentUserId),
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsQuery.snapshots(), // Using dynamic query
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
              
              // --- NEW LOGIC: Check if this specific user has read it ---
              List<dynamic> readByUsers = data['readBy'] ?? [];
              bool isRead = readByUsers.contains(currentUserId);
              
              // Routing metadata
              String? type = data['type']; 
              String? schoolId = data['schoolId'];
              String? issueId = data['issueId'];
              String? contractId = data['contractId'];
              String? contractorId = data['contractorId'];

              return Container(
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : kPrimaryBlue.withOpacity(0.05),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[200] : kPrimaryBlue.withOpacity(0.1),
                    child: Icon(
                      _getIconForType(type),
                      color: isRead ? Colors.grey : kPrimaryBlue,
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
                    // --- NEW LOGIC: Add this user's ID to the readBy array ---
                    if (currentUserId.isNotEmpty && !isRead) {
                      await FirebaseFirestore.instance
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
                          builder: (context) => DamageDetailsDialog(issueId: issueId), 
                        ),
                      );
                    } else if (type == 'contract' && contractId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewContractDetailsScreen(contractId: contractId), 
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
                        const SnackBar(content: Text("Error: Link destination not found.")),
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

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'issue': return Icons.report_problem_rounded;
      case 'contract': return Icons.assignment_rounded;
      case 'contractor': return Icons.business_center_rounded;
      case 'school':
      default: return Icons.school_rounded;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat.yMMMd().add_jm().format(timestamp.toDate());
    }
    return '';
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

  // --- NEW LOGIC: Mark All as Read ---
  Future<void> _markAllAsRead(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final DateTime? userCreationTime = currentUser?.metadata.creationTime;
    
    // We fetch all notifications
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