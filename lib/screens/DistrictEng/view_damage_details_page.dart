import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'damage_details_dialog.dart';
import 'add_issue_screen.dart';
import 'add_issue_screen.dart'; 

class ViewDamageDetailsPage extends StatefulWidget {
  final String userNic;
  const ViewDamageDetailsPage({super.key, required this.userNic});

  @override
  State<ViewDamageDetailsPage> createState() => _ViewDamageDetailsPageState();
}

class _ViewDamageDetailsPageState extends State<ViewDamageDetailsPage> {
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Processing':
        return Colors.grey.shade300;
      case 'Pending':
        return Colors.amber.shade100;
      case 'Finished':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'Processing':
        return Colors.grey.shade800;
      case 'Pending':
        return Colors.amber.shade900;
      case 'Finished':
        return Colors.green.shade900;
      default:
        return Colors.grey.shade800;
    }
  }

  Future<void> _updateStatus(String issueId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({'status': newStatus});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Damage Reports', style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by title or school...',
                prefixIcon: const Icon(Icons.search, color: kPrimaryBlue),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5),
                ),
              ),
            ),
          ),

          // --- Damage Reports List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  return const Center(child: Text('No damage reports found.'));
                }

               
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['issueTitle'] ?? "").toString().toLowerCase();
                  final school = (data['schoolName'] ?? "").toString().toLowerCase();
                  return title.contains(_searchQuery) || school.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No results found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final issueDoc = filteredDocs[index];
                    return _buildIssueCard(issueDoc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'In Progress': return Colors.blue.shade100;
      case 'Pending': return Colors.amber.shade100;
      case 'Resolved': return Colors.green.shade100;
      default: return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'In Progress': return Colors.blue.shade800;
      case 'Pending': return Colors.amber.shade800;
      case 'Resolved': return Colors.green.shade800;
      default: return Colors.grey.shade800;
    }
  }

  Widget _buildIssueCard(DocumentSnapshot issueDoc) {
    final data = issueDoc.data() as Map<String, dynamic>;
    final String issueId = issueDoc.id;
    final String title = data['issueTitle'] ?? 'No Title';
    final String school = data['schoolName'] ?? 'Unknown School';
    final String currentStatus = data['status'] ?? 'Pending';
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
                        color: kTextColor),
                  ),
                ),
                // Status Dropdown Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: ['Pending', 'Processing', 'Finished']
                              .contains(currentStatus)
                          ? currentStatus
                          : 'Pending',
                      icon: Icon(Icons.arrow_drop_down,
                          color: _getStatusTextColor(currentStatus)),
                      style: TextStyle(
                        color: _getStatusTextColor(currentStatus),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _updateStatus(issueId, newValue);
                        }
                      },
                      items: <String>['Pending', 'Processing', 'Finished']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kTextColor),
                  ),
                ),
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(color: _getStatusTextColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(status),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(school,
                style: const TextStyle(color: kSubTextColor, fontSize: 14)),
            Text(school, style: const TextStyle(color: kSubTextColor, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DamageDetailsDialog(issueId: issueId),
                        builder: (context) => DamageDetailsDialog(issueId: issueId),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddIssueScreen(
                          userNic: widget.userNic,
                          issueId: issueId,
                          issueId: issueId, 
                        ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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