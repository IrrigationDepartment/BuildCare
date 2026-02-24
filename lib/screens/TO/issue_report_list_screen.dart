import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'issue_report_details_screen.dart';
import 'add_issue_screen.dart';
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart'; // Add this for getting current user data

class IssueReportListScreen extends StatefulWidget {
  final String userNic; // User's NIC from login
  const IssueReportListScreen({super.key, required this.userNic});

  @override
  State<IssueReportListScreen> createState() => _IssueReportListScreenState();
}

class _IssueReportListScreenState extends State<IssueReportListScreen> {
  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kPrimaryDark = Color(0xFF312E81); // Indigo 900
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500
  static const Color kAccentColor = Color(0xFFEC4899); // Pink 500

  // User data variables
  String _userRole = '';
  String _userOffice = '';
  // ignore: unused_field
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
      // ignore: unused_local_variable
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
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_userRole == 'District Engineer')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    _userOffice,
                    style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
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
              label: const Text('Add Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              icon: const Icon(Icons.add_rounded, size: 24),
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
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
          return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // --- RESPONSIVE GRID FOR CARDS ---
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: GridView.extent(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for FAB
              maxCrossAxisExtent: 400, // Cards will be max 400px wide
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.6, // Adjust this ratio based on card height needs
              children: snapshot.data!.docs.map((issueDoc) {
                return _buildIssueCard(issueDoc);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDistrictEngineerIssues() {
    return FutureBuilder<List<String>>(
      future: _getSchoolNamesInDistrict(),
      builder: (context, schoolsSnapshot) {
        if (schoolsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
        }
        
        if (schoolsSnapshot.hasError || !schoolsSnapshot.hasData) {
          return Center(child: Text('Error loading schools: ${schoolsSnapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        
        final schoolNames = schoolsSnapshot.data!;
        if (schoolNames.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]
                  ),
                  child: Icon(Icons.school_rounded, size: 60, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 24),
                Text(
                  'No schools found in $_userOffice district',
                  style: const TextStyle(color: kSubTextColor, fontSize: 16, fontWeight: FontWeight.w500),
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
              return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
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
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]
                      ),
                      child: Icon(Icons.report_problem_rounded, size: 60, color: Colors.grey.shade300),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No issues found in $_userOffice district',
                      style: const TextStyle(color: kSubTextColor, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            // --- RESPONSIVE GRID FOR CARDS ---
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.extent(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  maxCrossAxisExtent: 400, 
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6, 
                  children: filteredIssues.map((issueDoc) {
                    return _buildIssueCard(issueDoc);
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'No issues found';
    IconData icon = Icons.check_circle_outline_rounded;
    
    if (_userRole == 'Principal') {
      message = 'You haven\'t reported any issues yet';
      icon = Icons.add_circle_outline_rounded;
    } else if (_userRole == 'District Engineer') {
      message = 'No issues in your district';
      icon = Icons.location_city_rounded;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]
            ),
            child: Icon(icon, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('All Clear!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: kSubTextColor, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // --- Helper to get color for the status chip ---
  Color _getStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in progress':
      case 'processing':
        return Colors.blue.shade50;
      case 'pending':
        return Colors.amber.shade50;
      case 'resolved':
      case 'completed':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  // --- Helper to get text color for the status chip ---
  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in progress':
      case 'processing':
        return Colors.blue.shade700;
      case 'pending':
        return Colors.amber.shade700;
      case 'resolved':
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
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

    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6)
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IssueReportDetailsScreen(
                  issueId: issueId,
                  userNic: widget.userNic,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Title & Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kTextColor,
                              letterSpacing: -0.5
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (location != null && location.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                location,
                                style: const TextStyle(
                                  color: kSubTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // --- Status Chip ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusTextColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Middle Row: Meta Data (School, Date, etc)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school_rounded, size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            school,
                            style: const TextStyle(color: kSubTextColor, fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    if (reporterNic != null && _userRole == 'District Engineer') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_rounded, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(
                            'NIC: $reporterNic',
                            style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                // Bottom Row: Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit Button (If allowed)
                    if (_canEditIssue(reporterNic)) ...[
                      TextButton.icon(
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
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: kAccentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // View Details Button
                    Container(
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IssueReportDetailsScreen(
                                issueId: issueId,
                                userNic: widget.userNic,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
}