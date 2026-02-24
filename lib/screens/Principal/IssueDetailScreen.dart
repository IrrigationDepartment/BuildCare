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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isLargeScreen = constraints.maxWidth > 800;

            if (isLargeScreen) {
              // --- TWO-COLUMN DESKTOP LAYOUT ---
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Images, Title, and Actions
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageCarousel(),
                            const SizedBox(height: 16),
                            _buildTitleAndStatus(title, status),
                            const Divider(height: 30),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // RIGHT COLUMN: Details and Reviews
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailsSection(date, schoolName, building, description),
                            const Divider(height: 40),
                            _buildReviewsSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // --- SINGLE-COLUMN MOBILE LAYOUT ---
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(),
                  _buildTitleAndStatus(title, status),
                  const Divider(height: 30),
                  _buildDetailsSection(date, schoolName, building, description),
                  const Divider(height: 40),
                  _buildActionButtons(),
                  const Divider(height: 40),
                  _buildReviewsSection(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- UI COMPONENT BUILDERS ---

  Widget _buildImageCarousel() {
    if (_imageUrlsState.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
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
    );
  }

  Widget _buildTitleAndStatus(String title, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildDetailsSection(String date, String schoolName, String building, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.date_range, "Date Reported:", date),
        _buildDetailRow(Icons.school, "School:", schoolName),
        _buildDetailRow(Icons.location_city, "Building:", building),
        const SizedBox(height: 15),

        const Text("Description:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(description, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                var reviewData = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                String reviewText = reviewData['reviewText'] ?? 'No feedback text provided.';
                String reviewerUid = reviewData['reviewerNic'] ?? ''; 
                
                String timestampStr = 'Just now';
                if(reviewData['timestamp'] != null) {
                  timestampStr = DateFormat.yMMMd().add_jm().format((reviewData['timestamp'] as Timestamp).toDate());
                }

                return ReviewCard(
                  reviewerUid: reviewerUid, 
                  reviewText: reviewText, 
                  timestampStr: timestampStr
                );
              },
            );
          },
        ),
      ],
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

// ============================================================================
// OPTIMIZED REVIEW CARD WIDGET
// Prevents duplicate Firestore calls while scrolling through reviews
// ============================================================================
class ReviewCard extends StatefulWidget {
  final String reviewerUid;
  final String reviewText;
  final String timestampStr;

  const ReviewCard({
    Key? key,
    required this.reviewerUid,
    required this.reviewText,
    required this.timestampStr,
  }) : super(key: key);

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  static final Map<String, Map<String, dynamic>> _userCache = {};
  
  String reviewerName = "Loading...";
  String reviewerType = "Admin";
  String? profileImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (widget.reviewerUid.isEmpty) {
      if (mounted) setState(() => reviewerName = "Unknown User");
      return;
    }

    if (_userCache.containsKey(widget.reviewerUid)) {
      _applyUserData(_userCache[widget.reviewerUid]!);
      return;
    }

    try {
      // 1. Try fetching by Document ID
      var doc = await FirebaseFirestore.instance.collection('users').doc(widget.reviewerUid).get();
      if (doc.exists && doc.data() != null) {
        _userCache[widget.reviewerUid] = doc.data() as Map<String, dynamic>;
        if (mounted) _applyUserData(_userCache[widget.reviewerUid]!);
      } else {
        // 2. Fallback: Try fetching by NIC field
        var query = await FirebaseFirestore.instance.collection('users').where('nic', isEqualTo: widget.reviewerUid).limit(1).get();
        if(query.docs.isNotEmpty) {
           _userCache[widget.reviewerUid] = query.docs.first.data();
           if (mounted) _applyUserData(_userCache[widget.reviewerUid]!);
        } else {
          if (mounted) setState(() => reviewerName = "Unknown User");
        }
      }
    } catch (e) {
      if (mounted) setState(() => reviewerName = "Error");
    }
  }

  void _applyUserData(Map<String, dynamic> data) {
    setState(() {
      reviewerName = data['name'] ?? 'Unknown Admin';
      reviewerType = data['userType'] ?? 'Admin';
      profileImage = data['profile_image'];
    });
  }

  @override
  Widget build(BuildContext context) {
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade200,
                  backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                      ? NetworkImage(profileImage!)
                      : null,
                  child: (profileImage == null || profileImage!.isEmpty)
                      ? Icon(Icons.person, size: 20, color: Colors.blue.shade800)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewerName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 15),
                      ),
                      Text(
                        reviewerType,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.timestampStr,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade400),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.reviewText,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}