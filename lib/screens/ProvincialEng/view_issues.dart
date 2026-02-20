<<<<<<< HEAD
=======
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// PDF Packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
 
// ============================================================================
// FULL SCREEN IMAGE VIEWER
>>>>>>> main
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ============================================================================
// FULL SCREEN IMAGE VIEWER (Unchanged)
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
              final status = data['status'] ?? 'N/A';
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
                        builder: (context) => IssueDetailPage(issueId: issueId),
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

// ============================================================================
<<<<<<< HEAD
=======
// ISSUE DETAIL PAGE (With PDF Logic)
>>>>>>> main
// ISSUE DETAIL PAGE (Modified)
// ============================================================================
class IssueDetailPage extends StatelessWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

<<<<<<< HEAD
=======
  // --- PDF Generation & Download Logic ---
  Future<void> _downloadPdfReport(Map<String, dynamic> data, Map<String, dynamic>? userData) async {
    final pdf = pw.Document();

    // Fetch images as bytes for PDF inclusion
    final List<dynamic> imageUrls = data['imageUrls'] ?? [];
    List<pw.MemoryImage> pdfImages = [];

    for (var url in imageUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          pdfImages.add(pw.MemoryImage(response.bodyBytes));
        }
      } catch (e) {
        debugPrint("Image Error: $e");
      }
    }

    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final dateStr = timestamp != null ? DateFormat('dd-MM-yyyy HH:mm').format(timestamp) : 'N/A';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("OFFICIAL ISSUE REPORT", 
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text("Report ID: $issueId", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(dateStr, style: const pw.TextStyle(color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 20),

            // Issue Info Table
            pw.Text("ISSUE SUMMARY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellHeight: 30,
              cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
              data: <List<String>>[
                <String>['Field', 'Details'],
                ['Issue Title', data['issueTitle'] ?? 'N/A'],
                ['Category', data['issueType'] ?? 'N/A'],
                ['Current Status', data['status'] ?? 'Pending'],
                ['School Name', data['schoolName'] ?? 'N/A'],
                ['School ID', data['schoolId'] ?? 'N/A'],
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Text("DESCRIPTION", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 5),
            pw.Paragraph(
              text: data['description'] ?? 'No description provided.',
              style: const pw.TextStyle(lineSpacing: 1.5),
            ),

            // Reporter Details
            if (userData != null) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("REPORTER DETAILS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text("Name: ${userData['name'] ?? 'Unknown'}"),
                    pw.Text("NIC: ${userData['nic'] ?? 'N/A'}"),
                    pw.Text("Contact: ${userData['mobilePhone'] ?? 'N/A'}"),
                    pw.Text("Office: ${userData['office'] ?? 'N/A'}"),
                  ],
                ),
              ),
            ],

            // Photos Grid
            if (pdfImages.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text("ATTACHED EVIDENCE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 15,
                runSpacing: 15,
                children: pdfImages.map((img) => pw.Container(
                  width: 160,
                  height: 160,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Image(img, fit: pw.BoxFit.cover),
                )).toList(),
              ),
            ],
          ];
        },
      ),
    );

    // This opens the native print/save dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Report_${data['issueTitle'] ?? "Issue"}.pdf',
    );
  }

  // --- Fetch Helpers ---
>>>>>>> main
  // Fetch specific issue
  Future<DocumentSnapshot> _fetchIssueDetails() {
    return FirebaseFirestore.instance.collection('issues').doc(issueId).get();
  }

  // Fetch user details based on NIC
  Future<QuerySnapshot> _fetchReporterDetails(String nic) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('nic', isEqualTo: nic)
        .limit(1)
        .get();
  }

