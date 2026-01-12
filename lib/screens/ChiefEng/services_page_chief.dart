import 'package:buildcare/screens/ChiefEng/dashboard.dart';
import 'package:buildcare/screens/ChiefEng/view_distric_eng_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//distric Enginner
class DistrictEngineerDashboardCardStream extends StatelessWidget {
  const DistrictEngineerDashboardCardStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: DistrictEngineerService().getDECountStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final count = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => const DistrictEngineersListPage(),
            //   ),
            // );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActiveDistrictEngineerScreen(),
              ),
            );
          },
          child: _buildOverviewCard(
            'District Engineers',
            isLoading ? '...' : count.toString(),
            const Color.fromARGB(255, 105, 166, 197),
            // const Color.fromARGB(255, 170, 153, 233),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return
        // DashboardCard(
        //   title: title,
        //   count: count,
        //   icon: Icons.school_rounded,
        //   width: 185,

        //   height: 90,

        // );
        DashboardCard(
      title: "District\nEngineers",
      count: count,
      icon: Icons.engineering,
      iconColor: Colors.blue.shade300,
      iconBackgroundColor: Colors.blue.shade50,
      width: 150,
      height: 80,
    );
    // return Container(
    //   width: 160,
    //   constraints: const BoxConstraints(
    //     maxWidth: 400,
    //   ),
    //   padding: const EdgeInsets.all(16),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     borderRadius: BorderRadius.circular(8),
    //     border: Border.all(
    //       color: Colors.grey.shade300,
    //       width: 1,
    //     ),
    //   ),
    //   child: IntrinsicHeight(
    //     child: Row(
    //       children: [
    //         Container(
    //           width: 40,
    //           height: 40,
    //           decoration: BoxDecoration(
    //             color: Colors.pink.shade50,
    //             borderRadius: BorderRadius.circular(8),
    //           ),
    //           child: Icon(
    //             Icons.school_rounded,
    //             color: Colors.pink.shade300,
    //             size: 40,
    //           ),
    //         ),
    //         const SizedBox(width: 8),
    //         Column(
    //           children: [
    //             Row(
    //               children: [
    //                 Text(
    //                   "Distric\nEnginer",
    //                   style: TextStyle(
    //                     fontSize: 15,
    //                     fontWeight: FontWeight.w900,
    //                     color: Colors.grey.shade800,
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             Text(count + " users"),
    //           ],
    //         ),
    //       ],
    //     ),
    //   ),
    // );
    // width: 90,
    // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    // decoration: BoxDecoration(
    //   color: color,
    //   borderRadius: BorderRadius.circular(15),
    //   boxShadow: [
    //     BoxShadow(
    //       color: Colors.black.withOpacity(0.1),
    //       blurRadius: 4,
    //       offset: const Offset(0, 2),
    //     ),
    //   ],
    // ),
    // child: Column(
    //   children: [
    //     Text(
    //       count,
    //       style: const TextStyle(
    //         fontSize: 24,
    //         fontWeight: FontWeight.bold,
    //         color: Colors.black,
    //       ),
    //     ),
    //     const SizedBox(height: 5),
    //     Text(
    //       title,
    //       textAlign: TextAlign.center,
    //       style: const TextStyle(
    //         fontSize: 11,
    //         color: Colors.black87,
    //       ),
    //     ),
    //   ],
    // ),
  }
}
//hhhhhhhhhh

class DistrictEngineersListPage extends StatelessWidget {
  const DistrictEngineersListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('District Engineersj'),
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DistrictEngineerService().getDistrictEngineersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading district engineers',
                    style: TextStyle(color: Colors.red[400], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB3E5FC),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.engineering_outlined,

                    // Icons.engineering_outlined,
                    size: 50,

                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No district engineers found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final engineers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: engineers.length,
            itemBuilder: (context, index) {
              final engineerData =
                  engineers[index].data() as Map<String, dynamic>;
              final engineerId = engineers[index].id;

              return DistrictEngineerCard(
                engineerData: engineerData,
                engineerId: engineerId,
              );
            },
          );
        },
      ),
    );
  }
}

class DistrictEngineerCard extends StatelessWidget {
  final Map<String, dynamic> engineerData;
  final String engineerId;

