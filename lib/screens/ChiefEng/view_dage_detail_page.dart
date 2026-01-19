import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IssuesDashboardCardStream extends StatelessWidget {
  const IssuesDashboardCardStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: IssuesService().getIssuesCountStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final count = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DamageDetailsListScreen(),
              ),
            );
          },
          child: _buildOverviewCard(
            'Issues',
            isLoading ? '...' : count.toString(),
            const Color.fromARGB(255, 255, 87, 87),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return DashboardCard(
      title: "Issues\nReported",
      count: count,
      icon: Icons.report_problem,
      iconColor: Colors.red.shade300,
      iconBackgroundColor: Colors.red.shade50,
      width: 163,
      height: 80,
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final double width;
  final double height;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 15,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$count  issues",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IssuesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get total issues count (Future)
  Future<int> getTotalIssuesCount() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('issues').get();
      return snapshot.size;
    } catch (e) {
      print('Error getting issues count: $e');
      return 0;
    }
  }

  // Get issues count as Stream (real-time updates)
  Stream<int> getIssuesCountStream() {
    return _firestore
        .collection('issues')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Get issues count by status
  Future<int> getIssuesCountByStatus(String status) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('issues')
          .where('status', isEqualTo: status)
          .get();
      return snapshot.size;
    } catch (e) {
      print('Error getting issues count by status: $e');
      return 0;
    }
  }

  // Get issues count by status as Stream
  Stream<int> getIssuesCountByStatusStream(String status) {
    return _firestore
        .collection('issues')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Get all issues as Stream
  Stream<QuerySnapshot> getIssuesStream() {
    return _firestore
        .collection('issues')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Get single issue by ID
  Future<DocumentSnapshot> getIssue(String issueId) async {
    try {
      return await _firestore.collection('issues').doc(issueId).get();
    } catch (e) {
      print('Error getting issue: $e');
      rethrow;
    }
  }

  // Get issues statistics
  Future<Map<String, int>> getIssuesStatistics() async {
    try {
      final snapshot = await _firestore.collection('issues').get();

      int pending = 0;
      int inProgress = 0;
      int resolved = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? 'Pending').toString().toLowerCase();

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'in progress':
            inProgress++;
            break;
          case 'resolved':
          case 'completed':
            resolved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return {
        'total': snapshot.size,
        'pending': pending,
        'inProgress': inProgress,
        'resolved': resolved,
        'rejected': rejected,
      };
    } catch (e) {
      print('Error getting issues statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'inProgress': 0,
        'resolved': 0,
        'rejected': 0,
      };
    }
  }
}


class DamageDetailsListScreen extends StatefulWidget {
  const DamageDetailsListScreen({Key? key}) : super(key: key);

  @override
  State<DamageDetailsListScreen> createState() =>
      _DamageDetailsListScreenState();
}

