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
  static const int _maxImagesToDisplay = 10; // Image limit: Only display first 10
  
  // New: Controller for the image carousel
  late PageController _pageController; 
  int _currentPage = 0;

  // --- Utility Functions ---

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date N/A';
    return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
  }

  // Function to move to the next image
  void _nextImage() {
    if (_currentPage < _imageUrlsState.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  // Function to move to the previous image
  void _previousImage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
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

          // Apply the 10-image limit here
          setState(() {
            _imageUrlsState = fresh.take(_maxImagesToDisplay).toList();
            // Reset page index if the list changed significantly
            if (_pageController.hasClients) {
              _currentPage = 0; 
              _pageController.jumpToPage(0);
            }
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
    _pageController = PageController();
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
    
    // Apply the 10-image limit during initialization as well
    _imageUrlsState = initial.take(_maxImagesToDisplay).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            // --- Image Carousel Implementation ---
            if (_imageUrlsState.isNotEmpty) ...[
              SizedBox(
                height: 250, // Height for the image carousel
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. PageView (The Carousel itself)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _imageUrlsState.length,
                      itemBuilder: (context, index) {
                        final url = _imageUrlsState[index];
                        return GestureDetector(
                          onTap: () => _openImageViewer(url),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
                                width: double.infinity, 
                                height: 250, 
                                fit: BoxFit.cover,
                                loadingBuilder: (c, w, p) => p == null
                                    ? w
                                    : const Center(child: CircularProgressIndicator()),
                                errorBuilder: (c, o, s) => Container(
                                  width: double.infinity,
                                  height: 250,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // 2. Navigation Chevrons (Left)
                    if (_imageUrlsState.length > 1) 
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(Icons.chevron_left, size: 40, 
                                     color: _currentPage > 0 ? _primaryColor : Colors.grey.shade400),
                          onPressed: _previousImage,
                        ),
                      ),

                    // 3. Navigation Chevrons (Right)
                    if (_imageUrlsState.length > 1) 
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.chevron_right, size: 40, 
                                     color: _currentPage < _imageUrlsState.length - 1 ? _primaryColor : Colors.grey.shade400),
                          onPressed: _nextImage,
                        ),
                      ),
                  ],
                ),
              ),

              // 4. Image Counter (e.g., 1/3)
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '${_currentPage + 1} / ${_imageUrlsState.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const Divider(height: 30), 
            ],
            // --- End Image Carousel Implementation ---

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
                    ),
                  ),
                ).then((result) {
                  // If editing changed the document, re-fetch images so user can see uploads immediately
                  if (result == true) {
                    _refreshImages();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Issue updated — images refreshed')),
                      );
                    }
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