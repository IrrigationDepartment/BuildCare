import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'damage_details_dialog.dart'; 
import 'view_details_screen.dart';   
import 'view_contractor.dart';      
import 'SchoolDetailsDialog.dart';    

class NotificationPage extends StatefulWidget { 
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // --- Facebook Style Constants ---
  static const Color fbBlue = Color(0xFF1877F2);
  static const Color fbUnreadBg = Color(0xFFE7F3FF);
  static const Color fbGrey = Color(0xFF65676B);
  static const Color fbDarkText = Color(0xFF050505);
  static const Color fbScaffoldBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final DateTime? userCreationTime = currentUser?.metadata.creationTime;
    final String currentUserId = currentUser?.uid ?? '';

    Query notificationsQuery = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    if (userCreationTime != null) {
      notificationsQuery = notificationsQuery.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(userCreationTime));
    }

    return Scaffold(
      backgroundColor: fbScaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(currentUserId),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: notificationsQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  var docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return _buildEmptyState(message: "You have no notifications.");
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String docId = docs[index].id;
                      
                      List<dynamic> readByUsers = data['readBy'] ?? [];
                      bool isRead = readByUsers.contains(currentUserId);
                      
                      String? type = data['type']; 
                      String? schoolId = data['schoolId'];
                      String? issueId = data['issueId'];
                      String? contractId = data['contractId'];
                      String? contractorId = data['contractorId'];

                      return InkWell(
                        onTap: () async {
                          if (currentUserId.isNotEmpty && !isRead) {
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(docId)
                                .update({
                                  'readBy': FieldValue.arrayUnion([currentUserId])
                                });
                          }

                          if (!context.mounted) return;

                          if (type == 'issue' && issueId != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => DamageDetailsDialog(issueId: issueId)));
                          } else if (type == 'contract' && contractId != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ViewContractDetailsScreen(contractId: contractId)));
                          } else if (type == 'contractor' && contractorId != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ViewContractorScreen(contractorId: contractorId)));
                          } else if (type == 'school' && schoolId != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SchoolDetailsPage(schoolId: schoolId)));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.transparent : fbUnreadBg,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatarWithBadge(type),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRichText(data['title'], data['subtitle'], isRead),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getTimeAgo(data['timestamp']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isRead ? fbGrey : fbBlue,
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildCustomAppBar(String currentUserId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: fbDarkText),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fbDarkText),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _markAllAsRead(currentUserId),
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fbBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithBadge(String? type) {
    IconData badgeIcon;

    switch (type) {
      case 'issue':
        badgeIcon = Icons.report_problem;
        break;
      case 'contract':
        badgeIcon = Icons.assignment;
        break;
      case 'contractor':
        badgeIcon = Icons.business_center;
        break;
      case 'school':
      default:
        badgeIcon = Icons.school;
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          child: Icon(badgeIcon, color: fbGrey, size: 24), 
        ),
      ],
    );
  }

  Widget _buildRichText(String? title, String? subtitle, bool isRead) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          color: fbDarkText,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: '${title ?? 'Notification'} ',
            style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.bold),
          ),
          TextSpan(
            text: subtitle ?? '',
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
              color: isRead ? fbGrey : fbDarkText,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is! Timestamp) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    
    return DateFormat.yMMMd().format(date);
  }

  Widget _buildEmptyState({String message = 'No notifications yet'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, color: fbGrey)),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final DateTime? userCreationTime = currentUser?.metadata.creationTime;
    
    Query query = FirebaseFirestore.instance.collection('notifications');
    if (userCreationTime != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(userCreationTime));
    }

    final querySnapshot = await query.get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final readBy = data['readBy'] as List<dynamic>? ?? [];
      
      if (!readBy.contains(currentUserId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUserId])
        });
      }
    }
    
    await batch.commit();
  }
}