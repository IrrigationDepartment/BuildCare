import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import destination screens
import 'IssueDetailScreen.dart';

class NotificationScreen extends StatefulWidget {
  final String loggedNic; // REQUIRE THE LOGGED-IN USER'S NIC

  const NotificationScreen({super.key, required this.loggedNic});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  // This function fetches your issues, then fetches the reviews inside them
  Future<List<Map<String, dynamic>>> _fetchMyReviews() async {
    List<Map<String, dynamic>> allReviews = [];

    try {
      // 1. Find all issues where addedByNic matches the logged in user's NIC
      var issuesSnapshot = await FirebaseFirestore.instance
          .collection('issues')
          .where('addedByNic', isEqualTo: widget.loggedNic)
          .get();

      // 2. Loop through each of your issues to get its 'reviews' subcollection
      for (var issueDoc in issuesSnapshot.docs) {
        var reviewsSnapshot = await issueDoc.reference.collection('reviews').get();

        for (var reviewDoc in reviewsSnapshot.docs) {
          var reviewData = reviewDoc.data();
          
          // Attach parent issue data so we know where this review came from
          reviewData['reviewId'] = reviewDoc.id;
          reviewData['issueId'] = issueDoc.id;
          reviewData['issueTitle'] = issueDoc.data()['issueTitle'] ?? 'Unknown Issue';
          reviewData['parentIssueData'] = issueDoc.data(); // Save for navigation later

          allReviews.add(reviewData);
        }
      }

      // 3. Sort all collected reviews by timestamp (Newest first)
      allReviews.sort((a, b) {
        Timestamp? timeA = a['timestamp'] as Timestamp?;
        Timestamp? timeB = b['timestamp'] as Timestamp?;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); // Descending order
      });

    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    }

    return allReviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      // Use FutureBuilder to run the 2-step fetch
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          List<Map<String, dynamic>> reviews = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Pull to refresh the reviews list
            },
            child: ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                var data = reviews[index];
                
                // Use the new optimized tile!
                return ReviewNotificationTile(
                  reviewData: data,
                  loggedNic: widget.loggedNic,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No new notifications',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- OPTIMIZED FACEBOOK-STYLE NOTIFICATION TILE ---
class ReviewNotificationTile extends StatefulWidget {
  final Map<String, dynamic> reviewData;
  final String loggedNic;

  const ReviewNotificationTile({
    Key? key,
    required this.reviewData,
    required this.loggedNic,
  }) : super(key: key);

  @override
  State<ReviewNotificationTile> createState() => _ReviewNotificationTileState();
}

class _ReviewNotificationTileState extends State<ReviewNotificationTile> {
  // Global cache to prevent lag when scrolling
  static final Map<String, Map<String, dynamic>> _userCache = {};
  
  String reviewerName = "Someone";
  String? profileImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String reviewerUid = widget.reviewData['reviewerNic'] ?? '';
    if (reviewerUid.isEmpty) return;

    // Load from cache instantly if we already downloaded this user's data
    if (_userCache.containsKey(reviewerUid)) {
      _applyUserData(_userCache[reviewerUid]!);
      return;
    }

    // Otherwise, fetch from Firebase
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(reviewerUid).get();
      if (doc.exists && doc.data() != null) {
        _userCache[reviewerUid] = doc.data() as Map<String, dynamic>;
        if (mounted) _applyUserData(_userCache[reviewerUid]!);
      }
    } catch (e) {
      debugPrint("Error fetching user for notification: $e");
    }
  }

  void _applyUserData(Map<String, dynamic> data) {
    setState(() {
      reviewerName = data['name'] ?? 'Someone';
      profileImage = data['profile_image'];
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now'; 
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      // Returns a clean format like "Feb 23, 1:26 PM"
      return DateFormat.yMMMd().add_jm().format(date);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    String reviewText = widget.reviewData['reviewText'] ?? 'No text provided';
    String issueTitle = widget.reviewData['issueTitle'] ?? 'an issue';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate directly to the Issue Details Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IssueDetailScreen(
                  issueData: widget.reviewData['parentIssueData'],
                  issueId: widget.reviewData['issueId'],
                  userNic: widget.loggedNic,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Image (or default icon)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                      ? NetworkImage(profileImage!)
                      : null,
                  child: (profileImage == null || profileImage!.isEmpty)
                      ? Icon(Icons.person, size: 28, color: Colors.blue.shade800)
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Facebook-style RichText (Bold name, normal text, bold issue)
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                          children: [
                            TextSpan(
                              text: "$reviewerName ",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: "reviewed your issue: "),
                            TextSpan(
                              text: issueTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // The actual review preview
                      Text(
                        '"$reviewText"',
                        style: TextStyle(
                          fontSize: 14, 
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Timestamp
                      Text(
                        _formatTimestamp(widget.reviewData['timestamp']),
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade400, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}