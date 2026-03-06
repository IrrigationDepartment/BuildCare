import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- NEW IMPORTS FOR PDF GENERATION ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  final String currentUserNic; // Current logged-in user NIC

  const ViewIssuesPage({super.key, required this.currentUserNic});

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
                            builder: (context) => IssueDetailPage(
                              issueId: issueId,
                              currentUserNic: currentUserNic, // Pass the NIC
                            ),
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
class IssueDetailPage extends StatefulWidget {
  final String issueId;
  final String currentUserNic; // Current logged-in user NIC

  const IssueDetailPage({
    super.key, 
    required this.issueId, 
    required this.currentUserNic
  });

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  final TextEditingController _reviewController = TextEditingController();

  Future<QuerySnapshot> _fetchUserDetails(String nic) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('nic', isEqualTo: nic)
        .limit(1)
        .get();
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Fixed Submit Review Function ---
  Future<void> _submitReview(String? principalNic, String? issueTitle) async {
    String reviewText = _reviewController.text.trim();
    if (reviewText.isEmpty) return;

    try {
      // 1. Add review to a subcollection in the issue document
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .collection('reviews')
          .add({
        'reviewText': reviewText,
        'reviewerNic': widget.currentUserNic,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Trigger notification to the Principal (Only if principalNic is valid)
      if (principalNic != null && principalNic.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New Review Added',
          'subtitle': 'An official reviewed your issue: ${issueTitle ?? "No Title"}',
          'type': 'review',
          'issueId': widget.issueId,
          'targetNic': principalNic, 
          'addedByNic': widget.currentUserNic, 
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      if (mounted) {
        _reviewController.clear();
        Navigator.pop(context); // Close Review Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add review: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- NEW PDF GENERATION LOGIC ---
  Future<void> _generateAndDownloadPdf(Map<String, dynamic> data, String dateReported) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(seconds: 1)),
    );

    final pdf = pw.Document();

    // Fetch reviews to include in the PDF
    final reviewsSnap = await FirebaseFirestore.instance
        .collection('issues')
        .doc(widget.issueId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .get();

    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BuildCare Issue Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                ]
              )
            ),
            pw.SizedBox(height: 20),

            // ISSUE DETAILS
            pw.Text(data['issueTitle'] ?? 'N/A', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildPdfRow('Status:', data['status'] ?? 'Pending'),
            _buildPdfRow('Date Reported:', dateReported),
            _buildPdfRow('Issue Type:', data['issueType'] ?? 'N/A'),
            _buildPdfRow('School Name:', data['schoolName'] ?? 'N/A'),
            _buildPdfRow('School ID:', data['schoolId'] ?? 'N/A'),
            _buildPdfRow('Reporter NIC:', data['addedByNic'] ?? 'N/A'),
            
            pw.SizedBox(height: 20),
            
            // DESCRIPTION
            pw.Text('Description:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text(data['description'] ?? 'No description provided.', style: const pw.TextStyle(fontSize: 12)),
            
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // REVIEWS
            pw.Text('Official Reviews & Remarks', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (reviewsSnap.docs.isEmpty)
              pw.Text('No reviews added yet.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey))
            else
              ...reviewsSnap.docs.map((doc) {
                final rData = doc.data();
                final Timestamp? tStamp = rData['timestamp'] as Timestamp?;
                final rTime = tStamp != null ? DateFormat('MMM dd, yyyy @ hh:mm a').format(tStamp.toDate()) : 'Unknown Date';
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Reviewer NIC: ${rData['reviewerNic'] ?? 'Unknown'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(rTime, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 5),
                      pw.Text(rData['reviewText'] ?? '', style: const pw.TextStyle(fontSize: 12)),
                    ]
                  )
                );
              }),
          ];
        },
      ),
    );

