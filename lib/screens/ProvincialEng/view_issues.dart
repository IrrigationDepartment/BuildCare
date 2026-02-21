import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
// MAIN VIEW ISSUES PAGE
// ============================================================================
class ViewIssuesPage extends StatelessWidget {
  const ViewIssuesPage({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
      case 'New':
        return Colors.orange.shade700;
      case 'Processing':
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Processed':
      case 'Resolved':
        return Colors.green.shade700;
      case 'Closed':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background for contrast
      appBar: AppBar(
        title: const Text('All Reported Issues', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // Max width for large screens
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

              // Responsive Grid
              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500, // Cards will be up to 500px wide
                  mainAxisExtent: 130,     // Fixed height to prevent overflow
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: issues.length,
                itemBuilder: (context, index) {
                  final issueDoc = issues[index];
                  final data = issueDoc.data() as Map<String, dynamic>;

                  final issueId = issueDoc.id;
                  final issueTitle = data['issueTitle'] ?? 'No Title';
                  final schoolName = data['schoolName'] ?? 'Unknown School';
                  final status = data['status'] ?? 'N/A';
                  final statusColor = _getStatusColor(status);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IssueDetailPage(issueId: issueId),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.warning_amber_rounded, color: statusColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    issueTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    schoolName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
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
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
}

// ============================================================================
// ISSUE DETAIL PAGE
// ============================================================================
class IssueDetailPage extends StatelessWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

  Future<QuerySnapshot> _fetchReporterDetails(String nic) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('nic', isEqualTo: nic)
        .limit(1)
        .get();
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({'status': newStatus});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
      case 'New':
        return Colors.orange.shade700;
      case 'Processing':
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Processed':
      case 'Resolved':
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
        title: const Text('Issue Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('issues').doc(issueId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading details: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Issue not found or deleted.', style: TextStyle(fontSize: 18)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final issueTitle = data['issueTitle'] ?? 'N/A';
          final issueType = data['issueType'] ?? 'N/A';
          final description = data['description'] ?? 'No description provided.';
          final status = data['status'] ?? 'Pending';
          final schoolName = data['schoolName'] ?? 'N/A';
          final schoolId = data['schoolId'] ?? 'N/A';
          final addedByNic = data['addedByNic'] ?? ''; 

          final List<String> imageUrls =
              (data['imageUrls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final dateReported = timestamp != null
              ? DateFormat('MMM dd, yyyy @ HH:mm').format(timestamp)
              : 'N/A';

          final statusColor = _getStatusColor(status);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900), // Keeps details readable on wide screens
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- Title & Status Card ----------------
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
                                    issueTitle,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.circle, color: statusColor, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: statusColor,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---------------- Reporter Info Section ----------------
                    if (addedByNic.isNotEmpty)
                      FutureBuilder<QuerySnapshot>(
                        future: _fetchReporterDetails(addedByNic),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
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
                                          const Text("Reported By:", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                          Text(
                                            "$reporterName ($reporterRole)",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const Text("Tap to view details", style: TextStyle(fontSize: 11, color: Colors.blue)),
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
                    const SizedBox(height: 20),

                    // ---------------- Description ----------------
                    _buildDetailSection(
                      context,
                      title: 'Description',
                      value: description,
                      icon: Icons.notes,
                      isLongText: true,
                    ),

                    // ---------------- Photos Section (Web/Responsive) ----------------
                    if (imageUrls.isNotEmpty) ...[
                      const Text(
                        "Attached Photos",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: imageUrls.asMap().entries.map((entry) {
                          int index = entry.key;
                          String url = entry.value;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(images: imageUrls, initialIndex: index),
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
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 140,
                                    height: 140,
                                    color: Colors.grey.shade200,
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 140,
                                    height: 140,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---------------- Details Grid (Responsive Side-by-Side) ----------------
                    const Text(
                      "Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // On wide screens, put cards side-by-side. On narrow screens, stack them.
                        final cardWidth = constraints.maxWidth > 600 ? (constraints.maxWidth / 2) - 8 : constraints.maxWidth;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 0,
                          children: [
                            SizedBox(width: cardWidth, child: _buildDetailSection(context, title: 'Issue Type', value: issueType, icon: Icons.category_outlined)),
                            SizedBox(width: cardWidth, child: _buildDetailSection(context, title: 'Reported On', value: dateReported, icon: Icons.access_time_outlined)),
                            SizedBox(width: cardWidth, child: _buildDetailSection(context, title: 'School Name', value: schoolName, icon: Icons.school_outlined)),
                            SizedBox(width: cardWidth, child: _buildDetailSection(context, title: 'School ID', value: schoolId, icon: Icons.vpn_key_outlined)),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // ---------------- Update Status Button ----------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showStatusChangeDialog(context, status),
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text('Update Status', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper: Detail Section Builder ---
  Widget _buildDetailSection(
    BuildContext context, {
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
        side: BorderSide(color: Colors.grey.shade300),
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
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

  // --- Helper: Status Change Dialog ---
  void _showStatusChangeDialog(BuildContext context, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select New Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusOption(context, 'Pending', Colors.orange, currentStatus),
              _statusOption(context, 'Processing', Colors.blue, currentStatus),
              _statusOption(context, 'Processed', Colors.green, currentStatus),
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

  Widget _statusOption(BuildContext context, String status, Color color, String currentStatus) {
    bool isSelected = status == currentStatus;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
      ),
      child: ListTile(
        leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: color, size: 20),
        title: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        onTap: () {
          if (!isSelected) {
            _updateStatus(context, status);
          } else {
            Navigator.pop(context);
          }
        },
        tileColor: isSelected ? color.withOpacity(0.05) : Colors.transparent,
      ),
    );
  }

  // --- Helper: User Details Popup ---
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
                backgroundImage: userData['profile_image'] != null
                    ? NetworkImage(userData['profile_image'])
                    : null,
                child: userData['profile_image'] == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                userData['name'] ?? 'Unknown',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 15),
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
}