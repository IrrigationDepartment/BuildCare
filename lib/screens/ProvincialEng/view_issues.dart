// lib/view_issues.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Importing IssueDetailPage from dashboard.dart
import 'dashboard.dart'; 

class ViewIssuesPage extends StatelessWidget {
  const ViewIssuesPage({super.key});

  // Helper function to determine status color (Duplicated for simplicity, 
  // better to move to a common utility file in a real app)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
      case 'Pending':
        return Colors.orange.shade700;
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Resolved':
        return Colors.green.shade700;
      case 'Closed':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reported Issues'),
        backgroundColor: const Color(0xFFE8F2FF),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream to fetch all issues, ordered by timestamp
        stream: FirebaseFirestore.instance
            .collection('issues')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text('Error loading issues: ${snapshot.error}'));
          }

          // 3. No Data State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No issues have been reported yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
            );
          }

          final issues = snapshot.data!.docs;

          // 4. Data Loaded State (Display List)
          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issueDoc = issues[index];
              final issueData = issueDoc.data() as Map<String, dynamic>;
              final issueId = issueDoc.id; // Get the Issue ID
              
              final issueTitle = issueData['issueTitle'] ?? 'No Title';
              final schoolName = issueData['schoolName'] ?? 'Unknown School';
              final status = issueData['status'] ?? 'N/A';
              Color statusColor = _getStatusColor(status);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Icon(
                    Icons.warning_amber,
                    color: statusColor,
                    size: 30,
                  ),
                  title: Text(
                    issueTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(schoolName, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                  // 🚨 Updated Navigation Logic to IssueDetailPage
                  onTap: () {
                    // Pass the Issue ID to the Detail Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IssueDetailPage(issueId: issueId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}