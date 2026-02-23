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
  List<String> _imageUrlsState = []; 
  static const int _maxImagesToDisplay = 10; 
  
  late PageController _pageController; 
  int _currentPage = 0;

  // --- Utility Functions ---

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date N/A';
    return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
  }

  String _formatReviewTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    return DateFormat.yMMMd().add_jm().format(timestamp.toDate());
  }

  void _nextImage() {
    if (_currentPage < _imageUrlsState.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousImage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

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
            final raw = (data['imageUrls'] as String).split(',');
            for (var s in raw) {
              final t = s.trim();
              if (t.isNotEmpty) fresh.add(t);
            }
          }
          final single = data['imageUrl'] ?? '';
          if (single is String && single.isNotEmpty && !fresh.contains(single)) fresh.insert(0, single);

          setState(() {
            _imageUrlsState = fresh.take(_maxImagesToDisplay).toList();
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
                Navigator.of(context).pop(); 
                _deleteIssue();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    
    _imageUrlsState = initial.take(_maxImagesToDisplay).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            if (_imageUrlsState.isNotEmpty) ...[
              SizedBox(
                height: 250, 
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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
                    
                    if (_imageUrlsState.length > 1) 
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(Icons.chevron_left, size: 40, 
                                     color: _currentPage > 0 ? _primaryColor : Colors.grey.shade400),
                          onPressed: _previousImage,
                        ),
                      ),

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

              const SizedBox(height: 10),
              Center(
                child: Text(
                  '${_currentPage + 1} / ${_imageUrlsState.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const Divider(height: 30), 
            ],

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

            _buildDetailRow(Icons.date_range, "Date Reported:", date),
            _buildDetailRow(Icons.school, "School:", schoolName),
            _buildDetailRow(Icons.location_city, "Building:", building),
            const SizedBox(height: 15),

            const Text("Description:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(fontSize: 16)),

            const Divider(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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

            const Divider(height: 40),

            // --- REVIEWS SECTION START ---
            const Text(
              "Reviews & Feedback", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
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
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        "No reviews available yet.",
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var reviewDoc = snapshot.data!.docs[index];
                    var reviewData = reviewDoc.data() as Map<String, dynamic>;

                    String reviewText = reviewData['reviewText'] ?? 'No feedback text provided.';
                    // This is actually the user's document ID based on your database screenshot
                    String reviewerUid = reviewData['reviewerNic'] ?? ''; 
                    String timestampStr = _formatReviewTime(reviewData['timestamp'] as Timestamp?);

                    // NEW: Fetch the specific user's data using their UID
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(reviewerUid).get(),
                      builder: (context, userSnapshot) {
                        String reviewerName = "Loading...";
                        String reviewerType = "Admin";
                        String? profileImage;

                        // Once the user's info loads, extract their real name, type, and image
                        if (userSnapshot.connectionState == ConnectionState.done) {
                          if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            reviewerName = userData['name'] ?? 'Unknown Admin';
                            reviewerType = userData['userType'] ?? 'Admin';
                            profileImage = userData['profile_image'];
                          } else {
                            reviewerName = "Unknown User";
                          }
                        }

                        return Card(
                          elevation: 0,
                          color: Colors.blue.shade50, 
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.blue.shade100),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Circular Profile Image
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blue.shade200,
                                      backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                                          ? NetworkImage(profileImage)
                                          : null,
                                      child: (profileImage == null || profileImage.isEmpty)
                                          ? Icon(Icons.person, size: 20, color: Colors.blue.shade800)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Name and User Type Stacked
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reviewerName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            reviewerType,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Timestamp
                                    Text(
                                      timestampStr,
                                      style: TextStyle(fontSize: 12, color: Colors.blue.shade400),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Review Description
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
              },
            ),
            // --- REVIEWS SECTION END ---
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
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