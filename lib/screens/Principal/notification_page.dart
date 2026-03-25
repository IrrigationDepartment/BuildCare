import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import destination screens
import 'IssueDetailScreen.dart';

class NotificationScreen extends StatefulWidget {
  final String loggedNic;

  const NotificationScreen({super.key, required this.loggedNic});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  Future<List<Map<String, dynamic>>> _fetchMyReviews() async {
    List<Map<String, dynamic>> allReviews = [];

    try {
      final issuesSnapshot = await FirebaseFirestore.instance
          .collection('issues')
          .where('addedByNic', isEqualTo: widget.loggedNic)
          .get();

      for (var issueDoc in issuesSnapshot.docs) {
        final reviewsSnapshot =
            await issueDoc.reference.collection('reviews').get();

        for (var reviewDoc in reviewsSnapshot.docs) {
          final reviewData = reviewDoc.data();

          final List<dynamic> readBy = reviewData['readBy'] ?? [];

          reviewData['reviewId'] = reviewDoc.id;
          reviewData['issueId'] = issueDoc.id;
          reviewData['issueTitle'] =
              issueDoc.data()['issueTitle'] ?? 'Unknown Issue';
          reviewData['parentIssueData'] = issueDoc.data();
          reviewData['isRead'] = readBy.contains(widget.loggedNic);

          allReviews.add(reviewData);
        }
      }

      allReviews.sort((a, b) {
        Timestamp? timeA = a['timestamp'] as Timestamp?;
        Timestamp? timeB = b['timestamp'] as Timestamp?;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA);
      });
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    }

    return allReviews;
  }

  Future<void> _markAllAsRead(List<Map<String, dynamic>> reviews) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final review in reviews) {
        final List<dynamic> readBy = review['readBy'] ?? [];
        if (readBy.contains(widget.loggedNic)) continue;

        final String issueId = review['issueId'] ?? '';
        final String reviewId = review['reviewId'] ?? '';

        if (issueId.isEmpty || reviewId.isEmpty) continue;

        final reviewRef = FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId)
            .collection('reviews')
            .doc(reviewId);

        batch.set(
          reviewRef,
          {
            'readBy': FieldValue.arrayUnion([widget.loggedNic]),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWideScreen = constraints.maxWidth > 800;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 800 : double.infinity,
                ),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchMyReviews(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final reviews = snapshot.data!;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markAllAsRead(reviews);
                    });

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final data = reviews[index];

                          return ReviewNotificationTile(
                            reviewData: data,
                            loggedNic: widget.loggedNic,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 80, color: Colors.grey[300]),
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

    if (_userCache.containsKey(reviewerUid)) {
      _applyUserData(_userCache[reviewerUid]!);
      return;
    }

    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reviewerUid)
          .get();

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
      return DateFormat.yMMMd().add_jm().format(date);
    }
    return '';
  }

  Future<void> _markThisAsRead() async {
    try {
      final String issueId = widget.reviewData['issueId'] ?? '';
      final String reviewId = widget.reviewData['reviewId'] ?? '';

      if (issueId.isEmpty || reviewId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .collection('reviews')
          .doc(reviewId)
          .set(
        {
          'readBy': FieldValue.arrayUnion([widget.loggedNic]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String reviewText = widget.reviewData['reviewText'] ?? 'No text provided';
    String issueTitle = widget.reviewData['issueTitle'] ?? 'an issue';
    bool isRead = widget.reviewData['isRead'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isRead ? Colors.grey.shade100 : Colors.blue.shade100,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await _markThisAsRead();

            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IssueDetailScreen(
                  issueData: widget.reviewData['parentIssueData'],
                  issueId: widget.reviewData['issueId'],
                  userNic: widget.loggedNic,
                ),
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  widget.reviewData['isRead'] = true;
                });
              }
            });
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage:
                          (profileImage != null && profileImage!.isNotEmpty)
                              ? NetworkImage(profileImage!)
                              : null,
                      child: (profileImage == null || profileImage!.isEmpty)
                          ? Icon(Icons.person,
                              size: 30, color: Colors.blue.shade400)
                          : null,
                    ),
                    if (!isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2C3E50),
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: "$reviewerName ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const TextSpan(text: "reviewed your issue:\n"),
                            TextSpan(
                              text: issueTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          '"$reviewText"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.blue.shade300),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(widget.reviewData['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade400,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}