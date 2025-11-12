// lib/view_issues.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        // 🚨 Filter එකක් නැතිව Issues collection එකේ ඇති සියලු documents ලබා ගනියි.
        stream: FirebaseFirestore.instance
            .collection('issues')
            .orderBy('timestamp', descending: true) // නවතම Issues මුලින්ම
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading issues: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No issues have been reported yet.',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          final issues = snapshot.data!.docs;

          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issueDoc = issues[index];
              final issueData = issueDoc.data() as Map<String, dynamic>;
              
              final schoolName = issueData['schoolName'] ?? 'Unknown School';
              final issueTitle = issueData['issueTitle'] ?? 'No Title';
              final status = issueData['status'] ?? 'N/A';
              
              // Status එක අනුව icon එකේ පාට වෙනස් කරයි
              Color statusColor;
              IconData statusIcon;
              if (status == 'Resolved') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle_outline;
              } else if (status == 'Pending' || status == 'New') {
                statusColor = Colors.red.shade700;
                statusIcon = Icons.error_outline;
              } else {
                statusColor = Colors.orange;
                statusIcon = Icons.pending_actions;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: Colors.white,
                elevation: 1,
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text(
                    issueTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$schoolName | Status: $status',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Issue එකේ විස්තර බැලීම සඳහා අදාල පිටුවට යන්න
                    print('Viewing details for Issue ID: ${issueDoc.id}');
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