    // Prompt user to download/save/print the generated PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Issue_Report_${widget.issueId}.pdf',
    );
  }

  // Helper widget for PDF layout
  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 12))),
        ],
      ),
    );
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
        stream: FirebaseFirestore.instance.collection('issues').doc(widget.issueId).snapshots(),
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
          final String? issueTitle = data['issueTitle']; 
          final String issueType = data['issueType'] ?? 'N/A';
          final String description = data['description'] ?? 'No description provided.';
          final String status = data['status'] ?? 'Pending';
          final String schoolName = data['schoolName'] ?? 'N/A';
          final String schoolId = data['schoolId'] ?? 'N/A';
          final String? addedByNic = data['addedByNic']; 

          final List<String> imageUrls =
              (data['imageUrls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final dateReported = timestamp != null
              ? DateFormat('MMM dd, yyyy @ HH:mm').format(timestamp)
              : 'N/A';

          final statusColor = _getStatusColor(status);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900), 
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
                                    issueTitle ?? 'N/A',
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
                    if (addedByNic != null && addedByNic.isNotEmpty)
                      FutureBuilder<QuerySnapshot>(
                        future: _fetchUserDetails(addedByNic),
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
                            onTap: () => _showUserPopup(userData),
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
                      title: 'Description',
                      value: description,
                      icon: Icons.notes,
                      isLongText: true,
                    ),

                    // ---------------- Photos Section ----------------
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

                    // ---------------- Details Grid ----------------
                    const Text(
                      "Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth > 600 ? (constraints.maxWidth / 2) - 8 : constraints.maxWidth;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 0,
                          children: [
                            SizedBox(width: cardWidth, child: _buildDetailSection(title: 'Issue Type', value: issueType, icon: Icons.category_outlined)),
                            SizedBox(width: cardWidth, child: _buildDetailSection(title: 'Reported On', value: dateReported, icon: Icons.access_time_outlined)),
                            SizedBox(width: cardWidth, child: _buildDetailSection(title: 'School Name', value: schoolName, icon: Icons.school_outlined)),
                            SizedBox(width: cardWidth, child: _buildDetailSection(title: 'School ID', value: schoolId, icon: Icons.vpn_key_outlined)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // ---------------- REVIEWS SECTION ----------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Engineer Reviews",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddReviewDialog(addedByNic, issueTitle),
                          icon: const Icon(Icons.add_comment, size: 18),
                          label: const Text("Add Review"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                          ),
                         )
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildReviewsList(), 
                    const SizedBox(height: 30),

                    // ---------------- BUTTONS SECTION ----------------
                    
                    // Update Status Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showStatusChangeDialog(status),
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
                    
                    const SizedBox(height: 12),

                    // Download PDF Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _generateAndDownloadPdf(data, dateReported),
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        label: const Text('Download PDF Report', style: TextStyle(fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(color: Colors.blueGrey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper: Build Reviews List ---
  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            "No reviews added yet.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var reviewData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String reviewerNic = reviewData['reviewerNic'] ?? 'Unknown';
            String reviewText = reviewData['reviewText'] ?? '';
            Timestamp? timestamp = reviewData['timestamp'] as Timestamp?;
            String timeString = timestamp != null 
                ? DateFormat('MMM dd, yyyy @ hh:mm a').format(timestamp.toDate()) 
                : 'Just now';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.teal.shade200),
              ),
              color: Colors.teal.shade50,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_pin, color: Colors.teal.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FutureBuilder<QuerySnapshot>(
                            future: _fetchUserDetails(reviewerNic),
                            builder: (context, userSnap) {
                              if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
                                var usr = userSnap.data!.docs.first.data() as Map<String, dynamic>;
                                return Text(
                                  "${usr['name'] ?? 'Vihanga Manodhya'} (${usr['userType'] ?? 'Provincial Engineer'})",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                                );
                              }
                              return Text(
                                "Vihanga Manodhya (Provincial Engineer)", 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)
                              );
                            }
                          ),
                        ),
                        Text(
                          timeString,
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      reviewText,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Helper: Detail Section Builder ---
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

  // --- Helper: Add Review Dialog ---
  void _showAddReviewDialog(String? principalNic, String? issueTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Review'),
          content: TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type your review or remarks here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _reviewController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => _submitReview(principalNic, issueTitle),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- Helper: Status Change Dialog ---
  void _showStatusChangeDialog(String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select New Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusOption('Pending', Colors.orange, currentStatus),
              _statusOption('Processing', Colors.blue, currentStatus),
              _statusOption('Processed', Colors.green, currentStatus),
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

  Widget _statusOption(String status, Color color, String currentStatus) {
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
            _updateStatus(status);
          } else {
            Navigator.pop(context);
          }
        },
        tileColor: isSelected ? color.withOpacity(0.05) : Colors.transparent,
      ),
    );
  }

  // --- Helper: User Details Popup ---
  void _showUserPopup(Map<String, dynamic> userData) {
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