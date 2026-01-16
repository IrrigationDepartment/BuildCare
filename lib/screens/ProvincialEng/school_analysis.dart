import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class SchoolAnalysisPage extends StatefulWidget {
  const SchoolAnalysisPage({super.key});

  @override
  State<SchoolAnalysisPage> createState() => _SchoolAnalysisPageState();
}

class _SchoolAnalysisPageState extends State<SchoolAnalysisPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Map<String, dynamic>> _analysisData;
  String _selectedAnalysisType = 'infrastructure';
  String? _selectedSchoolForDetails;

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
    
    // Infrastructure scores for each school
    Map<String, double> schoolInfrastructureScores = {};
    Map<String, int> schoolStudentCounts = {};
    Map<String, Map<String, dynamic>> schoolDetails = {};
    
    for (var school in schools) {
      final data = school.data();
      final schoolId = school.id;
      final district = data['district'] as String? ?? 'Unknown';
      schoolsByDistrict[district] = (schoolsByDistrict[district] ?? 0) + 1;
      
      // Store school details - explicitly convert to Map<String, dynamic>
      schoolDetails[schoolId] = {
        'name': data['schoolName'] as String? ?? data['name'] as String? ?? 'Unknown School',
        'district': district,
        'students': data['numStudents'] as int? ?? 0,
        'teachers': data['numTeachers'] as int? ?? 0,
        'nonAcademics': data['numNonAcademics'] as int? ?? 0,
        'infrastructure': data['infrastructure'] as Map<String, dynamic>? ?? {},
        'type': data['schoolType'] as String? ?? 'Other',
        'address': data['schoolAddress'] as String? ?? '',
      };
      
      // Calculate infrastructure score (0-100)
      double infrastructureScore = 0;
      final infra = data['infrastructure'] as Map<String, dynamic>?;
      if (infra != null) {
        int totalFacilities = 0;
        int availableFacilities = 0;
        
        // Check basic infrastructure - handle null values
        if (infra['electricity'] == true) availableFacilities++;
        if (infra['waterSupply'] == true) availableFacilities++;
        if (infra['sanitation'] == true) availableFacilities++;
        if (infra['communication'] == true) availableFacilities++;
        totalFacilities = 4;
        
        infrastructureScore = totalFacilities > 0 
            ? (availableFacilities / totalFacilities * 100) 
            : 0;
      }
      schoolInfrastructureScores[schoolId] = infrastructureScore;
      
      // Store student count
      schoolStudentCounts[schoolId] = data['numStudents'] as int? ?? 0;
    }
    
    // Analyze issues
    Map<String, int> issuesBySchool = {};
    Map<String, List<Map<String, dynamic>>> schoolIssuesDetails = {};
    Map<String, int> issuesByMonth = {};
    Map<String, int> issuesByYear = {};
    Map<String, int> issuesByDamageType = {};
    Map<String, int> issuesByBuilding = {};
    
    for (var issue in issues) {
      final data = issue.data();
      final schoolName = data['schoolName'] as String? ?? 'Unknown';
      final timestamp = data['timestamp'] as Timestamp?;
      final damageType = data['damageType'] as String? ?? 'Unknown';
      final buildingName = data['buildingName'] as String? ?? 'Unknown';
      
      // Count issues by school
      issuesBySchool[schoolName] = (issuesBySchool[schoolName] ?? 0) + 1;
      
      // Group by month and year
      if (timestamp != null) {
        final date = timestamp.toDate();
        final monthYear = DateFormat('MMM yyyy').format(date);
        final year = DateFormat('yyyy').format(date);
        
        issuesByMonth[monthYear] = (issuesByMonth[monthYear] ?? 0) + 1;
        issuesByYear[year] = (issuesByYear[year] ?? 0) + 1;
      }
      
      // Group by damage type
      issuesByDamageType[damageType] = (issuesByDamageType[damageType] ?? 0) + 1;
      
      // Group by building
      issuesByBuilding[buildingName] = (issuesByBuilding[buildingName] ?? 0) + 1;
      
      // Store issue details for each school - explicitly convert to Map<String, dynamic>
      if (!schoolIssuesDetails.containsKey(schoolName)) {
        schoolIssuesDetails[schoolName] = [];
      }
      schoolIssuesDetails[schoolName]!.add({
        'title': data['issueTitle'] as String? ?? 'Untitled',
        'damageType': damageType,
        'building': buildingName,
        'status': data['status'] as String? ?? 'Pending',
        'timestamp': timestamp?.toDate(),
        'description': data['description'] as String? ?? '',
      });
    }
    
    // Grade schools by infrastructure
    final schoolsByInfrastructure = _gradeSchoolsByInfrastructure(schoolInfrastructureScores);
    final schoolsByStudentCount = _gradeSchoolsByStudentCount(schoolStudentCounts);
    
    // Find schools with most issues
    final schoolsWithMostIssues = issuesBySchool.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'totalSchools': totalSchools,
      'totalIssues': issues.length,
      'schoolsByDistrict': schoolsByDistrict,
      'schoolInfrastructureScores': schoolInfrastructureScores,
      'schoolStudentCounts': schoolStudentCounts,
      'schoolsByInfrastructure': schoolsByInfrastructure,
      'schoolsByStudentCount': schoolsByStudentCount,
      'issuesBySchool': issuesBySchool,
      'issuesByMonth': issuesByMonth,
      'issuesByYear': issuesByYear,
      'issuesByDamageType': issuesByDamageType,
      'issuesByBuilding': issuesByBuilding,
      'schoolDetails': schoolDetails,
      'schoolIssuesDetails': schoolIssuesDetails,
      'schoolsWithMostIssues': schoolsWithMostIssues.take(10).toList(),
    };
  }

  Map<String, List<String>> _gradeSchoolsByInfrastructure(Map<String, double> scores) {
    final grades = <String, List<String>>{
      'A': [], // 80-100%
      'B': [], // 60-79%
      'C': [], // 40-59%
      'D': [], // 20-39%
      'F': [], // 0-19%
    };
    
    scores.forEach((schoolId, score) {
      if (score >= 80) grades['A']!.add(schoolId);
      else if (score >= 60) grades['B']!.add(schoolId);
      else if (score >= 40) grades['C']!.add(schoolId);
      else if (score >= 20) grades['D']!.add(schoolId);
      else grades['F']!.add(schoolId);
    });
    
    return grades;
  }

  Map<String, List<String>> _gradeSchoolsByStudentCount(Map<String, int> counts) {
    final grades = <String, List<String>>{
      'Large': [], // 1000+ students
      'Medium': [], // 500-999 students
      'Small': [], // 100-499 students
      'Very Small': [], // <100 students
    };
    
    counts.forEach((schoolId, count) {
      if (count >= 1000) grades['Large']!.add(schoolId);
      else if (count >= 500) grades['Medium']!.add(schoolId);
      else if (count >= 100) grades['Small']!.add(schoolId);
      else grades['Very Small']!.add(schoolId);
    });
    
    return grades;
  }

  Widget _buildAnalysisTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Analysis Type:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          DropdownButton<String>(
            value: _selectedAnalysisType,
            onChanged: (String? newValue) {
              setState(() {
                _selectedAnalysisType = newValue!;
              });
            },
            items: <String>[
              'infrastructure',
              'students',
              'issues',
              'monthly',
              'damage-types',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value.replaceAll('-', ' ').toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureAnalysis(Map<String, List<String>> grades, Map<String, Map<String, dynamic>> schoolDetails) {
    return Container(
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
            'Schools Graded by Infrastructure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...grades.entries.map((gradeEntry) {
            final grade = gradeEntry.key;
            final schools = gradeEntry.value;
            final color = _getGradeColor(grade);
            
            return ExpansionTile(
              title: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        grade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Grade $grade (${schools.length} schools)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              children: schools.map((schoolId) {
                final details = schoolDetails[schoolId];
                final schoolName = details?['name'] as String? ?? 'Unknown School';
                
                return ListTile(
                  leading: const Icon(Icons.school, size: 20),
                  title: Text(schoolName),
                  subtitle: details != null 
                      ? Text('${details['students']} students • ${details['district']}')
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSchoolForDetails = schoolId;
                    });
                  },
                );
              }).toList(),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStudentCountAnalysis(Map<String, List<String>> grades, Map<String, Map<String, dynamic>> schoolDetails) {
    return Container(
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
            'Schools by Student Count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...grades.entries.map((gradeEntry) {
            final category = gradeEntry.key;
            final schools = gradeEntry.value;
            final color = _getSizeColor(category);
            
            return ExpansionTile(
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$category (${schools.length} schools)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              children: schools.map((schoolId) {
                final details = schoolDetails[schoolId];
                final schoolName = details?['name'] as String? ?? 'Unknown School';
                final studentCount = details?['students'] as int? ?? 0;
                
                return ListTile(
                  leading: const Icon(Icons.people, size: 20),
                  title: Text(schoolName),
                  subtitle: Text('$studentCount students'),
                  trailing: Chip(
                    label: Text(category),
                    backgroundColor: color.withOpacity(0.2),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSchoolForDetails = schoolId;
                    });
                  },
                );
              }).toList(),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildIssuesAnalysis(Map<String, dynamic> data) {
    final issuesByMonth = data['issuesByMonth'] as Map<String, int>;
    final issuesByYear = data['issuesByYear'] as Map<String, int>;
    final issuesByDamageType = data['issuesByDamageType'] as Map<String, int>;
    final schoolsWithMostIssues = data['schoolsWithMostIssues'] as List<MapEntry<String, int>>;
    final schoolIssuesDetails = data['schoolIssuesDetails'] as Map<String, List<Map<String, dynamic>>>;
    
    return Column(
      children: [
        // Issues Over Time
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
                'Issues Over Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: <ColumnSeries<MapEntry<String, int>, String>>[
                    ColumnSeries<MapEntry<String, int>, String>(
                      dataSource: issuesByMonth.entries.toList(),
                      xValueMapper: (entry, _) => entry.key,
                      yValueMapper: (entry, _) => entry.value,
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Damage Types
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
                'Issues by Damage Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...issuesByDamageType.entries.map((entry) {
                final totalIssues = issuesByDamageType.values.reduce((a, b) => a + b);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(entry.key),
                      ),
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: entry.value / totalIssues,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getDamageTypeColor(entry.key),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(entry.value.toString()),
                        backgroundColor: _getDamageTypeColor(entry.key).withOpacity(0.2),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Schools with Most Issues
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
                'Schools with Most Issues',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...schoolsWithMostIssues.map((entry) {
                final schoolName = entry.key;
                final issueCount = entry.value;
                final issues = schoolIssuesDetails[schoolName] ?? [];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Text(
                        issueCount.toString(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(schoolName),
                    subtitle: Text('$issueCount issues'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showSchoolIssuesDetails(context, schoolName, issues);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  void _showSchoolIssuesDetails(BuildContext context, String schoolName, List<Map<String, dynamic>> issues) {
    // Group issues by building
    Map<String, List<Map<String, dynamic>>> issuesByBuilding = {};
    Map<String, int> issuesByMonth = {};
    Map<String, int> issuesByDamageType = {};
    
    for (var issue in issues) {
      final building = issue['building'] as String? ?? 'Unknown';
      final damageType = issue['damageType'] as String? ?? 'Unknown';
      final timestamp = issue['timestamp'] as DateTime?;
      
      // Group by building
      if (!issuesByBuilding.containsKey(building)) {
        issuesByBuilding[building] = [];
      }
      issuesByBuilding[building]!.add(issue);
      
      // Group by month
      if (timestamp != null) {
        final monthYear = DateFormat('MMM yyyy').format(timestamp);
        issuesByMonth[monthYear] = (issuesByMonth[monthYear] ?? 0) + 1;
      }
      
      // Group by damage type
      issuesByDamageType[damageType] = (issuesByDamageType[damageType] ?? 0) + 1;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Issue Details: $schoolName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Building with most issues
              if (issuesByBuilding.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buildings with Issues:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...issuesByBuilding.entries.map((entry) {
                          final building = entry.key;
                          final buildingIssues = entry.value;
                          
                          return ListTile(
                            leading: const Icon(Icons.location_city),
                            title: Text(building),
                            subtitle: Text('${buildingIssues.length} issues'),
                            trailing: Chip(
                              label: Text(
                                buildingIssues.length > 5 ? 'High' :
                                buildingIssues.length > 2 ? 'Medium' : 'Low',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: buildingIssues.length > 5 ? Colors.red :
                                              buildingIssues.length > 2 ? Colors.orange : Colors.green,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Issues by Month Chart
              if (issuesByMonth.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Issues by Month:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 150,
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            series: <ColumnSeries<MapEntry<String, int>, String>>[
                              ColumnSeries<MapEntry<String, int>, String>(
                                dataSource: issuesByMonth.entries.toList(),
                                xValueMapper: (entry, _) => entry.key,
                                yValueMapper: (entry, _) => entry.value,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Damage Types
              if (issuesByDamageType.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Damage Types:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: issuesByDamageType.entries.map((entry) {
                            return Chip(
                              label: Text('${entry.key} (${entry.value})'),
                              backgroundColor: _getDamageTypeColor(entry.key).withOpacity(0.2),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // All Issues List
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Issues:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: issues.length,
                            itemBuilder: (context, index) {
                              final issue = issues[index];
                              final timestamp = issue['timestamp'] as DateTime?;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    _getStatusIcon(issue['status'] as String? ?? 'Pending'),
                                    color: _getStatusColor(issue['status'] as String? ?? 'Pending'),
                                  ),
                                  title: Text(issue['title'] as String? ?? 'Untitled'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Building: ${issue['building']}'),
                                      Text('Damage: ${issue['damageType']}'),
                                      if (timestamp != null)
                                        Text('Date: ${DateFormat('MMM dd, yyyy').format(timestamp)}'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.lightGreen;
      case 'C': return Colors.yellow;
      case 'D': return Colors.orange;
      case 'F': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getSizeColor(String size) {
    switch (size) {
      case 'Large': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Small': return Colors.green;
      case 'Very Small': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Color _getDamageTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'roofing damage': return Colors.red;
      case 'electrical': return Colors.orange;
      case 'plumbing': return Colors.blue;
      case 'structural': return Colors.brown;
      case 'painting': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.pending;
      case 'in progress': return Icons.build;
      case 'completed': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.error;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'in progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
          final schoolDetails = data['schoolDetails'] as Map<String, Map<String, dynamic>>;
          
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
                      totalSchools > 0 
                          ? (totalIssues / totalSchools).toStringAsFixed(1)
                          : '0.0',
                      Icons.analytics,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Active Issues',
                      (data['issuesByDamageType'] as Map<String, int>).length.toString(),
                      Icons.timeline,
                      Colors.purple,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Analysis Type Selector
                _buildAnalysisTypeSelector(),
                
                const SizedBox(height: 16),
                
                // Display selected analysis
                if (_selectedAnalysisType == 'infrastructure')
                  _buildInfrastructureAnalysis(
                    data['schoolsByInfrastructure'] as Map<String, List<String>>,
                    schoolDetails,
                  )
                else if (_selectedAnalysisType == 'students')
                  _buildStudentCountAnalysis(
                    data['schoolsByStudentCount'] as Map<String, List<String>>,
                    schoolDetails,
                  )
                else if (_selectedAnalysisType == 'issues')
                  _buildIssuesAnalysis(data),
                
                const SizedBox(height: 24),
                
                // School Details if selected
                if (_selectedSchoolForDetails != null && 
                    schoolDetails.containsKey(_selectedSchoolForDetails!))
                  _buildSchoolDetailsCard(
                    _selectedSchoolForDetails!,
                    schoolDetails[_selectedSchoolForDetails!]!,
                    data,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchoolDetailsCard(String schoolId, Map<String, dynamic> details, Map<String, dynamic> allData) {
    final schoolInfrastructureScores = allData['schoolInfrastructureScores'] as Map<String, double>;
    final schoolIssuesDetails = allData['schoolIssuesDetails'] as Map<String, List<Map<String, dynamic>>>;
    final schoolName = details['name'] as String? ?? 'Unknown School';
    final issuesForSchool = schoolIssuesDetails[schoolName] ?? [];
    
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  schoolName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedSchoolForDetails = null;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // School Info
          Row(
            children: [
              _buildInfoItem('Students', details['students'].toString(), Icons.people),
              _buildInfoItem('Teachers', details['teachers'].toString(), Icons.person),
              _buildInfoItem('Staff', details['nonAcademics'].toString(), Icons.group),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Infrastructure Score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Infrastructure Score',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (schoolInfrastructureScores[schoolId] ?? 0) / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (schoolInfrastructureScores[schoolId] ?? 0) >= 80 ? Colors.green :
                      (schoolInfrastructureScores[schoolId] ?? 0) >= 60 ? Colors.yellow :
                      (schoolInfrastructureScores[schoolId] ?? 0) >= 40 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(schoolInfrastructureScores[schoolId] ?? 0).toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (schoolInfrastructureScores[schoolId] ?? 0) >= 80 ? Colors.green :
                             (schoolInfrastructureScores[schoolId] ?? 0) >= 60 ? Colors.orange : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Issues for this school
          if (issuesForSchool.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'School Issues',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...issuesForSchool.take(3).map((issue) {
                      return ListTile(
                        leading: Icon(
                          _getStatusIcon(issue['status'] as String? ?? 'Pending'),
                          color: _getStatusColor(issue['status'] as String? ?? 'Pending'),
                        ),
                        title: Text(issue['title'] as String? ?? 'Untitled'),
                        subtitle: Text('${issue['damageType']} • ${issue['building']}'),
                      );
                    }).toList(),
                    if (issuesForSchool.length > 3)
                      TextButton(
                        onPressed: () {
                          _showSchoolIssuesDetails(context, schoolName, issuesForSchool);
                        },
                        child: const Text('View all issues'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}