  const DistrictEngineerCard({
    Key? key,
    required this.engineerData,
    required this.engineerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = engineerData['name'] ?? 'Unknown';
    final email = engineerData['email'] ?? 'No email';
    final phone = engineerData['phone'] ?? 'No phone';
    final district = engineerData['district'] ?? 'No district';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFB3E5FC),
                child: const Icon(
                  Icons.engineering,
                  size: 30,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          district,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (email.isNotEmpty && email != 'No email')
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (phone.isNotEmpty && phone != 'No phone')
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DistrictEngineerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getTotalDECount() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'District Engineer')
          .get();
      return snapshot.size;
    } catch (e) {
      print('Error getting District Engineers count: $e');
      return 0;
    }
  }

  Stream<int> getDECountStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'District Engineer')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<QuerySnapshot> getDistrictEngineersStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'District Engineer')
        .orderBy('name')
        .snapshots();
  }

  Future<DocumentSnapshot> getDistrictEngineer(String engineerId) async {
    try {
      return await _firestore.collection('users').doc(engineerId).get();
    } catch (e) {
      print('Error getting District Engineer: $e');
      rethrow;
    }
  }
}

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('issues')
                .orderBy('timestamp', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading activities',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      color: Color(0xFF64B5F6),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activities',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  var issueData = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IssueActivityCard(
                      issueData: issueData,
                      issueId: doc.id,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

//Dashboard Card

class DashboardCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final double width;
  final double height;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
    required this.width,
    required this.height,
    this.iconColor = const Color(0xFFF48FB1),
    this.iconBackgroundColor = const Color(0xFFFCE4EC),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 28,
              height: 38,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            // Text Content with Flexible
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    count,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//schhool card

class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get total schools count (one-time)
  Future<int> getTotalSchoolsCount() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('schools').get();
      return snapshot.size;
    } catch (e) {
      print('Error getting schools count: $e');
      return 0;
    }
  }

  // Get schools count as a stream (real-time updates)
  Stream<int> getSchoolsCountStream() {
    return _firestore.collection('schools').snapshots().map(
          (snapshot) => snapshot.size,
        );
  }

  // Get all schools as a stream (real-time updates)
  Stream<QuerySnapshot> getSchoolsStream() {
    return _firestore
        .collection('schools')
        .orderBy('schoolName', descending: false)
        .snapshots();
  }

  // Get single school by ID
  Stream<DocumentSnapshot> getSchoolById(String schoolId) {
    return _firestore.collection('schools').doc(schoolId).snapshots();
  }
}

// Dashboard Card - Clickable Schools Count

class SchoolsDashboardCard extends StatefulWidget {
  const SchoolsDashboardCard({Key? key}) : super(key: key);

  @override
  State<SchoolsDashboardCard> createState() => _SchoolsDashboardCardState();
}

class _SchoolsDashboardCardState extends State<SchoolsDashboardCard> {
  final SchoolService _schoolService = SchoolService();
  int _schoolsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolsCount();
  }

  Future<void> _loadSchoolsCount() async {
    try {
      final count = await _schoolService.getTotalSchoolsCount();
      setState(() {
        _schoolsCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading schools count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SchoolsListPage(),
          ),
        );
      },
      child: _buildOverviewCard(
        'Total Schools',
        _isLoading ? '...' : _schoolsCount.toString(),
        const Color.fromARGB(255, 170, 153, 233),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return DashboardCard(
      title: title,
      count: count,
      icon: Icons.school,
      width: 150,
      height: 80,
      iconColor: Colors.white,
      iconBackgroundColor: color,
    );
  }
}

class SchoolsListPage extends StatelessWidget {
  const SchoolsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('All Schools'),
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: SchoolService().getSchoolsStream(),
        builder: (context, snapshot) {
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading schools',
                    style: TextStyle(color: Colors.red[400], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF64B5F6),
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No schools found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Display schools list
          final schools = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schools.length,
            itemBuilder: (context, index) {
              final schoolData = schools[index].data() as Map<String, dynamic>;
              final schoolId = schools[index].id;

              return SchoolCard(
                schoolData: schoolData,
                schoolId: schoolId,
              );
            },
          );
        },
      ),
    );
  }
}

class SchoolCard extends StatelessWidget {
  final Map<String, dynamic> schoolData;
  final String schoolId;

