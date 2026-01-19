import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SchoolMasterPlanPage extends StatefulWidget {
  const SchoolMasterPlanPage({super.key});

  @override
  State<SchoolMasterPlanPage> createState() => _SchoolMasterPlanPageState();
}

class _SchoolMasterPlanPageState extends State<SchoolMasterPlanPage> {
  // Colors
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _backgroundColor = Color(0xFFF0F2F5);

  // Current User Data (The person WRITING the review)
  String _currentEngineerName = '';
  String _currentEngineerNic = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  // 1. Get the Logged-in User's details
  Future<void> _fetchCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _currentEngineerName = data['name'] ?? 'Unknown User';
              // Ensure this field matches your Users collection (e.g., 'nic' or 'NIC')
              _currentEngineerNic = data['nic'] ?? '';
              _isLoadingUser = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  // 2. Function to Add Review AND Notification simultaneously
  Future<void> _addReviewToFirebase(
      {required String docId,
      required String note,
      required String planOwnerNic,
      required String schoolName}) async {
    if (note.isEmpty) return;

    try {
      // A. Start a Batch Write (Ensures both save, or neither saves)
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // B. Reference for the Review (Stored inside the plan)
      DocumentReference reviewRef = FirebaseFirestore.instance
          .collection('schoolMasterPlans')
          .doc(docId)
          .collection('reviews')
          .doc(); // Auto-ID

      // C. Reference for the Notification (Stored in public collection)
      DocumentReference notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(); // Auto-ID

      // D. Set Review Data
      batch.set(reviewRef, {
        'note': note,
        'reviewerName': _currentEngineerName,
        'reviewerNic': _currentEngineerNic,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // E. Set Notification Data
      // This creates the specific document your NotificationPage is listening for
      batch.set(notificationRef, {
        'receiverNic': planOwnerNic, // Who receives it (The Plan Owner)
        'senderNic': _currentEngineerNic, // Who sent it
        'senderName': _currentEngineerName,
        'title': 'New Review Received',
        'message': '$_currentEngineerName added a review for $schoolName',
        'type': 'review', // Used for the icon logic
        'isRead': false,
        'relatedPlanId': docId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // F. Commit the Batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Review sent successfully!"),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Close dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error adding review: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'All School Master Plans',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),

            // Master Plan List
            Expanded(
              child: _isLoadingUser
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAllMasterPlansStream(),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Stream ALL Master Plans
  Widget _buildAllMasterPlansStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schoolMasterPlans')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No master plans found."));
        }

        final allPlans = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: allPlans.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = allPlans[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPlanTile(context, doc.id, data);
          },
        );
      },
    );
  }

  // --- DIALOG: Add Review ---
  void _showAddReviewDialog(BuildContext context, String docId,
      String planOwnerNic, String schoolName) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Add Review Note"),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Enter your short note here...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
              onPressed: () {
                _addReviewToFirebase(
                    docId: docId,
                    note: noteController.text,
                    planOwnerNic: planOwnerNic, // Pass owner NIC
                    schoolName: schoolName // Pass School Name
                    );
              },
              child: const Text("Submit Review",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG: View Review History ---
  void _showReviewHistoryDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Review History"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schoolMasterPlans')
                  .doc(docId)
                  .collection('reviews')
                  .orderBy('reviewedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reviews yet."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    final String note = data['note'] ?? '';
                    final String reviewer = data['reviewerName'] ?? 'Unknown';
                    final Timestamp? ts = data['reviewedAt'];
                    final String dateStr = ts != null
                        ? DateFormat('yyyy-MM-dd h:mm a').format(ts.toDate())
                        : 'Unknown Date';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.comment, color: Colors.grey),
                      title: Text(note,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("By: $reviewer\n$dateStr"),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG: View Image ---
  void _showImageDialog(BuildContext context, String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Image.network(imageUrl, fit: BoxFit.contain),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"))
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              spreadRadius: 1)
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search Master Plan...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPlanTile(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final String schoolName = data['schoolName'] ?? 'Unknown School';
    final String description = data['description'] ?? 'Master Plan';
    final String imageUrl = data['masterPlanUrl'] ?? '';

    // CRITICAL: This gets the NIC of the user who created the plan
    final String planOwnerNic = data['addedByNic'] ?? '';

    String updated = 'Unknown Date';
    if (data['createdAt'] != null) {
      Timestamp t = data['createdAt'];
      updated = DateFormat('yyyy/MM/dd').format(t.toDate());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              spreadRadius: 1)
        ],
      ),
      child: Column(
        children: [
          // Top Row: Info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schoolName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text('Uploaded: $updated',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (imageUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.image, color: _primaryBlue),
                  onPressed: () =>
                      _showImageDialog(context, schoolName, imageUrl),
                )
            ],
          ),
          const Divider(),
          // Bottom Row: Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Add Review Button
              ElevatedButton.icon(
                onPressed: () => _showAddReviewDialog(
                    context, docId, planOwnerNic, schoolName),
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text('Add Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 35),
                ),
              ),
              // View History Button
              OutlinedButton.icon(
                onPressed: () => _showReviewHistoryDialog(context, docId),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  minimumSize: const Size(100, 35),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
