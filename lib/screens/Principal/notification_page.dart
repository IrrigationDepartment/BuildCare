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
          'My Issue Reviews',
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
                
                String reviewText = data['reviewText'] ?? 'No text provided';
                String issueTitle = data['issueTitle'] ?? '';
                
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimaryBlue.withOpacity(0.1),
                      child: const Icon(Icons.rate_review_rounded, color: kPrimaryBlue),
                    ),
                    title: Text(
                      'Re: $issueTitle', // Shows the title of the issue being reviewed
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          reviewText,
                          style: const TextStyle(fontSize: 14, color: kSubTextColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTimestamp(data['timestamp']),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate directly to the Issue Details Screen using the attached parent data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IssueDetailScreen(
                            issueData: data['parentIssueData'],
                            issueId: data['issueId'],
                            userNic: widget.loggedNic,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now'; 
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return DateFormat.yMMMd().add_jm().format(date);
    }
    return '';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No reviews on your issues yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}