  const SchoolCard({
    Key? key,
    required this.schoolData,
    required this.schoolId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String schoolName = schoolData['schoolName'] ?? 'Unknown School';
    String address = schoolData['address'] ?? 'No Address';
    String province = schoolData['province'] ?? 'N/A';
    String district = schoolData['district'] ?? 'N/A';
    String schoolType = schoolData['schoolType'] ?? 'N/A';

    // School type colors
    Color typeColor;
    Color typeBgColor;

    switch (schoolType.toLowerCase()) {
      case 'government':
        typeColor = Colors.blue.shade700;
        typeBgColor = Colors.blue.shade50;
        break;
      case 'private':
        typeColor = Colors.purple.shade700;
        typeBgColor = Colors.purple.shade50;
        break;
      case 'international':
        typeColor = Colors.orange.shade700;
        typeBgColor = Colors.orange.shade50;
        break;
      default:
        typeColor = Colors.grey.shade700;
        typeBgColor = Colors.grey.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left side colored indicator
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
            ),
          ),
          // Main content
          ListTile(
            contentPadding: const EdgeInsets.only(
              left: 21,
              right: 16,
              top: 16,
              bottom: 16,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: typeBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: typeColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.school,
                color: typeColor,
                size: 28,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    schoolName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeBgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: typeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    schoolType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$district, $province',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF64B5F6),
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SchoolDetailsPage(
                    schoolId: schoolId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SchoolDetailsPage extends StatelessWidget {
  final String schoolId;

  const SchoolDetailsPage({
    Key? key,
    required this.schoolId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('School Details'),
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: SchoolService().getSchoolById(schoolId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF64B5F6),
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading school details',
                    style: TextStyle(color: Colors.red[400], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Not found state
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'School not found',
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

          // Get school data
          final schoolData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card with School Name
                _buildHeaderCard(schoolData),
                const SizedBox(height: 16),

                // Basic Information
                _buildDetailCard(
                  'Basic Information',
                  Icons.info_outline,
                  Colors.blue,
                  [
                    _buildDetailRow('School Name', schoolData['schoolName']),
                    _buildSchoolTypeRow(
                        'School Type', schoolData['schoolType']),
                    _buildDetailRow('School ID', schoolId),
                    _buildDetailRow('Address', schoolData['address']),
                    _buildDetailRow('Province', schoolData['province']),
                    _buildDetailRow('District', schoolData['district']),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact Information
                _buildDetailCard(
                  'Contact Information',
                  Icons.contact_phone,
                  Colors.green,
                  [
                    _buildDetailRow('Phone', schoolData['phone']),
                    _buildDetailRow('Email', schoolData['email']),
                    _buildDetailRow('Principal', schoolData['principal']),
                  ],
                ),
                const SizedBox(height: 16),

                // Statistics
                _buildDetailCard(
                  'Statistics',
                  Icons.bar_chart,
                  Colors.orange,
                  [
                    _buildStatRow(
                      Icons.school,
                      'Total Students',
                      schoolData['totalStudents']?.toString() ?? 'N/A',
                      Colors.blue,
                    ),
                    _buildStatRow(
                      Icons.person,
                      'Total Teachers',
                      schoolData['totalTeachers']?.toString() ?? 'N/A',
                      Colors.green,
                    ),
                    _buildStatRow(
                      Icons.calendar_today,
                      'Established Year',
                      schoolData['establishedYear']?.toString() ?? 'N/A',
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // All Fields Card
                _buildAllFieldsCard(schoolData),
              ],
            ),
          );
        },
      ),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school,
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
                    data['schoolName'] ?? 'School Name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['district'] ?? 'District',
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
      ),
    );
  }

  Widget _buildDetailCard(
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

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolTypeRow(String label, dynamic value) {
    String schoolType = value?.toString() ?? 'N/A';

    Color typeColor;
    Color typeBgColor;

    switch (schoolType.toLowerCase()) {
      case 'government':
        typeColor = Colors.blue.shade700;
        typeBgColor = Colors.blue.shade50;
        break;
      case 'private':
        typeColor = Colors.purple.shade700;
        typeBgColor = Colors.purple.shade50;
        break;
      case 'international':
        typeColor = Colors.orange.shade700;
        typeBgColor = Colors.orange.shade50;
        break;
      default:
        typeColor = Colors.grey.shade700;
        typeBgColor = Colors.grey.shade50;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: typeBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: typeColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Text(
              schoolType,
              style: TextStyle(
                fontSize: 14,
                color: typeColor,
                fontWeight: FontWeight.bold,
              ),
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
      DateTime date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }

    if (value is List) {
      return value.join(', ');
    }

    return value.toString();
  }

  IconData _getIconForField(String fieldName) {
    final name = fieldName.toLowerCase();

    if (name.contains('name')) return Icons.badge;
    if (name.contains('email')) return Icons.email;
    if (name.contains('phone')) return Icons.phone;
    if (name.contains('address')) return Icons.location_on;
    if (name.contains('province')) return Icons.map;
    if (name.contains('district')) return Icons.location_city;
    if (name.contains('student')) return Icons.school;
    if (name.contains('teacher')) return Icons.person;
    if (name.contains('principal')) return Icons.person_pin;
    if (name.contains('year')) return Icons.calendar_today;
    if (name.contains('established')) return Icons.event;

    return Icons.info_outline;
  }
}

//Technical officer

class TechnicalOfficerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getTotalTOCount() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'Technical Officer')
          .get();
      return snapshot.size;
    } catch (e) {
      print('Error getting Technical Officers count: $e');
      return 0;
    }
  }

  Stream<int> getTOCountStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'Technical Officer')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<QuerySnapshot> getTechnicalOfficersStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'Technical Officer')
        .orderBy('name', descending: false)
        .snapshots();
  }
}

