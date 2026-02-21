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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('All Reported Issues', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900), // Responsive constraint
          child: StreamBuilder<QuerySnapshot>(
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
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                itemCount: issues.length,
                itemBuilder: (context, index) {
                  final issueDoc = issues[index];
                  final data = issueDoc.data() as Map<String, dynamic>;

                  final issueId = issueDoc.id;
                  final issueTitle = data['issueTitle'] ?? 'No Title';
                  final schoolName = data['schoolName'] ?? 'Unknown School';
                  final status = data['status'] ?? 'Pending';
                  final statusColor = _getStatusColor(status);

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.warning_amber_rounded, color: statusColor),
                          ),
                          title: Text(
                            issueTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(schoolName, style: const TextStyle(color: Colors.black54)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
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
}

// ============================================================================
// ISSUE DETAILS SCREEN
// ============================================================================
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
  State<IssueReportDetailsScreen> createState() => _IssueReportDetailsScreenState();
}

class _IssueReportDetailsScreenState extends State<IssueReportDetailsScreen> {
  // Style Constants
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kSubTextColor = Color(0xFF757575);
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

  final List<String> _statusOptions = ['Pending', 'Processing', 'Completed'];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchIssueDetails();
  }

  // --- Helpers ---
  Future<QuerySnapshot> _fetchReporterDetails(String nic) {
    return FirebaseFirestore.instance.collection('users').where('nic', isEqualTo: nic).limit(1).get();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange.shade700;
      case 'processing': return Colors.blue.shade700;
      case 'completed': return Colors.green.shade700;
      default: return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.pending;
      case 'processing': return Icons.build;
      case 'completed': return Icons.check_circle;
      default: return Icons.help;
    }
  }

  // --- Responsive Detail Card Builder ---
  Widget _buildDetailSection({
    required String title,
    required String value,
    required IconData icon,
    bool isLongText = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueGrey.shade700, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: isLongText ? 15 : 16,
                fontWeight: isLongText ? FontWeight.normal : FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---
  void _showStatusChangeDialog(BuildContext context, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Issue Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Status: $currentStatus',
                style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(currentStatus)),
              ),
              const SizedBox(height: 20),
              ..._statusOptions.map((status) {
                return _statusOption(context, status, _getStatusColor(status), status == currentStatus);
              }),
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
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isCurrent ? color : Colors.grey.shade300, width: isCurrent ? 2 : 1),
      ),
      child: ListTile(
        leading: Icon(_getStatusIcon(status), color: color),
        title: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.green) : null,
        onTap: () {
          if (!isCurrent) {
            _updateStatus(status);
            Navigator.pop(context);
          }
        },
        tileColor: isCurrent ? color.withOpacity(0.05) : Colors.transparent,
      ),
    );
  }

  void _showUserPopup(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: userData['profile_image'] != null ? NetworkImage(userData['profile_image']) : null,
                child: userData['profile_image'] == null ? const Icon(Icons.person, size: 40) : null,
              ),
              const SizedBox(height: 16),
              Text(userData['name'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(userData['userType'] ?? 'Staff', style: const TextStyle(color: Colors.grey)),
              const Divider(height: 30),
              _userInfoRow(Icons.badge, "NIC", userData['nic']),
              _userInfoRow(Icons.phone, "Mobile", userData['mobilePhone']),
              _userInfoRow(Icons.email, "Email", userData['email']),
              _userInfoRow(Icons.business, "Office", userData['office']),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _userInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                children: [
                  TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value ?? "N/A"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic ---
  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _currentUserName = userData['name'] ?? userData['email'] ?? 'Unknown';
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
    }
  }

  Future<void> _fetchIssueDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('issues').doc(widget.issueId).get();
      if (doc.exists) {
        _issueData = doc.data() as Map<String, dynamic>;
        if (_issueData!['dateOfOccurance'] != null) {
          final DateTime selectedDate = (_issueData!['dateOfOccurance'] as Timestamp).toDate();
          _formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
        }
        if (_issueData!['timestamp'] != null) {
          final DateTime reportedDateTime = (_issueData!['timestamp'] as Timestamp).toDate();
          _reportedDate = DateFormat('dd-MM-yyyy @ HH:mm').format(reportedDateTime);
        }
        _images = (_issueData!['imageUrls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
        _statusHistory = _issueData!['statusHistory'] ?? [];
        if (mounted) setState(() => _isPageLoading = false);
      } else {
        if (mounted) setState(() => _isPageLoading = false);
        _showErrorAndPop('Issue details not found.');
      }
    } catch (e) {
      if (mounted) setState(() => _isPageLoading = false);
      _showErrorAndPop('Error fetching details: $e');
    }
  }

  void _showErrorAndPop(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdatingStatus || _currentUserId == null) return;
    setState(() => _isUpdatingStatus = true);

    try {
      final statusUpdate = {
        'status': newStatus,
        'updatedBy': _currentUserName ?? 'Unknown',
        'updatedById': _currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
        'note': '',
      };

      final updatedHistory = List.from(_statusHistory)..add(statusUpdate);

      await FirebaseFirestore.instance.collection('issues').doc(widget.issueId).update({
        'status': newStatus,
        'statusHistory': updatedHistory,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': _currentUserName,
      });

      _issueData?['status'] = newStatus;
      _statusHistory = updatedHistory;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: _getStatusColor(newStatus)),
        );
      }
      await _fetchIssueDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  void _showStatusHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _statusHistory.isEmpty
                    ? const Center(child: Text('No status history available'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _statusHistory.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final history = _statusHistory[index];
                          final status = history['status'] ?? 'Unknown';
                          final color = _getStatusColor(status);
                          final updatedBy = history['updatedBy'] ?? 'Unknown';
                          final note = history['note']?.toString();
                          final updatedAt = history['updatedAt'] is Timestamp
                              ? (history['updatedAt'] as Timestamp).toDate()
                              : DateTime.now();

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: color),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(_getStatusIcon(status), size: 14, color: color),
                                            const SizedBox(width: 6),
                                            Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('MMM dd, HH:mm').format(updatedAt),
                                        style: const TextStyle(fontSize: 12, color: kSubTextColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Updated by: $updatedBy',
                                      style: const TextStyle(fontSize: 14, color: kSubTextColor)),
                                  if (note != null && note.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text('Note: $note', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
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
        title: const Text('Issue Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
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
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900), // Limits width on desktop monitors
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Area: Status Banner
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _issueData!['issueTitle'] ?? 'No Title',
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(_getStatusIcon(currentStatus), color: statusColor, size: 24),
                                            const SizedBox(width: 8),
                                            Text(
                                              currentStatus.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: statusColor,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.isAdminView)
                                    ElevatedButton.icon(
                                      onPressed: () => _showStatusChangeDialog(context, currentStatus),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Update Status'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: statusColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Top Info: Reporter and Date (Uses LayoutBuilder to sit side-by-side on wide screens)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWideScreen = constraints.maxWidth > 600;
                              return Flex(
                                direction: isWideScreen ? Axis.horizontal : Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.userNic.isNotEmpty)
                                    Flexible(
                                      flex: isWideScreen ? 1 : 0,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: FutureBuilder<QuerySnapshot>(
                                          future: _fetchReporterDetails(widget.userNic),
                                          builder: (context, userSnapshot) {
                                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                                              return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                                            }
                                            if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                                              return const SizedBox.shrink();
                                            }

                                            final userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                                            final reporterName = userData['name'] ?? 'Unknown';
                                            final reporterRole = userData['userType'] ?? 'Staff';

                                            return InkWell(
                                              onTap: () => _showUserPopup(context, userData),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Card(
                                                elevation: 0,
                                                color: Colors.blue.shade50,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(color: Colors.blue.shade200),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16.0),
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
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const Text("Reported By", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                                            Text("$reporterName ($reporterRole)",
                                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                          ],
                                                        ),
                                                      ),
                                                      const Icon(Icons.info_outline, color: Colors.blue),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  if (isWideScreen && widget.userNic.isNotEmpty) const SizedBox(width: 16),
                                  if (!isWideScreen && widget.userNic.isNotEmpty) const SizedBox(height: 16),
                                  Flexible(
                                    flex: isWideScreen ? 1 : 0,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time_filled, color: Colors.blueGrey.shade700, size: 38),
                                              const SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Reported On', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                                  Text(_reportedDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Description
                          _buildDetailSection(
                            title: 'Description',
                            value: _issueData!['description'] ?? 'No description provided.',
                            icon: Icons.notes,
                            isLongText: true,
                          ),

                          // Image Gallery (Web Friendly Layout)
                          if (_images.isNotEmpty) ...[
                            const Text("Attached Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _images.asMap().entries.map((entry) {
                                int index = entry.key;
                                String url = entry.value;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FullScreenImageViewer(images: _images, initialIndex: index),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) => progress == null
                                          ? child
                                          : Container(width: 140, height: 140, color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(width: 140, height: 140, color: Colors.grey.shade100, child: const Icon(Icons.broken_image, color: Colors.grey)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Building/Issue Details Grid
                          const Text("Property Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = constraints.maxWidth > 600 ? (constraints.maxWidth / 2) - 8 : constraints.maxWidth;
                              return Wrap(
                                spacing: 16,
                                runSpacing: 0,
                                children: [
                                  SizedBox(width: cardWidth, child: _buildDetailSection(title: 'School Name', value: _issueData!['schoolName'] ?? 'N/A', icon: Icons.school_outlined)),
                                  SizedBox(width: cardWidth, child: _buildDetailSection(title: 'Building Name', value: _issueData!['buildingName'] ?? 'N/A', icon: Icons.domain)),
                                  SizedBox(width: cardWidth, child: _buildDetailSection(title: 'Type of Damage', value: _issueData!['damageType'] ?? 'N/A', icon: Icons.category_outlined)),
                                  SizedBox(width: cardWidth, child: _buildDetailSection(title: 'Date of Occurance', value: _formattedDate, icon: Icons.event)),
                                  SizedBox(width: cardWidth, child: _buildDetailSection(title: 'Building Area', value: _issueData!['buildingArea'] ?? 'N/A', icon: Icons.square_foot)),
                                  SizedBox(width: cardWidth, child: _buildDetailSection(title: 'Floors', value: _issueData!['numFloors']?.toString() ?? 'N/A', icon: Icons.layers_outlined)),
                                  SizedBox(width: cardWidth, child: _buildDetailSection(title: 'Classrooms', value: _issueData!['numClassrooms']?.toString() ?? 'N/A', icon: Icons.meeting_room_outlined)),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}