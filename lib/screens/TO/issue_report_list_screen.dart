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

  // --- FILTER STATE ---
  String? _selectedDamageType;
  final List<String> _allDamageTypes = [
    'Foundation & Wall Damage',
    'Roofing Damage',
    'Utility Damage (Electricity/Water)',
    'Floor Damage',
    'Plumbing/Draining Structural Issue',
    'Windows/Doors Frame Damage',
    'Staircase & Corridor Damage',
    'Ceiling & Canopy Damage',
    'HVAC / Air Conditioning Issue',
    'Fencing & Gate Damage',
    'Painting & Plastering Issue',
    'Fire or Smoke Damage',
    'Other Structural Damage'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndSetStream();
  }

  Future<void> _fetchUserDataAndSetStream() async {
    try {
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
        
        _setupIssuesStream();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  void _setupIssuesStream() {
    Query query = FirebaseFirestore.instance.collection('issues');
    
    if (_userRole == 'District Engineer') {
      query = query.orderBy('timestamp', descending: true);
    } else if (_userRole == 'Principal') {
      query = query
          .where('addedByNic', isEqualTo: widget.userNic)
          .orderBy('timestamp', descending: true);
    } else if (_userRole == 'Technical Officer') {
      query = query.orderBy('timestamp', descending: true);
    } else {
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

  // --- FILTER BOTTOM SHEET ---
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String searchQuery = '';
            
            List<String> filteredTypes = _allDamageTypes
                .where((type) =>
                    type.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Damage',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextColor),
                      ),
                      if (_selectedDamageType != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedDamageType = null);
                            Navigator.pop(context);
                          },
                          child: const Text('Clear Filter', style: TextStyle(color: Colors.redAccent)),
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    onChanged: (value) {
                      setModalState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search damage types...',
                      prefixIcon: const Icon(Icons.search, color: kSubTextColor),
                      filled: true,
                      fillColor: kBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: filteredTypes.isEmpty
                        ? const Center(
                            child: Text('No matching damage types found.',
                                style: TextStyle(color: kSubTextColor)))
                        : ListView.separated(
                            itemCount: filteredTypes.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final type = filteredTypes[index];
                              final isSelected = _selectedDamageType == type;

                              return ListTile(
                                title: Text(type,
                                    style: TextStyle(
                                      color: isSelected ? kPrimaryColor : kTextColor,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    )),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: kPrimaryColor)
                                    : null,
                                contentPadding: EdgeInsets.zero,
                                onTap: () {
                                  setState(() {
                                    _selectedDamageType = type;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
          IconButton(
            icon: Icon(
              _selectedDamageType == null ? Icons.filter_list_rounded : Icons.filter_list_off_rounded, 
              color: _selectedDamageType == null ? kPrimaryColor : kAccentColor
            ),
            tooltip: 'Filter Issues',
            onPressed: _showFilterBottomSheet,
          ),
          
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
      body: Column(
        children: [
          if (_selectedDamageType != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  const Text('Filtering: ', style: TextStyle(color: kSubTextColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: Text(_selectedDamageType!, style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        backgroundColor: kPrimaryColor.withOpacity(0.1),
                        deleteIconColor: kPrimaryColor,
                        onDeleted: () {
                          setState(() {
                            _selectedDamageType = null;
                          });
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: kPrimaryColor.withOpacity(0.2))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
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
    if (_userRole.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    if (_userRole == 'District Engineer') {
      return _buildDistrictEngineerIssues();
    }

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

        List<DocumentSnapshot> displayDocs = snapshot.data!.docs;
        if (_selectedDamageType != null) {
          displayDocs = displayDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['damageType'] == _selectedDamageType;
          }).toList();
        }

        if (displayDocs.isEmpty) {
           return _buildEmptyState(isFilterEmpty: true);
        }

        // Output the responsive layout
        return _buildResponsiveGrid(displayDocs);
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
          return _buildEmptyState();
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

            final filteredIssues = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              
              final schoolName = data['schoolName'] as String? ?? '';
              if (!schoolNames.contains(schoolName)) return false;

              if (_selectedDamageType != null && data['damageType'] != _selectedDamageType) return false;

              return true;
            }).toList();

            if (filteredIssues.isEmpty) {
              return _buildEmptyState(isFilterEmpty: true);
            }

            // Output the responsive layout
            return _buildResponsiveGrid(filteredIssues);
          },
        );
      },
    );
  }

  // --- NEW: LayoutBuilder for true responsiveness ---
  Widget _buildResponsiveGrid(List<DocumentSnapshot> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // MOBILE / SMALL SCREEN VIEW (< 650px)
        if (constraints.maxWidth < 650) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildIssueCard(docs[index]);
            },
          );
        } 
        // TABLET / DESKTOP VIEW (>= 650px)
        else {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 450, // Card won't get wider than 450
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  mainAxisExtent: 210, // Gives the card a fixed height to prevent Grid aspect ratio stretching
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  return _buildIssueCard(docs[index]);
                },
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyState({bool isFilterEmpty = false}) {
    String message = 'No issues found';
    IconData icon = Icons.check_circle_outline_rounded;
    
    if (isFilterEmpty) {
      message = 'No issues found matching "$_selectedDamageType"';
      icon = Icons.filter_alt_off_rounded;
    } else if (_userRole == 'Principal') {
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
          Text(isFilterEmpty ? 'No Matches' : 'All Clear!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kSubTextColor, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

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
            // Replaced spaceBetween with explicit SizedBox to prevent unbounded height errors in ListView
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ensures it takes only needed space on Mobile
              children: [
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
                
                const Spacer(), // Pushes the rest to the bottom dynamically
                const SizedBox(height: 12),
                
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

                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_canEditIssue(reporterNic)) ...[
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddIssueScreen(
                                userNic: widget.userNic,
                                issueId: issueId, 
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
    if (_userRole == 'Principal') {
      return reporterNic == widget.userNic;
    }
    return _userRole == 'District Engineer' || _userRole == 'Technical Officer';
  }
}