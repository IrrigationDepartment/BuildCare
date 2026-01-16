import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SchoolAnalysisPage extends StatefulWidget {
  const SchoolAnalysisPage({super.key});

  @override
  State<SchoolAnalysisPage> createState() => _SchoolAnalysisPageState();
}

class _SchoolAnalysisPageState extends State<SchoolAnalysisPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Map<String, dynamic>> _analysisData;

  @override
  void initState() {
    super.initState();
    _analysisData = _fetchAnalysisData();
  }

  Future<Map<String, dynamic>> _fetchAnalysisData() async {
    final schoolsSnapshot = await _firestore.collection('schools').get();
    final issuesSnapshot = await _firestore.collection('issues').get();

    final schools = schoolsSnapshot.docs;
    final issues = issuesSnapshot.docs;

    // Calculate statistics
    int totalSchools = schools.length;

    // Group by district
    Map<String, int> schoolsByDistrict = {};
    Map<String, int> issuesByDistrict = {};

    for (var school in schools) {
      final data = school.data() as Map<String, dynamic>;
      final district = data['district'] ?? 'Unknown';
      schoolsByDistrict[district] = (schoolsByDistrict[district] ?? 0) + 1;
    }

    for (var issue in issues) {
      final data = issue.data() as Map<String, dynamic>;
      final district = data['district'] ?? 'Unknown';
      issuesByDistrict[district] = (issuesByDistrict[district] ?? 0) + 1;
    }

    // Find top 5 districts with most schools
    var sortedDistricts = schoolsByDistrict.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topDistricts = sortedDistricts.take(5).toList();

    // Calculate issues per school ratio
    double avgIssuesPerSchool =
        totalSchools > 0 ? issues.length / totalSchools : 0.0;

    // Get school types distribution
    Map<String, int> schoolTypes = {};
    for (var school in schools) {
      final data = school.data() as Map<String, dynamic>;
      final type = data['schoolType'] ?? data['type'] ?? 'Other';
      schoolTypes[type] = (schoolTypes[type] ?? 0) + 1;
    }

    return {
      'totalSchools': totalSchools,
      'totalIssues': issues.length,
      'avgIssuesPerSchool': avgIssuesPerSchool,
      'topDistricts': topDistricts,
      'schoolsByDistrict': schoolsByDistrict,
      'issuesByDistrict': issuesByDistrict,
      'schoolTypes': schoolTypes,
    };
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Analysis'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analysisData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final totalSchools = data['totalSchools'] as int;
          final totalIssues = data['totalIssues'] as int;
          final avgIssuesPerSchool = data['avgIssuesPerSchool'] as double;
          final topDistricts =
              data['topDistricts'] as List<MapEntry<String, int>>;
          final schoolTypes = data['schoolTypes'] as Map<String, int>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  children: [
                    _buildStatCard(
                      'Total Schools',
                      totalSchools.toString(),
                      Icons.school,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total Issues',
                      totalIssues.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Avg Issues/School',
                      avgIssuesPerSchool.toStringAsFixed(1),
                      Icons.analytics,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'School Types',
                      schoolTypes.length.toString(),
                      Icons.category,
                      Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Top Districts Chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Districts by Schools',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Showing top 5 districts with most schools',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: SfCartesianChart(
                          primaryXAxis: CategoryAxis(),
                          series: <ColumnSeries<MapEntry<String, int>, String>>[
                            ColumnSeries<MapEntry<String, int>, String>(
                              dataSource: topDistricts,
                              xValueMapper: (entry, _) => entry.key,
                              yValueMapper: (entry, _) => entry.value,
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // School Types Distribution
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'School Types Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...schoolTypes.entries.map((entry) {
                        final percentage = totalSchools > 0
                            ? (entry.value / totalSchools * 100)
                                .toStringAsFixed(1)
                            : '0.0';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: LinearProgressIndicator(
                                  value: totalSchools > 0
                                      ? entry.value / totalSchools
                                      : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getColorForType(entry.key),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$percentage% (${entry.value})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Schools List
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Schools',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('schools')
                            .orderBy('addedAt', descending: true)
                            .limit(10)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final schools = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: schools.length,
                            itemBuilder: (context, index) {
                              final school = schools[index];
                              final data =
                                  school.data() as Map<String, dynamic>;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    child:
                                        Icon(Icons.school, color: Colors.white),
                                  ),
                                  title: Text(
                                    data['schoolName'] ??
                                        data['name'] ??
                                        'Unknown School',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(data['district'] ?? 'No District'),
                                      if (data['address'] != null)
                                        Text(
                                          data['address'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(
                                    data['schoolType'] ??
                                        data['type'] ??
                                        'Other',
                                    style: TextStyle(
                                      color: _getColorForType(
                                          data['schoolType'] ?? 'Other'),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'government':
        return Colors.blue;
      case 'private':
        return Colors.green;
      case 'international':
        return Colors.orange;
      case 'religious':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
