import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class MasterPlansDashboardCardStream extends StatelessWidget {
  const MasterPlansDashboardCardStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: MasterPlansService().getMasterPlansCountStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final count = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SchoolMasterPlanScreen(),
              ),
            );
          },
          child: _buildOverviewCard(
            'Master Plans',
            isLoading ? '...' : count.toString(),
            const Color.fromARGB(255, 126, 87, 194),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return DashboardCard(
      title: "Master\nPlans",
      count: count,
      icon: Icons.architecture,
      iconColor: Colors.purple.shade300,
      iconBackgroundColor: Colors.purple.shade50,
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
              size: 24,
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
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "${count}  plans",
                  style: const TextStyle(
                    fontSize: 10,

                    fontWeight: FontWeight.w500,
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



class ViewMasterPlanScreen extends StatelessWidget {
  final String pdfUrl;
  final String schoolName;
  final String description;

  const ViewMasterPlanScreen({
    Key? key,
    required this.pdfUrl,
    required this.schoolName,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'School Master Plan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'View Master Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schoolName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 28,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: pdfUrl.isNotEmpty
                    ? InteractiveViewer(
                        panEnabled: true,
                        scaleEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.network(
                            pdfUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Master Plan Image',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        description,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 80,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'The Master Plan URL is unavailable.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class MasterPlansService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get total master plans count (Future)
  Future<int> getTotalMasterPlansCount() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('schoolMasterPlans').get();
      return snapshot.size;
    } catch (e) {
      print('Error getting master plans count: $e');
      return 0;
    }
  }

  // Get master plans count as Stream (real-time updates)
  Stream<int> getMasterPlansCountStream() {
    return _firestore
        .collection('schoolMasterPlans')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Get master plans count by school name
  Future<int> getMasterPlansCountBySchool(String schoolName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('schoolMasterPlans')
          .where('schoolName', isEqualTo: schoolName)
          .get();
      return snapshot.size;
    } catch (e) {
      print('Error getting master plans count by school: $e');
      return 0;
    }
  }

  // Get master plans count by school as Stream
  Stream<int> getMasterPlansCountBySchoolStream(String schoolName) {
    return _firestore
        .collection('schoolMasterPlans')
        .where('schoolName', isEqualTo: schoolName)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Get all master plans as Stream
  Stream<QuerySnapshot> getMasterPlansStream() {
    return _firestore
        .collection('schoolMasterPlans')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get single master plan by ID
  Future<DocumentSnapshot> getMasterPlan(String planId) async {
    try {
      return await _firestore.collection('schoolMasterPlans').doc(planId).get();
    } catch (e) {
      print('Error getting master plan: $e');
      rethrow;
    }
  }

  // Get master plans statistics by date range
  Future<Map<String, int>> getMasterPlansStatistics() async {
    try {
      final snapshot = await _firestore.collection('schoolMasterPlans').get();

      int thisMonth = 0;
      int thisYear = 0;
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'];

        if (createdAt != null && createdAt is Timestamp) {
          final date = createdAt.toDate();

          if (date.year == now.year && date.month == now.month) {
            thisMonth++;
          }

          if (date.year == now.year) {
            thisYear++;
          }
        }
      }

      return {
        'total': snapshot.size,
        'thisMonth': thisMonth,
        'thisYear': thisYear,
      };
    } catch (e) {
      print('Error getting master plans statistics: $e');
      return {
        'total': 0,
        'thisMonth': 0,
        'thisYear': 0,
      };
    }
  }

  // Search master plans by school name or description
  Stream<QuerySnapshot> searchMasterPlans(String searchQuery) {
    return _firestore
        .collection('schoolMasterPlans')
        .where('schoolName', isGreaterThanOrEqualTo: searchQuery)
        .where('schoolName', isLessThan: searchQuery + 'z')
        .snapshots();
  }

  // Get master plans by date range
  Future<List<DocumentSnapshot>> getMasterPlansByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('schoolMasterPlans')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs;
    } catch (e) {
      print('Error getting master plans by date range: $e');
      return [];
    }
  }
}



class DashboardExampleWithMasterPlans extends StatelessWidget {
  const DashboardExampleWithMasterPlans({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Master Plans Count Card
            const MasterPlansDashboardCardStream(),

            const SizedBox(height: 16),

            // Statistics Cards (optional)
            FutureBuilder<Map<String, int>>(
              future: MasterPlansService().getMasterPlansStatistics(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data!;

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'This Month',
                        stats['thisMonth'].toString(),
                        Colors.blue,
                        Icons.calendar_month,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'This Year',
                        stats['thisYear'].toString(),
                        Colors.green,
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Recent Master Plans List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: MasterPlansService().getMasterPlansStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No master plans found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade50,
                          child: Icon(
                            Icons.architecture,
                            color: Colors.purple.shade300,
                          ),
                        ),
                        title: Text(data['schoolName'] ?? 'N/A'),
                        subtitle: Text(data['description'] ?? 'No description'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to details
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}



class SchoolMasterPlanScreen extends StatefulWidget {
  const SchoolMasterPlanScreen({Key? key}) : super(key: key);

  @override
  State<SchoolMasterPlanScreen> createState() => _SchoolMasterPlanScreenState();
}

class _SchoolMasterPlanScreenState extends State<SchoolMasterPlanScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'School Master Plan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Master Plan........',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schoolMasterPlans')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 60, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Data retrieval error',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
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
                        Icon(Icons.folder_open,
                            size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'There are no Master Plans.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var masterPlans = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var schoolName =
                      (data['schoolName'] ?? '').toString().toLowerCase();
                  var description =
                      (data['description'] ?? '').toString().toLowerCase();

                  if (searchQuery.isEmpty) return true;

                  return schoolName.contains(searchQuery) ||
                      description.contains(searchQuery);
                }).toList();

                if (masterPlans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No results matching the search.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: masterPlans.length,
                  itemBuilder: (context, index) {
                    var doc = masterPlans[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: MasterPlanCard(
                        documentId: doc.id,
                        schoolName: data['schoolName'] ?? 'N/A',
                        description: data['description'] ?? 'No description',
                        masterPlanUrl: data['masterPlanUrl'] ?? '',
                        createdAt: data['createdAt'],
                      ),
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
}

// Master Plan Card (from your existing code)
class MasterPlanCard extends StatelessWidget {
  final String documentId;
  final String schoolName;
  final String description;
  final String masterPlanUrl;
  final dynamic createdAt;

  const MasterPlanCard({
    Key? key,
    required this.documentId,
    required this.schoolName,
    required this.description,
    required this.masterPlanUrl,
    required this.createdAt,
  }) : super(key: key);

  String _formatDate(dynamic timestamp) {
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

      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getFileExtension(String url) {
    if (url.isEmpty) return 'PDF';
    if (url.contains('.pdf')) return 'PDF';
    if (url.contains('.doc')) return 'DOC';
    if (url.contains('.xls')) return 'XLS';
    return 'PDF';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            schoolName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Uploaded Date: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                _formatDate(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'For a ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getFileExtension(masterPlanUrl),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
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
                    if (masterPlanUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewMasterPlanScreen(
                            pdfUrl: masterPlanUrl,
                            schoolName: schoolName,
                            description: description,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('The Master Plan URL is unavailable.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.remove_red_eye, size: 16),
                  label: const Text('View', style: TextStyle(fontSize: 14)),
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
                    // Download functionality
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download', style: TextStyle(fontSize: 14)),
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