<<<<<<< HEAD
=======
  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('issues').doc(issueId).update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('issues').doc(issueId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData || !snapshot.data!.exists) return const Scaffold(body: Center(child: Text("Issue not found.")));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final addedByNic = data['addedByNic'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Issue Details'),
            backgroundColor: const Color(0xFFE8F2FF),
            elevation: 1,
            actions: [
              // PDF Download Button
              FutureBuilder<QuerySnapshot>(
                future: _fetchReporterDetails(addedByNic),
                builder: (context, userSnap) {
                  final userData = (userSnap.hasData && userSnap.data!.docs.isNotEmpty)
                      ? userSnap.data!.docs.first.data() as Map<String, dynamic>
                      : null;
                  return IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                    onPressed: () => _downloadPdfReport(data, userData),
                    tooltip: 'Download PDF Report',
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
>>>>>>> main
  // Update Status Logic
  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({'status': newStatus});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
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
      appBar: AppBar(
        title: const Text('Issue Details'),
        backgroundColor: const Color(0xFFE8F2FF),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Changed to StreamBuilder so UI updates immediately when status changes
        stream: FirebaseFirestore.instance.collection('issues').doc(issueId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading details: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Issue not found or has been deleted.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final issueTitle = data['issueTitle'] ?? 'N/A';
          final issueType = data['issueType'] ?? 'N/A';
          final description = data['description'] ?? 'No description provided.';
          final status = data['status'] ?? 'Pending';
          final schoolName = data['schoolName'] ?? 'N/A';
          final schoolId = data['schoolId'] ?? 'N/A';
          final addedByNic = data['addedByNic'] ?? ''; // Get the NIC

          final List<String> imageUrls =
              (data['imageUrls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final dateReported = timestamp != null
              ? DateFormat('dd-MM-yyyy @ HH:mm').format(timestamp)
              : 'N/A';

          final statusColor = _getStatusColor(status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
<<<<<<< HEAD
=======
                _buildTitleSection(data['issueTitle'] ?? 'N/A', data['status'] ?? 'Pending'),
                const SizedBox(height: 10),
                if (addedByNic.isNotEmpty) _buildReporterCard(context, addedByNic),
                const SizedBox(height: 20),
                _buildInfoSection('Description', data['description'] ?? 'No description.', Icons.description_outlined, true),
                const SizedBox(height: 10),
                if (data['imageUrls'] != null) _buildPhotoSection(context, List<String>.from(data['imageUrls'])),
                const SizedBox(height: 10),
                _buildInfoSection('Issue Type', data['issueType'] ?? 'N/A', Icons.category_outlined),
                _buildInfoSection('School Name', data['schoolName'] ?? 'N/A', Icons.school_outlined),
                _buildInfoSection('School ID', data['schoolId'] ?? 'N/A', Icons.vpn_key_outlined),
                const SizedBox(height: 30),
                _buildUpdateButton(context, data['status'] ?? 'Pending'),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI Component Builders ---

  Widget _buildTitleSection(String title, String status) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Status: ', style: TextStyle(fontSize: 16)),
              Text(status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildReporterCard(BuildContext context, String nic) {
    return FutureBuilder<QuerySnapshot>(
      future: _fetchReporterDetails(nic),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) return const SizedBox();
        final userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        return InkWell(
          onTap: () => _showUserPopup(context, userData),
          child: Card(
            color: Colors.blue.shade50,
            child: ListTile(
              leading: CircleAvatar(backgroundImage: userData['profile_image'] != null ? NetworkImage(userData['profile_image']) : null),
              title: Text("${userData['name']} (${userData['userType']})", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Tap for contact info"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, String value, IconData icon, [bool longText = false]) {
    return Card(
      elevation: 0.5,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: TextStyle(fontSize: 16, fontWeight: longText ? FontWeight.normal : FontWeight.bold, color: Colors.black87)),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Attached Photos", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(images: images, initialIndex: i))),
              child: Padding(padding: const EdgeInsets.only(right: 8), child: Image.network(images[i], width: 100, fit: BoxFit.cover)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton(BuildContext context, String currentStatus) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showStatusChangeDialog(context),
        icon: const Icon(Icons.edit),
        label: const Text('Update Status'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
      ),
    );
  }

  void _showStatusChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pending', 'Processing', 'Processed'].map((s) => ListTile(
            title: Text(s),
            onTap: () { _updateStatus(context, s); Navigator.pop(context); },
          )).toList(),
        ),
      ),
    );
  }

  void _showUserPopup(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(userData['name'] ?? 'User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Email: ${userData['email']}"),
            Text("Mobile: ${userData['mobilePhone']}"),
            Text("NIC: ${userData['nic']}"),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
>>>>>>> main
                // ---------------- Title & Status Card ----------------
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issueTitle,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Status: ', style: TextStyle(fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ---------------- Reporter Info Section ----------------
                if (addedByNic.isNotEmpty)
                  FutureBuilder<QuerySnapshot>(
                    future: _fetchReporterDetails(addedByNic),
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

                // ---------------- Description ----------------
                _buildDetailSection(
                  context,
                  title: 'Description',
                  value: description,
                  icon: Icons.description_outlined,
                  isLongText: true,
                ),

                const SizedBox(height: 10),

                // ---------------- Photos Section ----------------
                if (imageUrls.isNotEmpty) ...[
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
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    images: imageUrls,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrls[index],
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

                // ---------------- Other Details ----------------
                _buildDetailSection(
                  context,
                  title: 'Issue Type',
                  value: issueType,
                  icon: Icons.category_outlined,
                ),
                _buildDetailSection(
                  context,
                  title: 'School Name',
                  value: schoolName,
                  icon: Icons.school_outlined,
                ),
                _buildDetailSection(
                  context,
                  title: 'School ID',
                  value: schoolId,
                  icon: Icons.vpn_key_outlined,
                ),
                _buildDetailSection(
                  context,
                  title: 'Reported On',
                  value: dateReported,
                  icon: Icons.access_time_outlined,
                ),

                const SizedBox(height: 30),

                // ---------------- Update Status Button ----------------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusChangeDialog(context, status),
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
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

  // --- Helper: Status Change Dialog ---
  void _showStatusChangeDialog(BuildContext context, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select New Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusOption(context, 'Pending', Colors.orange),
              _statusOption(context, 'Processing', Colors.blue),
              _statusOption(context, 'Processed', Colors.green),
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

  Widget _statusOption(BuildContext context, String status, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 16),
      title: Text(status),
      onTap: () {
        _updateStatus(context, status);
      },
    );
  }

  // --- Helper: User Details Popup ---
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
}