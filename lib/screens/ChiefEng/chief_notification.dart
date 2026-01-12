import 'package:buildcare/screens/ChiefEng/contract_details_page.dart';
import 'package:buildcare/screens/ChiefEng/dashboard.dart';
import 'package:buildcare/screens/ChiefEng/view_contractor_detail.dart';
import 'package:buildcare/screens/ChiefEng/view_dage_detail_page.dart';
import 'package:buildcare/screens/ChiefEng/view_school_masterplan_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNotification({
    required String title,
    required String subtitle,
    required String type,
    String? relatedDocumentId,
    String? addedByNic,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        if (relatedDocumentId != null) 'relatedDocumentId': relatedDocumentId,
        if (addedByNic != null) 'addedByNic': addedByNic,
      });
      debugPrint('Notification created: $type - $title');
    } catch (e) {
      debugPrint(' Error creating notification: $e');
      rethrow;
    }
  }

  static Stream<int> getUnreadCountStream() {
    return _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}

class DashboardNotificationButton extends StatefulWidget {
  const DashboardNotificationButton({super.key});

  @override
  State<DashboardNotificationButton> createState() =>
      _DashboardNotificationButtonState();
}

class _DashboardNotificationButtonState
    extends State<DashboardNotificationButton> {
  late Stream<int> _unreadCountStream;

  @override
  void initState() {
    super.initState();
    _unreadCountStream = NotificationService.getUnreadCountStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _unreadCountStream,
      initialData: 0,
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;

        if (snapshot.hasError) {
          count = 0;
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Color(0xFF64B5F6),
                size: 32,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SimpleNotificationButton extends StatelessWidget {
  final int unreadCount;

  const SimpleNotificationButton({
    super.key,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications,
            color: Color(0xFF64B5F6),
            size: 32,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Mark all as read',
                onPressed: () async {
                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in snapshot.data!.docs) {
                    batch.update(doc.reference, {'isRead': true});
                  }
                  await batch.commit();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF64B5F6),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notification_add_rounded,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: TextStyle(color: Colors.red[400], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final doc = notifications[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isUnread = !(data['isRead'] ?? false);
                  final timestamp = data['timestamp'] as Timestamp?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isUnread ? 2 : 1,
                    color: isUnread ? const Color(0xFFE3F2FD) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isUnread
                            ? const Color(0xFF64B5F6).withOpacity(0.3)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        try {
                         
                          if (isUnread) {
                            await doc.reference.update({'isRead': true});
                          }

                        
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => NotificationDetailDialog(
                                data: data,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error marking as read: $e');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isUnread
                                    ? const Color(0xFF64B5F6)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getNotificationIcon(data['type']),
                                color:
                                    isUnread ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] ?? 'Notification',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['subtitle'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTimestamp(timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF64B5F6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'contractor':
        return Icons.engineering;
      case 'contract':
        return Icons.description;
      case 'school':
        return Icons.school;
      case 'repair':
        return Icons.build;
      case 'damage':
      case 'issue':
        return Icons.warning;
      case 'masterplan':
        return Icons.architecture;
      case 'engineer':
        return Icons.person;
      case 'success':
        return Icons.check_circle;
      case 'info':
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';

    try {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes}m ago';
      if (difference.inDays < 1) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }
}


class NotificationDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const NotificationDetailDialog({
    super.key,
    required this.data,
  });

 
  void _navigateToPage(BuildContext context, String? type) {
    Navigator.pop(context); 

  
    final relatedDocumentId = data['relatedDocumentId'] as String? ??
        data['issueId'] as String? ??
        data['schoolId'] as String? ??
        data['contractorId'] as String? ??
        data['contractId'] as String?;

    
    if (relatedDocumentId == null || relatedDocumentId.isEmpty) {
      debugPrint(
          ' Navigation failed - Available fields: ${data.keys.toList()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Cannot navigate: Missing document ID for ${type ?? "this notification"}'),
              const SizedBox(height: 4),
              const Text(
                'Make sure to use "relatedDocumentId" when creating notifications',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    debugPrint(' Navigating to $type with ID: $relatedDocumentId');

    switch (type?.toLowerCase()) {
      case 'school':
       
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SchoolDetailsPage(
              schoolId: relatedDocumentId,
            ),
          ),
        );
        _showNavigationMessage(context, 'School Details', relatedDocumentId);
        break;

      case 'damage':
      case 'issue':
      
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DamageDetailsPage(
              issueId: relatedDocumentId,
            ),
          ),
        );
        _showNavigationMessage(
            context, 'Issue/Damage Details', relatedDocumentId);
        break;

      case 'contractor':
      
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractorDetailsViewScreen(
              contractorId: relatedDocumentId,
            ),
          ),
        );
        _showNavigationMessage(
            context, 'Contractor Details', relatedDocumentId);
        break;

      case 'contract':
       
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractDetailsViewScreen(
              contractId: relatedDocumentId,
            ),
          ),
        );
        _showNavigationMessage(context, 'Contract Details', relatedDocumentId);
        break;

      case 'masterplan':
       
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SchoolMasterPlanScreen(),
          ),
        );
        _showNavigationMessage(context, 'Master Plan', relatedDocumentId);
        break;

      case 'repair':
       
        _showNavigationMessage(
            context, 'Repair Report Details', relatedDocumentId);
        break;

      case 'engineer':
       
        _showNavigationMessage(context, 'Engineer Details', relatedDocumentId);
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No page configured for type: ${type ?? "unknown"}'),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }

  void _showNavigationMessage(
      BuildContext context, String pageName, String documentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ready to navigate to: $pageName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Document ID: $documentId'),
            const SizedBox(height: 4),
            const Text(
              'Uncomment the navigation code in NotificationDetailDialog',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(data['type']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getNotificationIcon(data['type']),
                    color: _getTypeColor(data['type']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['title'] ?? 'Notification',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

           
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['subtitle'] ?? 'No details available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Additional information section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['relatedDocumentId'] != null) ...[
                    _buildInfoRow(
                      Icons.link,
                      'Document ID',
                      data['relatedDocumentId'],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (data['addedByNic'] != null) ...[
                    _buildInfoRow(
                      Icons.person,
                      'Added by',
                      data['addedByNic'],
                    ),
                    const SizedBox(height: 10),
                  ],
                  _buildInfoRow(
                    Icons.access_time,
                    'Time',
                    _formatTimestamp(data['timestamp'] as Timestamp?),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            
            GestureDetector(
              onTap: () => _navigateToPage(context, data['type']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getTypeColor(data['type']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getNotificationIcon(data['type']),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (data['type'] ?? 'Info').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'contractor':
        return Icons.engineering;
      case 'contract':
        return Icons.description;
      case 'school':
        return Icons.school;
      case 'repair':
        return Icons.build;
      case 'damage':
      case 'issue':
        return Icons.warning;
      case 'masterplan':
        return Icons.architecture;
      case 'engineer':
        return Icons.person;
      case 'success':
        return Icons.check_circle;
      case 'info':
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'contractor':
        return Colors.deepPurple;
      case 'contract':
        return Colors.indigo;
      case 'school':
        return Colors.blue;
      case 'repair':
        return Colors.orange;
      case 'damage':
      case 'issue':
        return Colors.red;
      case 'masterplan':
        return Colors.teal;
      case 'engineer':
        return Colors.cyan;
      case 'success':
        return Colors.green;
      case 'info':
      default:
        return const Color(0xFF64B5F6);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';

    try {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
      if (difference.inDays < 1) return '${difference.inHours} hours ago';
      if (difference.inDays < 7) return '${difference.inDays} days ago';

      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Recently';
    }
  }
}
