import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'issue_report_details_screen.dart';
<<<<<<< HEAD
=======
import 'add_issue_screen.dart'; 
import 'add_issue_screen.dart'; // Placeholder for adding new issues
>>>>>>> main
import 'add_issue_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this for getting current user data

class IssueReportListScreen extends StatefulWidget {
  final String userNic; // User's NIC from login
  const IssueReportListScreen({super.key, required this.userNic});

  @override
  State<IssueReportListScreen> createState() => _IssueReportListScreenState();
}

class _IssueReportListScreenState extends State<IssueReportListScreen> {
  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  // User data variables
  String _userRole = '';
  String _userOffice = '';
  String _userName = '';
  late Stream<QuerySnapshot> _issuesStream;

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndSetStream();
  }

  Future<void> _fetchUserDataAndSetStream() async {
    try {
      // Fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: widget.userNic)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data();
        setState(() {
          _userRole = userData['userType'] ?? '';
          _userOffice = userData['office'] ?? '';
          _userName = userData['name'] ?? '';
        });
        
        // Set up the stream with proper filtering
        _setupIssuesStream();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  void _setupIssuesStream() {
    Query query = FirebaseFirestore.instance.collection('issues');
    
    // Apply role-based filtering
    if (_userRole == 'District Engineer') {
      // District Engineer: Filter by office district
      // First, get all schools in the district
      final schoolsQuery = FirebaseFirestore.instance
          .collection('schools')
          .where('educationalZone', isEqualTo: _userOffice)
          .snapshots();
      
      // We need to handle this differently - show a loading state first
      // The actual filtering will happen in the StreamBuilder
      query = query.orderBy('timestamp', descending: true);
    } else if (_userRole == 'Principal') {
      // Principal: Filter by their NIC (only their own issues)
      query = query
          .where('addedByNic', isEqualTo: widget.userNic)
          .orderBy('timestamp', descending: true);
    } else if (_userRole == 'Technical Officer') {
      // Technical Officer: Get all issues
      query = query.orderBy('timestamp', descending: true);
    } else {
      // Default: Show all issues
      query = query.orderBy('timestamp', descending: true);
    }
    
    setState(() {
      _issuesStream = query.snapshots();
    });
  }

  Future<List<String>> _getSchoolNamesInDistrict() async {
    try {
      final schoolsSnap = await FirebaseFirestore.instance
          .collection('schools')
          .where('educationalZone', isEqualTo: _userOffice)
          .get();
      
      return schoolsSnap.docs
          .map((doc) => doc.data()['schoolName'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint("Error fetching schools in district: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
<<<<<<< HEAD
=======
        title: const Text('Issue Report', style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      // --- Button to add a new issue report ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddIssueScreen(userNic: widget.userNic),
            ),
          );
        },
        label: const Text('Add Issue'),
        icon: const Icon(Icons.add),
        backgroundColor: kPrimaryBlue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Assumes your collection is named 'issues'
        stream: FirebaseFirestore.instance.collection('issues').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No issues found.'));
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
>>>>>>> main
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: kTextColor),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          if (_userRole == 'District Engineer')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                label: Text(
                  _userOffice,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: kPrimaryBlue,
              ),
            ),
        ],
      ),
      // --- Button to add a new issue report ---
      floatingActionButton: _userRole == 'Principal' 
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddIssueScreen(userNic: widget.userNic),
                  ),
                );
              },
              label: const Text('Add Issue'),
              icon: const Icon(Icons.add),
              backgroundColor: kPrimaryBlue,
            )
          : null,
      body: _buildBody(),
    );
  }

  String _getAppBarTitle() {
    if (_userRole == 'Principal') {
      return 'My Issue Reports';
    } else if (_userRole == 'District Engineer') {
      return 'Issues - $_userOffice District';
    } else {
      return 'Issue Reports';
    }
  }

  Widget _buildBody() {
    // If user data is still loading
    if (_userRole.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // For District Engineers, we need special handling
    if (_userRole == 'District Engineer') {
      return _buildDistrictEngineerIssues();
    }

    // For Principals and others
    return StreamBuilder<QuerySnapshot>(
      stream: _issuesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
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
    );
  }

  Widget _buildDistrictEngineerIssues() {
    return FutureBuilder<List<String>>(
      future: _getSchoolNamesInDistrict(),
      builder: (context, schoolsSnapshot) {
        if (schoolsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (schoolsSnapshot.hasError || !schoolsSnapshot.hasData) {
          return Center(child: Text('Error loading schools: ${schoolsSnapshot.error}'));
        }
        
        final schoolNames = schoolsSnapshot.data!;
        if (schoolNames.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No schools found in $_userOffice district',
                  style: const TextStyle(color: kSubTextColor),
                ),
              ],
            ),
          );
        }
        
        return StreamBuilder<QuerySnapshot>(
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
              return _buildEmptyState();
            }

            // Filter issues by school names in the district
            final filteredIssues = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final schoolName = data['schoolName'] as String? ?? '';
              return schoolNames.contains(schoolName);
            }).toList();

            if (filteredIssues.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.report_problem, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No issues found in $_userOffice district',
                      style: const TextStyle(color: kSubTextColor),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredIssues.length,
              itemBuilder: (context, index) {
                final issueDoc = filteredIssues[index];
                return _buildIssueCard(issueDoc);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'No issues found';
    IconData icon = Icons.report_problem;
    
    if (_userRole == 'Principal') {
      message = 'You haven\'t reported any issues yet';
      icon = Icons.add_circle_outline;
    } else if (_userRole == 'District Engineer') {
      message = 'No issues in your district';
      icon = Icons.location_city;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: kSubTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- Helper to get color for the status chip ---
  Color _getStatusColor(String? status) {
<<<<<<< HEAD
=======
    switch (status) {
      case 'In Progress':
        return Colors.blue.shade100;
      case 'Pending':
        return Colors.amber.shade100;
      case 'Resolved':
>>>>>>> main
    switch (status?.toLowerCase()) {
      case 'in progress':
      case 'processing':
        return Colors.blue.shade100;
      case 'pending':
        return Colors.amber.shade100;
      case 'resolved':
      case 'completed':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  // --- Helper to get text color for the status chip ---
  Color _getStatusTextColor(String? status) {
<<<<<<< HEAD
=======
    switch (status) {
      case 'In Progress':
        return Colors.blue.shade800;
      case 'Pending':
        return Colors.amber.shade800;
      case 'Resolved':
>>>>>>> main
    switch (status?.toLowerCase()) {
      case 'in progress':
      case 'processing':
        return Colors.blue.shade800;
      case 'pending':
        return Colors.amber.shade800;
      case 'resolved':
      case 'completed':
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
    final String? reporterNic = data['addedByNic'];
    final String? location = data['location'] ?? data['buildingName'];
    final Timestamp? timestamp = data['timestamp'];
    final DateTime? date = timestamp?.toDate();
    
    // Format date
    String dateStr = '';
    if (date != null) {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

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
<<<<<<< HEAD
=======
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
>>>>>>> main
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      if (location != null && location.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Location: $location',
                            style: const TextStyle(
                              color: kSubTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
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
<<<<<<< HEAD
=======
            const SizedBox(height: 4),
            Text(
              school,
              style: const TextStyle(color: kSubTextColor, fontSize: 14),
            ),
>>>>>>> main
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.school, size: 14, color: kSubTextColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    school,
                    style: const TextStyle(color: kSubTextColor, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: kSubTextColor),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(color: kSubTextColor, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (reporterNic != null && _userRole == 'District Engineer') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: kSubTextColor),
                  const SizedBox(width: 4),
                  Text(
                    'Reported by: $reporterNic',
                    style: const TextStyle(color: kSubTextColor, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // --- View and Edit Buttons ---
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
<<<<<<< HEAD
=======
                        builder: (context) =>
                            IssueReportDetailsScreen(issueId: issueId),
>>>>>>> main
                        builder: (context) => IssueReportDetailsScreen(
                          issueId: issueId,
                          userNic: widget.userNic,
                        ),
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
<<<<<<< HEAD
=======
                ElevatedButton.icon(
                  onPressed: () {
                    // --- MODIFICATION ---
                    // Navigate directly to AddIssueScreen in Edit Mode
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddIssueScreen(
                          userNic: widget.userNic,
                          issueId: issueId, // Pass the ID to enable edit mode
                        ),
                      ),
                    );
                    // --- END OF MODIFICATION ---
                    // TODO: Navigate to an "EditIssueScreen"
                    // For now, it can also go to the details screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            IssueReportDetailsScreen(issueId: issueId),
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
}
>>>>>>> main
                // Show edit button only for the reporter or admin roles
                if (_canEditIssue(reporterNic))
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddIssueScreen(
                            userNic: widget.userNic,
                            issueId: issueId, // Pass the ID to enable edit mode
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
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canEditIssue(String? reporterNic) {
    // Principals can only edit their own issues
    if (_userRole == 'Principal') {
      return reporterNic == widget.userNic;
    }
    
    // District Engineers and Technical Officers can edit all issues in their view
    return _userRole == 'District Engineer' || _userRole == 'Technical Officer';
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> main
