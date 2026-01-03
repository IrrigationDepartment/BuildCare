import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_issue_screen.dart';

// ============================================================================
// FULL SCREEN IMAGE VIEWER
// ============================================================================
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// VIEW ISSUES PAGE
// ============================================================================
class ViewIssuesPage extends StatelessWidget {
  const ViewIssuesPage({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'processing':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reported Issues'),
        backgroundColor: const Color(0xFFE8F2FF),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No issues reported yet.'));
          }

          final issues = snapshot.data!.docs;

          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issueDoc = issues[index];
              final data = issueDoc.data() as Map<String, dynamic>;

              final issueId = issueDoc.id;
              final issueTitle = data['issueTitle'] ?? 'No Title';
              final schoolName = data['schoolName'] ?? 'Unknown School';
              final status = data['status'] ?? 'Pending';
              final statusColor = _getStatusColor(status);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: statusColor),
                  title: Text(
                    issueTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(schoolName, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Text('Status: ',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(status,
                              style: TextStyle(
                                  color: statusColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IssueReportDetailsScreen(
                          issueId: issueId,
                          userNic: data['addedByNic'] ?? '',
                          isAdminView: true,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class IssueReportDetailsScreen extends StatefulWidget {
  final String issueId;
  final String userNic;
  final bool isAdminView;
  
  const IssueReportDetailsScreen({
    super.key,
    required this.issueId,
    required this.userNic,
    this.isAdminView = false,
  });

  @override
  State<IssueReportDetailsScreen> createState() =>
      _IssueReportDetailsScreenState();
}

class _IssueReportDetailsScreenState extends State<IssueReportDetailsScreen> {
  // Style Constants
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);
  static const Color kCardColor = Colors.white;
  static const Color kIconColor = Color(0xFF9E9E9E);
  static const Color kPrimaryColor = Color(0xFF4A6FA5);

  // State Variables
  bool _isPageLoading = true;
  bool _isUpdatingStatus = false;
  Map<String, dynamic>? _issueData;
  String _formattedDate = 'N/A';
  String _reportedDate = 'N/A';
  List<String> _images = [];
  List<dynamic> _statusHistory = [];
  String? _currentUserId;
  String? _currentUserName;

  // Status options - Only Pending, Processing, Completed
  final List<String> _statusOptions = [
    'Pending',
    'Processing',
    'Completed'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchIssueDetails();
  }

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================

  // Fetch user details based on NIC
  Future<QuerySnapshot> _fetchReporterDetails(String nic) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('nic', isEqualTo: nic)
        .limit(1)
        .get();
  }

  // Status color logic
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'processing':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'processing':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  // Detail section builder
  Widget _buildDetailSection({
    required String title,
    required String value,
    required IconData icon,
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.blueGrey.shade700, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const Divider(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLongText ? 4.0 : 0.0,
                  vertical: 4.0,
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isLongText ? 16 : 17,
                    fontWeight: isLongText ? FontWeight.normal : FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Status change dialog - Simplified for Pending, Processing, Completed
  void _showStatusChangeDialog(BuildContext context, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Issue Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Status: $currentStatus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(currentStatus),
                ),
              ),
              const SizedBox(height: 20),
              ..._statusOptions.map((status) {
                return _statusOption(
                  context,
                  status,
                  _getStatusColor(status),
                  status == currentStatus,
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )
          ],
        );
      },
    );
  }

  Widget _statusOption(BuildContext context, String status, Color color, bool isCurrent) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(_getStatusIcon(status), color: color),
        title: Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: isCurrent
            ? const Icon(Icons.check, color: Colors.green)
            : null,
        onTap: () {
          if (!isCurrent) {
            _updateStatus(status);
            Navigator.pop(context);
          }
        },
        tileColor: isCurrent ? color.withOpacity(0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }

  // User details popup
  void _showUserPopup(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: userData['profile_image'] != null
                    ? NetworkImage(userData['profile_image'])
                    : null,
                child: userData['profile_image'] == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                userData['name'] ?? 'Unknown',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                userData['userType'] ?? 'Staff',
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 30),
              _userInfoRow(Icons.badge, "NIC", userData['nic']),
              _userInfoRow(Icons.phone, "Mobile", userData['mobilePhone']),
              _userInfoRow(Icons.email, "Email", userData['email']),
              _userInfoRow(Icons.business, "Office", userData['office']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _userInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                      text: "$label: ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value ?? "N/A"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CORE FUNCTIONS
  // ============================================================================

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _currentUserName = userData['name'] ?? userData['email'] ?? 'Unknown';
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<void> _fetchIssueDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .get();

      if (doc.exists) {
        _issueData = doc.data() as Map<String, dynamic>;

        // Format occurrence date
        if (_issueData!['dateOfOccurance'] != null) {
          final DateTime selectedDate =
              (_issueData!['dateOfOccurance'] as Timestamp).toDate();
          _formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
        }

        // Format reported date (timestamp)
        if (_issueData!['timestamp'] != null) {
          final DateTime reportedDateTime =
              (_issueData!['timestamp'] as Timestamp).toDate();
          _reportedDate = DateFormat('dd-MM-yyyy @ HH:mm').format(reportedDateTime);
        }

        // Load images
        _images = (_issueData!['imageUrls'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

        // Load status history
        _statusHistory = _issueData!['statusHistory'] ?? [];

        setState(() {
          _isPageLoading = false;
        });
      } else {
        setState(() {
          _isPageLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Issue details not found.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _isPageLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdatingStatus || _currentUserId == null) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final statusUpdate = {
        'status': newStatus,
        'updatedBy': _currentUserName ?? 'Unknown',
        'updatedById': _currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
        'note': '',
      };

      final updatedHistory = List.from(_statusHistory)..add(statusUpdate);

      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .update({
        'status': newStatus,
        'statusHistory': updatedHistory,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': _currentUserName,
      });

      _issueData?['status'] = newStatus;
      _statusHistory = updatedHistory;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );
      }

      // Refresh data
      await _fetchIssueDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  void _showStatusHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _statusHistory.isEmpty
                    ? const Center(
                        child: Text('No status history available'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _statusHistory.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final history = _statusHistory[index];
                          final status = history['status'] ?? 'Unknown';
                          final updatedBy = history['updatedBy'] ?? 'Unknown';
                          final note = history['note']?.toString();
                          final updatedAt = history['updatedAt'] is Timestamp
                              ? (history['updatedAt'] as Timestamp).toDate()
                              : DateTime.now();
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(status),
                                              size: 14,
                                              color: _getStatusColor(status),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              status,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(status),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('MMM dd, HH:mm').format(updatedAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kSubTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Updated by: $updatedBy',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: kSubTextColor,
                                    ),
                                  ),
                                  if (note != null && note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note: $note',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _issueData?['status'] ?? 'Pending';
    final statusColor = _getStatusColor(currentStatus);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Issue Details',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFE8F2FF),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_statusHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'View Status History',
              onPressed: _showStatusHistory,
            ),
          if (!widget.isAdminView && widget.userNic.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Report',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddIssueScreen(
                      userNic: widget.userNic,
                      issueId: widget.issueId,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : _issueData == null
              ? const Center(child: Text('Issue not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _issueData!['issueTitle'] ?? 'No Title',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(currentStatus),
                                    color: statusColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Status',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: statusColor,
                                          ),
                                        ),
                                        Text(
                                          currentStatus,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.isAdminView)
                                    ElevatedButton.icon(
                                      onPressed: () => _showStatusChangeDialog(context, currentStatus),
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Change Status'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: statusColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Reporter Info Section
                      if (widget.userNic.isNotEmpty)
                        FutureBuilder<QuerySnapshot>(
                          future: _fetchReporterDetails(widget.userNic),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                              return const Text("Reporter info not found.");
                            }

                            final userDoc = userSnapshot.data!.docs.first;
                            final userData = userDoc.data() as Map<String, dynamic>;
                            final reporterName = userData['name'] ?? 'Unknown';
                            final reporterRole = userData['userType'] ?? 'Staff';

                            return InkWell(
                              onTap: () => _showUserPopup(context, userData),
                              child: Card(
                                color: Colors.blue.shade50,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.blue.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue.shade200,
                                        backgroundImage: userData['profile_image'] != null
                                            ? NetworkImage(userData['profile_image'])
                                            : null,
                                        child: userData['profile_image'] == null
                                            ? const Icon(Icons.person, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Reported By:",
                                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text(
                                            "$reporterName ($reporterRole)",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const Text("Tap to view details",
                                              style: TextStyle(fontSize: 10, color: Colors.blue)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 20),

                      // Reported On Section (Like in your image)
                      Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time_outlined, 
                                      color: Colors.blueGrey.shade700, size: 24),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Reported On',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                                child: Text(
                                  _reportedDate,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Description
                      _buildDetailSection(
                        title: 'Description',
                        value: _issueData!['description'] ?? 'No description provided.',
                        icon: Icons.description_outlined,
                        isLongText: true,
                      ),

                      const SizedBox(height: 10),

                      // Images Section
                      if (_images.isNotEmpty) ...[
                        const Text(
                          "Attached Photos",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FullScreenImageViewer(
                                          images: _images,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _images[index],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 120,
                                          color: Colors.grey.shade200,
                                          child: const Center(child: CircularProgressIndicator()),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 120,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Issue Details
                      _buildDetailSection(
                        title: 'Type of Damage',
                        value: _issueData!['damageType'] ?? 'N/A',
                        icon: Icons.category_outlined,
                      ),
                      _buildDetailSection(
                        title: 'Date of Occurance',
                        value: _formattedDate,
                        icon: Icons.calendar_today_outlined,
                      ),
                      _buildDetailSection(
                        title: 'Building Area',
                        value: _issueData!['buildingArea'] ?? 'N/A',
                        icon: Icons.square_foot_outlined,
                      ),
                      _buildDetailSection(
                        title: 'Number of Floors',
                        value: _issueData!['numFloors']?.toString() ?? 'N/A',
                        icon: Icons.layers_outlined,
                      ),
                      _buildDetailSection(
                        title: 'Number of Classrooms',
                        value: _issueData!['numClassrooms']?.toString() ?? 'N/A',
                        icon: Icons.chair_outlined,
                      ),
                      _buildDetailSection(
                        title: 'School Name',
                        value: _issueData!['schoolName'] ?? 'N/A',
                        icon: Icons.school_outlined,
                      ),
                      _buildDetailSection(
                        title: 'Building Name',
                        value: _issueData!['buildingName'] ?? 'N/A',
                        icon: Icons.business_outlined,
                      ),

                      // Status History
                      if (_statusHistory.isNotEmpty)
                        Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.history,
                                        color: Colors.blueGrey.shade700, size: 24),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Recent Status Updates',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 10),
                                ..._statusHistory.reversed.take(3).map((history) {
                                  final status = history['status'] ?? 'Unknown';
                                  final updatedBy = history['updatedBy'] ?? 'Unknown';
                                  final updatedAt = history['updatedAt'] is Timestamp
                                      ? (history['updatedAt'] as Timestamp).toDate()
                                      : DateTime.now();

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                    leading: Icon(
                                      _getStatusIcon(status),
                                      color: _getStatusColor(status),
                                      size: 20,
                                    ),
                                    title: Text(
                                      status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                    subtitle: Text(
                                      'By $updatedBy • ${DateFormat('MMM dd, HH:mm').format(updatedAt)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                if (_statusHistory.length > 3)
                                  TextButton.icon(
                                    onPressed: _showStatusHistory,
                                    icon: const Icon(Icons.history),
                                    label: const Text('View Full History'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: kPrimaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      // Update Status Button (for admin users only) - Styled like in your image
                      if (widget.isAdminView) ...[
                        const SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: () => _showStatusChangeDialog(context, currentStatus),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                              shadowColor: Colors.blue.withOpacity(0.3),
                            ),
                            child: const Text(
                              'Update Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
    );
  }
}