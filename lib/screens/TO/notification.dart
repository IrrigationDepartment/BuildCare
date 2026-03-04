import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:intl/intl.dart';

// --- Destination Imports ---
import 'school_details_page.dart';
import 'issue_report_details_screen.dart';
import 'view_details.dart'; // Contains ViewContractDetailsScreen
import 'view_contractor_screen.dart'; // Contains ViewContractorScreen

// StatefulWidget වලට convert කළා — user NIC load කරන්න
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500
  static const Color kAccentColor = Color(0xFFEC4899); // Pink 500 (For unread dot)

  String? _userNic; // Login වෙලා ඉන්න user ගේ NIC
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserNic();
  }

  // Users collection එකෙන් current user ගේ NIC ගන්නවා
  Future<void> _fetchUserNic() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        setState(() {
          _userNic = query.docs.first.data()['nic'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching user NIC: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    // recipientNic filter — මේ TO කෙනාට යවපු notifications විතරයි පේන්නේ
    final Query notificationsQuery = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientNic', isEqualTo: _userNic)
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: kTextColor, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _markAllAsRead(currentUserId),
            icon: const Icon(Icons.done_all_rounded, size: 18, color: kPrimaryColor),
            label: const Text(
              'Mark read',
              style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsQuery.snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String docId = snapshot.data!.docs[index].id;
                  
                  List<dynamic> readByUsers = data['readBy'] ?? [];
                  bool isRead = readByUsers.contains(currentUserId);

                  String? type = data['type'];
                  String? schoolId = data['schoolId'];
                  String? issueId = data['issueId'];
                  String? contractId = data['contractId'];
                  String? contractorId = data['contractorId'];
                  String userNic = data['addedByNic'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRead ? kCardColor : kPrimaryColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: isRead
                          ? Border.all(color: Colors.grey.shade200)
                          : Border.all(color: kPrimaryColor.withOpacity(0.3), width: 1.5),
                      boxShadow: isRead 
                          ? [] 
                          : [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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

                          // type 'new_issue' සහ 'issue' දෙකම handle කරනවා
                          if ((type == 'issue' || type == 'new_issue') && issueId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IssueReportDetailsScreen(
                                  issueId: issueId,
                                  userNic: userNic,
                                ),
                              ),
                            );
                          } else if (type == 'contract' && contractId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewContractDetailsScreen(
                                  contractId: contractId,
                                ),
                              ),
                            );
                          } else if (type == 'contractor' && contractorId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewContractorScreen(
                                  contractorId: contractorId,
                                ),
                              ),
                            );
                          } else if (type == 'school' && schoolId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SchoolDetailsPage(schoolId: schoolId),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Error: Link destination not found.", style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? Colors.grey.shade100
                                      : kPrimaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconForType(type),
                                  color: isRead ? Colors.grey.shade500 : kPrimaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] ?? 'Notification',
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                        color: kTextColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['subtitle'] ?? data['body'] ?? '',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: isRead ? kSubTextColor : kTextColor.withOpacity(0.8),
                                          height: 1.3),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTimestamp(data['timestamp']),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: kAccentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'issue':
      case 'new_issue':
        return Icons.report_problem_rounded;
      case 'contract':
        return Icons.assignment_rounded;
      case 'contractor':
        return Icons.business_center_rounded;
      case 'school':
      default:
        return Icons.school_rounded;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return DateFormat.yMMMd().add_jm().format(date);
    }
    return '';
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
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('You\'re all caught up!', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 8),
          const Text('No new notifications right now.', 
            style: TextStyle(fontSize: 15, color: kSubTextColor)),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(String currentUserId) async {
    if (currentUserId.isEmpty || _userNic == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // මේ user ට විතරයි related notifications mark කරන්නේ
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientNic', isEqualTo: _userNic)
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
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