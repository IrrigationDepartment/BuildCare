// lib/view_issues.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Importing the main file as IssueDetailPage is defined there
import 'dashboard.dart'; 

class ViewIssuesPage extends StatelessWidget {
  const ViewIssuesPage({super.key});

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
              final issueId = issueDoc.id; // 🚨 Get the Issue ID
              
              final schoolName = issueData['schoolName'] ?? 'Unknown School';
              final issueTitle = issueData['issueTitle'] ?? 'No Title';
              final status = issueData['status'] ?? 'N/A';
              
              Color statusColor;
              IconData statusIcon;
              
              // Determine icon and color based on status
              if (status == 'Resolved' || status == 'Completed') {
                statusColor = Colors.green.shade600;
                statusIcon = Icons.check_circle;
              } else if (status == 'Pending' || status == 'New') {
                statusColor = Colors.red.shade700;
                statusIcon = Icons.error;
              } else if (status == 'Ongoing' || status == 'In Progress') {
                statusColor = Colors.orange.shade600;
                statusIcon = Icons.pending_actions;
              } else {
                statusColor = Colors.grey.shade600;
                statusIcon = Icons.info_outline;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: statusColor.withOpacity(0.4), width: 1),
                ),
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor, size: 28),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Pass the Issue ID to the Detail Page
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