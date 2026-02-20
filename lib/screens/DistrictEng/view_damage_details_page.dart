import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'damage_details_dialog.dart'; // Corrected import to match the actual class name

class ViewDamageDetailsPage extends StatefulWidget {
  final String userNic; // User's NIC from login
  const ViewDamageDetailsPage({super.key, required this.userNic});

  @override
  State<ViewDamageDetailsPage> createState() => _ViewDamageDetailsPageState();
}

class _ViewDamageDetailsPageState extends State<ViewDamageDetailsPage> {
  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title:
            const Text('Damage Reports', style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      // --- Floating Action Button removed based on request ---
      
      body: StreamBuilder<QuerySnapshot>(
        // Assumes your collection is named 'issues' (or 'damageReports')
        stream: FirebaseFirestore.instance.collection('issues').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No damage reports found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final issueDoc = snapshot.data!.docs[index];
              return _buildIssueCard(issueDoc);
            },
          );
        },
      ),
    );
  }

  // --- Helper to get color for the status chip ---
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'In Progress':
        return Colors.blue.shade100;
      case 'Pending':
        return Colors.amber.shade100;
      case 'Resolved':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  // --- Helper to get text color for the status chip ---
  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'In Progress':
        return Colors.blue.shade800;
      case 'Pending':
        return Colors.amber.shade800;
      case 'Resolved':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  // --- Builds the individual issue card ---
  Widget _buildIssueCard(DocumentSnapshot issueDoc) {
    final data = issueDoc.data() as Map<String, dynamic>;
    final String issueId = issueDoc.id;
    final String title = data['issueTitle'] ?? 'No Title';
    final String school = data['schoolName'] ?? 'Unknown School';
    final String status = data['status'] ?? 'Unknown';

    return Card(
      elevation: 2,
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
                // --- Status Chip ---
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusTextColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: _getStatusColor(status),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              school,
              style: const TextStyle(color: kSubTextColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            // --- View and Edit Buttons ---
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DamageDetailsDialog(issueId: issueId), // Correct class name
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to an "EditIssueScreen"
                    // For now, it can also go to the details screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DamageDetailsDialog(issueId: issueId), // Correct class name
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}