class _DamageDetailsListScreenState extends State<DamageDetailsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All'; 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filterIssues(
      List<QueryDocumentSnapshot> issues) {
    var filtered = issues;

    
    if (_selectedStatus != 'All') {
      filtered = filtered.where((issue) {
        final data = issue.data() as Map<String, dynamic>;
        final status = (data['status'] ?? 'Pending').toString().toLowerCase();
        return status == _selectedStatus.toLowerCase();
      }).toList();
    }

    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((issue) {
        final data = issue.data() as Map<String, dynamic>;
        final title = (data['issueTitle'] ?? '').toString().toLowerCase();
        final schoolName = (data['schoolName'] ?? '').toString().toLowerCase();
        final buildingName =
            (data['buildingName'] ?? '').toString().toLowerCase();
        final damageType = (data['damageType'] ?? '').toString().toLowerCase();
        final description =
            (data['description'] ?? '').toString().toLowerCase();
        final status = (data['status'] ?? '').toString().toLowerCase();

        final query = _searchQuery.toLowerCase();

        return title.contains(query) ||
            schoolName.contains(query) ||
            buildingName.contains(query) ||
            damageType.contains(query) ||
            description.contains(query) ||
            status.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        // backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Issues Report',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
               
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Search issues by title, school, damage type...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Pending'),
                      _buildFilterChip('In Progress'),
                      _buildFilterChip('Resolved'),
                      _buildFilterChip('Rejected'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('issues').snapshots(),
              builder: (context, snapshot) {
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  );
                }

                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          color: Colors.grey[400],
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No issue reports found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                
                final allIssues = snapshot.data!.docs;
                final filteredIssues = _filterIssues(allIssues);

                
                if (filteredIssues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results found for "$_searchQuery"'
                              : 'No $_selectedStatus issues found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredIssues.length,
                  itemBuilder: (context, index) {
                    final doc = filteredIssues[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return IssueCard(
                      title: data['issueTitle'] ?? 'N/A',
                      location: data['schoolName'] ?? 'N/A',
                      status: data['status'] ?? 'Pending',
                      issueId: doc.id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status) {
    final isSelected = _selectedStatus == status;
    Color chipColor;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'in progress':
        chipColor = Colors.blue;
        break;
      case 'resolved':
        chipColor = Colors.green;
        break;
      case 'rejected':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(status),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = status;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: chipColor.withOpacity(0.2),
        checkmarkColor: chipColor,
        labelStyle: TextStyle(
          color: isSelected ? chipColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? chipColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }
}

class IssueCard extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final String issueId;

  const IssueCard({
    Key? key,
    required this.title,
    required this.location,
    required this.status,
    required this.issueId,
  }) : super(key: key);

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return {
          'color': Colors.blue[100]!,
          'textColor': Colors.blue[700]!,
        };
      case 'pending':
        return {
          'color': Colors.yellow[100]!,
          'textColor': Colors.orange[800]!,
        };
      case 'resolved':
      case 'completed':
        return {
          'color': Colors.green[100]!,
          'textColor': Colors.green[700]!,
        };
      case 'rejected':
        return {
          'color': Colors.red[100]!,
          'textColor': Colors.red[700]!,
        };
      default:
        return {
          'color': Colors.grey[100]!,
          'textColor': Colors.grey[700]!,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _getStatusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusStyle['color'],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusStyle['textColor'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DamageDetailsPage(
                          issueId: issueId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye, size: 16),
                  label: const Text(
                    'View',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Edit functionality
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DamageDetailsPage extends StatefulWidget {
  final String? issueId;

  const DamageDetailsPage({
    Key? key,
    this.issueId,
  }) : super(key: key);

  @override
  State<DamageDetailsPage> createState() => _DamageDetailsPageState();
}

class _DamageDetailsPageState extends State<DamageDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Issue Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: DamageDetailCard(issueId: widget.issueId),
    );
  }
}

class DamageDetailCard extends StatelessWidget {
  final String? issueId;

  const DamageDetailCard({
    super.key,
    this.issueId,
  });

  @override
  Widget build(BuildContext context) {
    if (issueId == null || issueId!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No issue ID provided',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF64B5F6),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading issue details',
                  style: TextStyle(color: Colors.red[400], fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.report_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Issue not found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(data),
              const SizedBox(height: 16),
              if (imageUrls.isNotEmpty) _buildImagesSection(context, imageUrls),
              if (imageUrls.isNotEmpty) const SizedBox(height: 16),
              _buildSectionCard(
                'Basic Information',
                Icons.info_outline,
                Colors.blue,
                [
                  _buildInfoRow('Issue Title', data['issueTitle']),
                  _buildInfoRow('School Name', data['schoolName']),
                  _buildInfoRow('School Type', data['schoolType']),
                  _buildInfoRow('Building Name', data['buildingName']),
                  _buildInfoRow('Damage Type', data['damageType']),
                  _buildInfoRow('Description', data['description']),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                'Building Details',
                Icons.apartment,
                Colors.orange,
                [
                  _buildStatRow(
                    Icons.square_foot,
                    'Building Area',
                    data['buildingArea']?.toString() ?? 'N/A',
                    Colors.orange,
                  ),
                  _buildStatRow(
                    Icons.layers,
                    'Number of Floors',
                    data['numFloors']?.toString() ?? 'N/A',
                    Colors.purple,
                  ),
                  _buildStatRow(
                    Icons.meeting_room,
                    'Number of Classrooms',
                    data['numClassrooms']?.toString() ?? 'N/A',
                    Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                'Status & Timeline',
                Icons.timeline,
                Colors.green,
                [
                  _buildStatusRow('Status', data['status'] ?? 'Pending'),
                  _buildInfoRow(
                    'Date of Occurrence',
                    _formatTimestamp(data['dateOfOccurance']),
                  ),
                  _buildInfoRow('Added By NIC', data['addedByNic']),
                  if (data['addedAt'] != null)
                    _buildInfoRow(
                      'Added At',
                      _formatTimestamp(data['addedAt']),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAllFieldsCard(data),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.report_problem,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['issueTitle'] ?? 'Issue Report',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['schoolName'] ?? 'Unknown School',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context, List<dynamic> imageUrls) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Damage Images (${imageUrls.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Image.network(imageUrls[index]),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, size: 40),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'in progress':
        statusColor = Colors.blue;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'resolved':
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFieldsCard(Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dataset,
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'All Document Fields',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...data.entries.map((entry) {
              return _buildDynamicField(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicField(String key, dynamic value) {
    String displayValue = _formatValue(value);
    IconData icon = _getIconForField(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              _formatFieldName(key),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFieldName(String fieldName) {
    String result = fieldName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';

    if (value is bool) {
      return value ? 'Yes' : 'No';
    }

    if (value is Timestamp) {
      return _formatTimestamp(value);
    }

    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }

    if (value is List) {
      if (value.isEmpty) return 'None';
      if (value.first.toString().startsWith('http')) {
        return '${value.length} image(s)';
      }
      return value.join(', ');
    }

    return value.toString();
  }

  IconData _getIconForField(String fieldName) {
    final name = fieldName.toLowerCase();

    if (name.contains('title') || name.contains('name')) return Icons.title;
    if (name.contains('school')) return Icons.school;
    if (name.contains('building')) return Icons.apartment;
    if (name.contains('area')) return Icons.square_foot;
    if (name.contains('damage')) return Icons.warning;
    if (name.contains('floor')) return Icons.layers;
    if (name.contains('classroom')) return Icons.meeting_room;
    if (name.contains('date') || name.contains('time'))
      return Icons.access_time;
    if (name.contains('description')) return Icons.description;
    if (name.contains('status')) return Icons.flag;
    if (name.contains('nic')) return Icons.badge;
    if (name.contains('image')) return Icons.photo;

    return Icons.info_outline;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'N/A';
      }

      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