// Clickable Dashboard Card
class TechnicalOfficerDashboardCardStream extends StatelessWidget {
  const TechnicalOfficerDashboardCardStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: TechnicalOfficerService().getTOCountStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final count = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TechnicalOfficersListPage(),
              ),
            );
          },
          child: _buildOverviewCard(
            'Technical Officers',
            isLoading ? '...' : count.toString(),
            const Color(0xFFB3E5FC),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return DashboardCard(
        title: "Tecnical Officer",
        count: count,
        icon: Icons.engineering,
        width: 150,
        height: 80);
  }
}

// Technical Officers List Page
class TechnicalOfficersListPage extends StatelessWidget {
  const TechnicalOfficersListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Technical Officers'),
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: TechnicalOfficerService().getTechnicalOfficersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading technical officers',
                    style: TextStyle(color: Colors.red[400], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF64B5F6),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.engineering_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No technical officers found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final officers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: officers.length,
            itemBuilder: (context, index) {
              final officerData =
                  officers[index].data() as Map<String, dynamic>;
              final officerId = officers[index].id;

              return TechnicalOfficerCard(
                officerData: officerData,
                officerId: officerId,
              );
            },
          );
        },
      ),
    );
  }
}

class TechnicalOfficerCard extends StatelessWidget {
  final Map<String, dynamic> officerData;
  final String officerId;

  const TechnicalOfficerCard({
    Key? key,
    required this.officerData,
    required this.officerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String name = officerData['name'] ?? 'Unknown Officer';
    String email = officerData['email'] ?? 'No Email';
    String phone = officerData['mobilePhone'] ?? 'No Phone';
    String nic = officerData['nic'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFB3E5FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.engineering,
            color: Color(0xFF64B5F6),
            size: 28,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  nic,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF64B5F6),
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TechnicalOfficerDetailsPage(
                officerData: officerData,
                officerId: officerId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class TechnicalOfficerDetailsPage extends StatelessWidget {
  final Map<String, dynamic> officerData;
  final String officerId;

  const TechnicalOfficerDetailsPage({
    Key? key,
    required this.officerData,
    required this.officerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Technical Officer Details'),
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.engineering,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    officerData['name'] ?? 'Unknown Officer',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3E5FC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Technical Officer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64B5F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Personal Information',
              [
                _buildDetailRow('Full Name', officerData['name']),
                _buildDetailRow('NIC', officerData['nic']),
                _buildDetailRow('User Type', officerData['userType']),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Contact Information',
              [
                _buildDetailRow('Email', officerData['email']),
                _buildDetailRow('Mobile Phone', officerData['mobilePhone']),
                _buildDetailRow('Landline', officerData['landlineNumber']),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Address Details',
              [
                _buildDetailRow('Address', officerData['address']),
                _buildDetailRow('Province', officerData['province']),
                _buildDetailRow('District', officerData['district']),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Professional Information',
              [
                _buildDetailRow(
                    'Registration Number', officerData['registrationNumber']),
                _buildDetailRow('Department', officerData['department']),
                _buildDetailRow('Assigned Schools',
                    officerData['assignedSchools']?.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
