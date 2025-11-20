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

  // Current User Data for the Review Record
  String _currentEngineerName = '';
  String _currentEngineerNic = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  // 1. Get the Logged-in Engineer's Name and NIC
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
              _currentEngineerName = data['name'] ?? 'Unknown Engineer';
              _currentEngineerNic = data['nic'] ?? 'Unknown NIC';
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

  // 2. Function to Add a Review to Firestore
  Future<void> _addReviewToFirebase(String docId, String note) async {
    if (note.isEmpty) return;

    try {
      // We create a 'reviews' sub-collection inside the master plan document
      // This keeps a perfect history record.
      await FirebaseFirestore.instance
          .collection('schoolMasterPlans')
          .doc(docId)
          .collection('reviews') 
          .add({
        'note': note,
        'reviewerName': _currentEngineerName,
        'reviewerNic': _currentEngineerNic,
        'reviewedAt': Timestamp.now(), // Captures Date and Time
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review added successfully"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Close dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding review: $e"), backgroundColor: Colors.red),
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

  // 3. Stream ALL Master Plans (No filtering)
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
  void _showAddReviewDialog(BuildContext context, String docId) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              onPressed: () => _addReviewToFirebase(docId, noteController.text),
              child: const Text("Submit Review", style: TextStyle(color: Colors.white)),
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
            height: 300, // Fixed height for the list
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
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final String note = data['note'] ?? '';
                    final String reviewer = data['reviewerName'] ?? 'Unknown';
                    final Timestamp? ts = data['reviewedAt'];
                    final String dateStr = ts != null 
                        ? DateFormat('yyyy-MM-dd hh:mm a').format(ts.toDate()) 
                        : 'Unknown Date';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.comment, color: Colors.grey),
                      title: Text(note, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Image.network(imageUrl, fit: BoxFit.contain),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, spreadRadius: 1)],
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

  Widget _buildPlanTile(BuildContext context, String docId, Map<String, dynamic> data) {
    final String schoolName = data['schoolName'] ?? 'Unknown School';
    final String description = data['description'] ?? 'Master Plan';
    final String imageUrl = data['masterPlanUrl'] ?? '';
    
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, spreadRadius: 1)],
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
                    Text(schoolName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text('Uploaded: $updated', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (imageUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.image, color: _primaryBlue),
                  onPressed: () => _showImageDialog(context, schoolName, imageUrl),
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
                onPressed: () => _showAddReviewDialog(context, docId),
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