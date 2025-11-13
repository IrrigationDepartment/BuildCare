// issue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Assuming you have an AddBuildingIssuesPage for editing
import 'add_building_issues_page.dart'; 

class IssueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> issueData;
  final String issueId;
  final String userNic;

  const IssueDetailScreen({
    Key? key,
    required this.issueData,
    required this.issueId,
    required this.userNic,
  }) : super(key: key);

  @override
  _IssueDetailScreenState createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  static const Color _primaryColor = Color(0xFF53BDFF);
  bool _isDeleting = false;
  List<String> _imageUrlsState = []; // holds current image urls for display

  // --- Utility Functions ---

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date N/A';
    return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
  }

  // Fetch latest imageUrls from Firestore for this issue (useful after upload)
  Future<void> _refreshImages() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('issues').doc(widget.issueId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final List<String> fresh = [];
          if (data['imageUrls'] is List) {
            for (var it in List.from(data['imageUrls'])) {
              if (it != null) {
                final s = it.toString();
                if (s.isNotEmpty) fresh.add(s);
              }
            }
          } else if (data['imageUrls'] is String) {
            // comma separated
            final raw = (data['imageUrls'] as String).split(',');
            for (var s in raw) {
              final t = s.trim();
              if (t.isNotEmpty) fresh.add(t);
            }
          }
          final single = data['imageUrl'] ?? '';
          if (single is String && single.isNotEmpty && !fresh.contains(single)) fresh.insert(0, single);
          setState(() {
            _imageUrlsState = fresh;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to refresh images: $e')));
      }
    }
  }

  // --- DELETE FUNCTION ---

  Future<void> _deleteIssue() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Issue deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to the dashboard after successful deletion
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting issue: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // --- Confirmation Dialog ---

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this issue report?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deleteIssue();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // --- Image viewer ---
  void _openImageViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, w, p) => p == null
                      ? w
                      : const SizedBox(
                          width: 60,
                          height: 60,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 60, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Widget Build ---

  @override
  void initState() {
    super.initState();
    // initialize local image list from passed issueData
    final List<String> initial = [];
    final raw = widget.issueData['imageUrls'];
    if (raw is List) {
      for (var it in List.from(raw)) {
        if (it != null) {
          final s = it.toString();
          if (s.isNotEmpty) initial.add(s);
        }
      }
    } else if (raw is String) {
      for (var s in raw.split(',')) {
        final t = s.trim();
        if (t.isNotEmpty) initial.add(t);
      }
    }
    final single = widget.issueData['imageUrl'] ?? '';
    if (single is String && single.isNotEmpty && !initial.contains(single)) initial.insert(0, single);
    _imageUrlsState = initial;
  }

  @override
  Widget build(BuildContext context) {
    // Safely extract data from the map
    final String title = widget.issueData['issueTitle'] ?? 'No Title';
    final String schoolName = widget.issueData['schoolName'] ?? 'N/A';
    final String building = widget.issueData['buildingName'] ?? 'N/A';
    final String description = widget.issueData['description'] ?? 'No description provided.';
    final String status = widget.issueData['status'] ?? 'Pending';
    final String date = _formatDate(widget.issueData['dateOfOccurance'] as Timestamp?);


    return Scaffold(
      appBar: AppBar(
        title: const Text("Issue Details", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: _primaryColor),
        actions: [
          IconButton(
            tooltip: 'Refresh images',
            onPressed: _refreshImages,
            icon: const Icon(Icons.refresh, color: _primaryColor),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Display: show a gallery (thumbnails) if images exist
            if (_imageUrlsState.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrlsState.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final url = _imageUrlsState[index];
                    return GestureDetector(
                      onTap: () => _openImageViewer(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 320,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (c, w, p) => p == null
                              ? w
                              : const SizedBox(
                                  width: 320,
                                  height: 200,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                          errorBuilder: (c, o, s) => Container(
                            width: 320,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Title and Status
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'Pending' ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: status == 'Pending' ? Colors.orange.shade800 : Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 30),

            // Details Section
            _buildDetailRow(Icons.date_range, "Date Reported:", date),
            _buildDetailRow(Icons.school, "School:", schoolName),
            _buildDetailRow(Icons.location_city, "Building:", building),
            const SizedBox(height: 15),

            const Text("Description:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(fontSize: 16)),

            const Divider(height: 40),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            // EDIT Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddBuildingIssuesPage(
                      userNic: widget.userNic,
                      issueId: widget.issueId,
                      issueData: widget.issueData,
                    ),
                  ),
                ).then((result) {
                  // If editing changed the document, re-fetch images so user can see uploads immediately
                  if (result == true) {
                    _refreshImages();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue updated — images refreshed')),
                    );
                  }
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit Issue"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),

                // DELETE Button
                _isDeleting
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _showDeleteConfirmationDialog,
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper for consistent detail display
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _primaryColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}