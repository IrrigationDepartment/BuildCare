// lib/view_issues.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; //

// ----------------------------------------------------------------------------
// --- Main View Issues Page (No change to this part) ---
// ----------------------------------------------------------------------------
class ViewIssuesPage extends StatelessWidget {
  const ViewIssuesPage({super.key});

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
        stream: FirebaseFirestore.instance
            .collection('issues')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No issues reported yet.'));
          }

          final issues = snapshot.data!.docs;

          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issueDoc = issues[index];
              final data = issueDoc.data() as Map<String, dynamic>;
              
              final issueId = issueDoc.id;
              final issueTitle = data['issueTitle'] ?? 'No Title';
              final schoolName = data['schoolName'] ?? 'Unknown School';
              final status = data['status'] ?? 'N/A';
              final statusColor = _getStatusColor(status);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: statusColor),
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

// ----------------------------------------------------------------------------
// --- IssueDetailPage (Updated to display details in a Form-style layout) ---
// ----------------------------------------------------------------------------
class IssueDetailPage extends StatelessWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

  // Helper function to fetch the specific issue document
  Future<DocumentSnapshot> _fetchIssueDetails() {
    return FirebaseFirestore.instance.collection('issues').doc(issueId).get();
  }

  // Helper function to determine status color (Duplicated for consistency)
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
        title: const Text('Issue Details'),
        backgroundColor: const Color(0xFFE8F2FF),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchIssueDetails(),
        builder: (context, snapshot) {
          // 1. Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error loading details: ${snapshot.error}'));
          }

          // 3. Data missing state
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text('Issue not found or has been deleted.', style: TextStyle(fontSize: 18)));
          }

          // 4. Data loaded state
          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          final issueTitle = data['issueTitle'] ?? 'N/A';
          final issueType = data['issueType'] ?? 'N/A';
          final description = data['description'] ?? 'No description provided.';
          final status = data['status'] ?? 'N/A';
          final schoolName = data['schoolName'] ?? 'N/A';
          final schoolId = data['schoolId'] ?? 'N/A';
          
          // Format timestamp
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final dateReported = timestamp != null
              ? DateFormat('dd-MM-yyyy @ HH:mm').format(timestamp)
              : 'N/A';
          
          final statusColor = _getStatusColor(status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // --- Title Card ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issueTitle,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Status: ', style: TextStyle(fontSize: 16)),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Description ---
                _buildDetailSection(
                  context,
                  title: 'Description',
                  value: description,
                  icon: Icons.description_outlined,
                  isLongText: true,
                ),
                const SizedBox(height: 10),
                
                // --- Issue Type and School Details ---
                _buildDetailSection(
                  context,
                  title: 'Issue Type',
                  value: issueType,
                  icon: Icons.category_outlined,
                ),
                _buildDetailSection(
                  context,
                  title: 'School Name',
                  value: schoolName,
                  icon: Icons.school_outlined,
                ),
                _buildDetailSection(
                  context,
                  title: 'School ID',
                  value: schoolId,
                  icon: Icons.vpn_key_outlined,
                ),

                // --- Timestamp ---
                _buildDetailSection(
                  context,
                  title: 'Reported On',
                  value: dateReported,
                  icon: Icons.access_time_outlined,
                ),
                
                // --- Action Buttons (Placeholder for future functionality) ---
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement Status Change logic (e.g., Change to 'In Progress')
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Status Change Button Pressed')),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widget for displaying individual details ---
  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.blueGrey.shade700, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const Divider(height: 10),
              // Use a larger vertical padding for long descriptions
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isLongText ? 4.0 : 0.0, vertical: 4.0),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isLongText ? 16 : 17,
                    fontWeight: isLongText ? FontWeight.normal : FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}