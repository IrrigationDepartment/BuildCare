import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final usersSnapshot = await _firestore.collection('users').get();
    
    final schools = schoolsSnapshot.docs;
    final issues = issuesSnapshot.docs;
    final users = usersSnapshot.docs;
    
    // Create user map for quick lookup
    Map<String, Map<String, dynamic>> userMap = {};
    for (var user in users) {
      userMap[user.id] = user.data();
    }
    
    // Calculate statistics
    int totalSchools = schools.length;
    int totalStudents = 0;
    int totalTeachers = 0;
    
    // Group by district
    Map<String, int> schoolsByDistrict = {};
    
    // Infrastructure scores and teacher-student ratios for each school
    Map<String, double> schoolInfrastructureScores = {};
    Map<String, double> schoolTeacherStudentRatios = {};
    Map<String, String> schoolRatioGrades = {};
    Map<String, Map<String, dynamic>> schoolDetails = {};
    
    // Analyze building conditions
    Map<String, Map<String, int>> buildingIssuesByType = {}; // buildingName -> {damageType: count}
    Map<String, List<Map<String, dynamic>>> buildingIssuesDetails = {}; // buildingName -> [issues]
    Map<String, String> buildingCondition = {}; // buildingName -> condition (Good, Warning, Danger)
    Map<String, String> buildingSchoolMap = {}; // buildingName -> schoolName
    
    for (var school in schools) {
      final data = school.data();
      final schoolId = school.id;
      final district = data['district'] as String? ?? 'Unknown';
      schoolsByDistrict[district] = (schoolsByDistrict[district] ?? 0) + 1;
      
      // Get student and teacher counts
      final students = data['numStudents'] as int? ?? 0;
      final teachers = data['numTeachers'] as int? ?? 0;
      
      totalStudents += students;
      totalTeachers += teachers;
      
      // Calculate teacher-student ratio
      double ratio = teachers > 0 ? students / teachers : double.infinity;
      schoolTeacherStudentRatios[schoolId] = ratio;
      
      // Grade based on ratio (Sri Lanka standard: 16:1 is good)
      String ratioGrade = _getRatioGrade(ratio);
      schoolRatioGrades[schoolId] = ratioGrade;
      
      // Store school details
      schoolDetails[schoolId] = {
        'name': data['schoolName'] as String? ?? data['name'] as String? ?? 'Unknown School',
        'district': district,
        'students': students,
        'teachers': teachers,
        'nonAcademics': data['numNonAcademics'] as int? ?? 0,
        'infrastructure': data['infrastructure'] as Map<String, dynamic>? ?? {},
        'type': data['schoolType'] as String? ?? 'Other',
        'address': data['schoolAddress'] as String? ?? '',
        'email': data['schoolEmail'] as String? ?? '',
        'phone': data['schoolPhone'] as String? ?? '',
        'zone': data['educationalZone'] as String? ?? '',
      };
      
      // Calculate infrastructure score (0-100)
      double infrastructureScore = 0;
      final infra = data['infrastructure'] as Map<String, dynamic>?;
      if (infra != null) {
        int totalFacilities = 0;
        int availableFacilities = 0;
        
        // Check basic infrastructure
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
    }
    
    // Analyze issues for building conditions
    Map<String, int> issuesBySchool = {};
    Map<String, List<Map<String, dynamic>>> schoolIssuesDetails = {};
    Map<String, int> issuesByYear = {};
    Map<String, int> issuesByDamageType = {};
    Map<String, List<Map<String, dynamic>>> reporterIssues = {}; // reporterId -> [issues]
    
    for (var issue in issues) {
      final data = issue.data();
      final schoolName = data['schoolName'] as String? ?? 'Unknown';
      final timestamp = data['timestamp'] as Timestamp?;
      final damageType = data['damageType'] as String? ?? 'Unknown';
      final buildingName = data['buildingName'] as String? ?? 'Unknown';
      final reporterNic = data['addedByNic'] as String? ?? 'Unknown';
      final issueId = issue.id;
      
      // Store building-school mapping
      buildingSchoolMap[buildingName] = schoolName;
      
      // Initialize building issue tracking
      if (!buildingIssuesByType.containsKey(buildingName)) {
        buildingIssuesByType[buildingName] = {};
      }
      if (!buildingIssuesDetails.containsKey(buildingName)) {
        buildingIssuesDetails[buildingName] = [];
      }
      
      // Count issues by damage type for each building
      buildingIssuesByType[buildingName]![damageType] = 
          (buildingIssuesByType[buildingName]![damageType] ?? 0) + 1;
      
      // Store detailed issue info with reporter
      buildingIssuesDetails[buildingName]!.add({
        'id': issueId,
        'title': data['issueTitle'] as String? ?? 'Untitled',
        'damageType': damageType,
        'building': buildingName,
        'school': schoolName,
        'status': data['status'] as String? ?? 'Pending',
        'timestamp': timestamp?.toDate(),
        'description': data['description'] as String? ?? '',
        'images': data['imageUrls'] as List<dynamic>? ?? [],
        'classrooms': data['numClassrooms'] as int? ?? 0,
        'floors': data['numFloors'] as int? ?? 0,
        'reporterNic': reporterNic,
        'occurrenceDate': data['dateOfOccurrence'] != null 
            ? (data['dateOfOccurrence'] as Timestamp).toDate() 
            : null,
      });
      
      // Track issues by reporter
      if (!reporterIssues.containsKey(reporterNic)) {
        reporterIssues[reporterNic] = [];
      }
      reporterIssues[reporterNic]!.add({
        'id': issueId,
        'title': data['issueTitle'] as String? ?? 'Untitled',
        'damageType': damageType,
        'building': buildingName,
        'school': schoolName,
        'status': data['status'] as String? ?? 'Pending',
        'timestamp': timestamp?.toDate(),
        'description': data['description'] as String? ?? '',
        'images': data['imageUrls'] as List<dynamic>? ?? [],
      });
      
      // Count issues by school
      issuesBySchool[schoolName] = (issuesBySchool[schoolName] ?? 0) + 1;
      
      // Group by year
      if (timestamp != null) {
        final year = DateFormat('yyyy').format(timestamp.toDate());
        issuesByYear[year] = (issuesByYear[year] ?? 0) + 1;
      }
      
      // Group by damage type
      issuesByDamageType[damageType] = (issuesByDamageType[damageType] ?? 0) + 1;
      
      // Store issue details for school
      if (!schoolIssuesDetails.containsKey(schoolName)) {
        schoolIssuesDetails[schoolName] = [];
      }
      schoolIssuesDetails[schoolName]!.add({
        'id': issueId,
        'title': data['issueTitle'] as String? ?? 'Untitled',
        'damageType': damageType,
        'building': buildingName,
        'status': data['status'] as String? ?? 'Pending',
        'timestamp': timestamp?.toDate(),
        'description': data['description'] as String? ?? '',
        'images': data['imageUrls'] as List<dynamic>? ?? [],
        'reporterNic': reporterNic,
      });
    }
    
    // Assess building conditions
    buildingIssuesByType.forEach((buildingName, damageTypes) {
      int totalIssues = damageTypes.values.fold(0, (sum, count) => sum + count);
      String condition = 'Good';
      
      // Criteria for building condition:
      // - Good: 0-2 issues
      // - Warning: 3-5 issues or multiple issues of same type
      // - Danger: 6+ issues or structural damage type
      
      if (totalIssues >= 6) {
        condition = 'Danger';
      } else if (totalIssues >= 3) {
        condition = 'Warning';
      }
      
      // Check for structural damage types
      if (damageTypes.containsKey('Structural Damage') || 
          damageTypes.containsKey('Roofing Damage') ||
          damageTypes.containsKey('Foundation Damage')) {
        if (damageTypes['Structural Damage'] != null && damageTypes['Structural Damage']! >= 2 ||
            damageTypes['Roofing Damage'] != null && damageTypes['Roofing Damage']! >= 2 ||
            damageTypes['Foundation Damage'] != null && damageTypes['Foundation Damage']! >= 2) {
          condition = 'Danger';
        } else if (condition == 'Good') {
          condition = 'Warning';
        }
      }
      
      // Check for multiple issues of same type
      damageTypes.forEach((type, count) {
        if (count >= 3) {
          condition = 'Danger';
        } else if (count >= 2 && condition == 'Good') {
          condition = 'Warning';
        }
      });
      
      buildingCondition[buildingName] = condition;
    });
    
    // Grade schools by infrastructure
    final schoolsByInfrastructure = _gradeSchoolsByInfrastructure(schoolInfrastructureScores);
    // Grade schools by teacher-student ratio
    final schoolsByRatio = _gradeSchoolsByRatio(schoolRatioGrades);
    
    // Find dangerous buildings
    final dangerousBuildings = buildingCondition.entries
        .where((entry) => entry.value == 'Danger')
        .map((entry) => {
          'building': entry.key,
          'school': buildingSchoolMap[entry.key] ?? 'Unknown',
          'condition': entry.value,
          'issues': buildingIssuesDetails[entry.key] ?? [],
          'damageTypes': buildingIssuesByType[entry.key] ?? {},
        })
        .toList();
    
    // Find warning buildings
    final warningBuildings = buildingCondition.entries
        .where((entry) => entry.value == 'Warning')
        .map((entry) => {
          'building': entry.key,
          'school': buildingSchoolMap[entry.key] ?? 'Unknown',
          'condition': entry.value,
          'issues': buildingIssuesDetails[entry.key] ?? [],
          'damageTypes': buildingIssuesByType[entry.key] ?? {},
        })
        .toList();
    
    // Find schools with most issues
    final schoolsWithMostIssues = issuesBySchool.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'totalSchools': totalSchools,
      'totalIssues': issues.length,
      'totalStudents': totalStudents,
      'totalTeachers': totalTeachers,
      'nationalRatio': totalTeachers > 0 ? totalStudents / totalTeachers : 0,
      'schoolsByDistrict': schoolsByDistrict,
      'schoolInfrastructureScores': schoolInfrastructureScores,
      'schoolTeacherStudentRatios': schoolTeacherStudentRatios,
      'schoolRatioGrades': schoolRatioGrades,
      'schoolsByInfrastructure': schoolsByInfrastructure,
      'schoolsByRatio': schoolsByRatio,
      'issuesBySchool': issuesBySchool,
      'issuesByYear': issuesByYear,
      'issuesByDamageType': issuesByDamageType,
      'schoolDetails': schoolDetails,
      'schoolIssuesDetails': schoolIssuesDetails,
      'schoolsWithMostIssues': schoolsWithMostIssues.take(10).toList(),
      'dangerousBuildings': dangerousBuildings,
      'warningBuildings': warningBuildings,
      'buildingConditions': buildingCondition,
      'userMap': userMap,
      'reporterIssues': reporterIssues,
    };
  }

  String _getRatioGrade(double ratio) {
    if (ratio <= 16) return 'A';      // 16:1 or better (matches Sri Lanka standard)
    else if (ratio <= 30) return 'B'; // 17-30:1
    else if (ratio <= 50) return 'C'; // 31-50:1
    else if (ratio <= 60) return 'D'; // 51-60:1
    else return 'E';                  // Above 60:1
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

  Map<String, List<String>> _gradeSchoolsByRatio(Map<String, String> ratioGrades) {
    final grades = <String, List<String>>{
      'A': [],
      'B': [],
      'C': [],
      'D': [],
      'E': [],
    };
    
    ratioGrades.forEach((schoolId, grade) {
      grades[grade]!.add(schoolId);
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
              'teacher-ratio',
              'building-conditions',
              'issues',
            ].map<DropdownMenuItem<String>>((String value) {
              String displayText = '';
              switch (value) {
                case 'infrastructure':
                  displayText = 'INFRASTRUCTURE';
                  break;
                case 'teacher-ratio':
                  displayText = 'TEACHER RATIO';
                  break;
                case 'building-conditions':
                  displayText = 'BUILDING SAFETY';
                  break;
                case 'issues':
                  displayText = 'ISSUES';
                  break;
              }
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  displayText,
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

  Widget _buildTeacherRatioAnalysis(Map<String, List<String>> grades, Map<String, Map<String, dynamic>> schoolDetails, double nationalRatio) {
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
            'Schools by Teacher-Student Ratio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sri Lanka National Standard:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Ideal Ratio: 16:1 (1 teacher per 16 students)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    '• Current National Average: ${nationalRatio.toStringAsFixed(1)}:1',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRatioLegend('A', '≤16:1', Colors.green),
                      _buildRatioLegend('B', '17-30:1', Colors.lightGreen),
                      _buildRatioLegend('C', '31-50:1', Colors.yellow),
                      _buildRatioLegend('D', '51-60:1', Colors.orange),
                      _buildRatioLegend('E', '>60:1', Colors.red),
                    ],
                  ),
                ],
              ),
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
                final students = details?['students'] as int? ?? 0;
                final teachers = details?['teachers'] as int? ?? 0;
                final ratio = teachers > 0 ? students / teachers : double.infinity;
                
                return ListTile(
                  leading: const Icon(Icons.people, size: 20),
                  title: Text(schoolName),
                  subtitle: Text('${students}:${teachers} (${ratio.toStringAsFixed(1)}:1 ratio)'),
                  trailing: Chip(
                    label: Text('Grade $grade'),
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

  Widget _buildBuildingConditionsAnalysis(List<dynamic> dangerousBuildings, List<dynamic> warningBuildings) {
    return Column(
      children: [
        // Dangerous Buildings
        if (dangerousBuildings.isNotEmpty) ...[
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
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Dangerous Buildings (Need Immediate Repair)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...dangerousBuildings.map((building) {
                  final buildingName = building['building'] as String;
                  final schoolName = building['school'] as String;
                  final issues = building['issues'] as List<dynamic>;
                  final damageTypes = building['damageTypes'] as Map<String, int>;
                  
                  return Card(
                    color: Colors.red.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text(buildingName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('School: $schoolName'),
                          Text('Issues: ${issues.length} reported'),
                          if (damageTypes.isNotEmpty)
                            Text(
                              'Damage Types: ${damageTypes.keys.join(', ')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: () {
                        _showBuildingDetails(context, buildingName, schoolName, issues, 'Danger');
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Warning Buildings
        if (warningBuildings.isNotEmpty) ...[
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
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Buildings Needing Attention',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...warningBuildings.map((building) {
                  final buildingName = building['building'] as String;
                  final schoolName = building['school'] as String;
                  final issues = building['issues'] as List<dynamic>;
                  final damageTypes = building['damageTypes'] as Map<String, int>;
                  
                  return Card(
                    color: Colors.orange.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber, color: Colors.orange),
                      title: Text(buildingName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('School: $schoolName'),
                          Text('Issues: ${issues.length} reported'),
                          if (damageTypes.isNotEmpty)
                            Text(
                              'Damage Types: ${damageTypes.keys.join(', ')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.orange),
                      onTap: () {
                        _showBuildingDetails(context, buildingName, schoolName, issues, 'Warning');
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
        
        if (dangerousBuildings.isEmpty && warningBuildings.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No buildings identified as dangerous or needing repair.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  void _showBuildingDetails(BuildContext context, String buildingName, String schoolName, 
                          List<dynamic> issues, String condition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildingName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'School: $schoolName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Condition Indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: condition == 'Danger' ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: condition == 'Danger' ? Colors.red : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      condition == 'Danger' ? Icons.warning : Icons.warning_amber,
                      color: condition == 'Danger' ? Colors.red : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            condition == 'Danger' 
                                ? 'DANGEROUS BUILDING - IMMEDIATE REPAIR NEEDED'
                                : 'NEEDS ATTENTION - REPAIR RECOMMENDED',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: condition == 'Danger' ? Colors.red : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            condition == 'Danger'
                                ? 'Multiple serious issues reported. Consider temporary closure.'
                                : 'Several issues reported. Schedule inspection and repairs.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Building Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBuildingStat('Total Issues', issues.length.toString(), Icons.list),
                  _buildBuildingStat('Active', 
                    issues.where((i) => (i['status'] as String? ?? '') == 'Pending').length.toString(), 
                    Icons.pending
                  ),
                  _buildBuildingStat('In Progress', 
                    issues.where((i) => (i['status'] as String? ?? '') == 'In Progress').length.toString(), 
                    Icons.build
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // All Issues List
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All Reported Issues:',
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
                                final issue = issues[index] as Map<String, dynamic>;
                                final timestamp = issue['timestamp'] as DateTime?;
                                final images = issue['images'] as List<dynamic>? ?? [];
                                final reporterNic = issue['reporterNic'] as String?;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () {
                                      _showIssueDetails(context, issue, reporterNic);
                                    },
                                    leading: Icon(
                                      _getStatusIcon(issue['status'] as String? ?? 'Pending'),
                                      color: _getStatusColor(issue['status'] as String? ?? 'Pending'),
                                    ),
                                    title: Text(issue['title'] as String? ?? 'Untitled'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Damage: ${issue['damageType']}'),
                                        if (timestamp != null)
                                          Text('Reported: ${DateFormat('MMM dd, yyyy').format(timestamp)}'),
                                        if (reporterNic != null)
                                          Text('Reported by: $reporterNic'),
                                        if (images.isNotEmpty)
                                          Text('${images.length} image(s)'),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIssueDetails(BuildContext context, Map<String, dynamic> issue, String? reporterNic) async {
    final Map<String, dynamic>? reporterData = reporterNic != null 
        ? await _getReporterData(reporterNic)
        : null;
    
    final images = issue['images'] as List<dynamic>? ?? [];
    final timestamp = issue['timestamp'] as DateTime?;
    final occurrenceDate = issue['occurrenceDate'] as DateTime?;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      issue['title'] as String? ?? 'Issue Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Issue Status
              Chip(
                label: Text(
                  issue['status'] as String? ?? 'Pending',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: _getStatusColor(issue['status'] as String? ?? 'Pending'),
              ),
              
              const SizedBox(height: 16),
              
              // Issue Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Building', issue['building'] as String? ?? 'Unknown'),
                      _buildDetailRow('School', issue['school'] as String? ?? 'Unknown'),
                      _buildDetailRow('Damage Type', issue['damageType'] as String? ?? 'Unknown'),
                      if ((issue['classrooms'] as int? ?? 0) > 0)
                        _buildDetailRow('Classrooms', ((issue['classrooms'] as int?) ?? 0).toString()),
                      if ((issue['floors'] as int? ?? 0) > 0)
                        _buildDetailRow('Floors', ((issue['floors'] as int?) ?? 0).toString()),
                      if (timestamp != null)
                        _buildDetailRow('Reported Date', DateFormat('MMM dd, yyyy HH:mm').format(timestamp)),
                      if (occurrenceDate != null)
                        _buildDetailRow('Occurrence Date', DateFormat('MMM dd, yyyy').format(occurrenceDate)),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      if ((issue['description'] as String? ?? '').isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(issue['description'] as String? ?? ''),
                          ],
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Images
                      if (images.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Images:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  final imageUrl = images[index] as String;
                                  return GestureDetector(
                                    onTap: () => _launchUrl(imageUrl),
                                    child: Container(
                                      width: 160,
                                      height: 120,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade200,
                                        image: DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Reporter Information
                      if (reporterData != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reported By:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blue.shade100,
                                      backgroundImage: reporterData['profile_image'] != null
                                          ? NetworkImage(reporterData['profile_image'] as String)
                                          : null,
                                      child: reporterData['profile_image'] == null
                                          ? const Icon(Icons.person, color: Colors.blue)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reporterData['name'] as String? ?? 'Unknown',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(reporterData['userType'] as String? ?? ''),
                                          Text('NIC: ${reporterData['nic'] as String? ?? ''}'),
                                          Text(reporterData['email'] as String? ?? ''),
                                          if (reporterData['office'] != null)
                                            Text('Office: ${reporterData['office']}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getReporterData(String nic) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('nic', isEqualTo: nic)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    } catch (e) {
      print('Error fetching reporter data: $e');
    }
    return null;
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioLegend(String grade, String ratio, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            grade,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            ratio,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesAnalysis(Map<String, dynamic> data) {
    final issuesByYear = data['issuesByYear'] as Map<String, int>;
    final schoolsWithMostIssues = data['schoolsWithMostIssues'] as List<MapEntry<String, int>>;
    final schoolIssuesDetails = data['schoolIssuesDetails'] as Map<String, List<Map<String, dynamic>>>;
    
    return Column(
      children: [
        // Issues by Year
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
                'Issues by Year',
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
                      dataSource: issuesByYear.entries.toList(),
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
                  Expanded(
                    child: Text(
                      'Issues: $schoolName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // All Issues List
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 60),
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
                                final reporterNic = issue['reporterNic'] as String?;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () {
                                      _showIssueDetails(context, issue, reporterNic);
                                    },
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
                                        if (reporterNic != null)
                                          Text('Reported by: $reporterNic'),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuildingStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
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
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showSchoolInfrastructureDetails(BuildContext context, Map<String, dynamic> details) {
    final infrastructure = details['infrastructure'] as Map<String, dynamic>? ?? {};
    
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
                  Expanded(
                    child: Text(
                      'Infrastructure: ${details['name']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // School Basic Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'School Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('District', details['district'] as String? ?? 'Unknown'),
                      _buildInfoRow('Zone', details['zone'] as String? ?? 'Unknown'),
                      _buildInfoRow('Type', details['type'] as String? ?? 'Unknown'),
                      _buildInfoRow('Address', details['address'] as String? ?? 'Not provided'),
                      _buildInfoRow('Email', details['email'] as String? ?? 'Not provided'),
                      _buildInfoRow('Phone', details['phone'] as String? ?? 'Not provided'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Student-Teacher Ratio
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student-Teacher Ratio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCircle('Students', details['students'].toString(), Icons.people, Colors.blue),
                          _buildStatCircle('Teachers', details['teachers'].toString(), Icons.person, Colors.green),
                          _buildStatCircle('Staff', details['nonAcademics'].toString(), Icons.group, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Chip(
                          label: Text(
                            '${details['students']}:${details['teachers']} Ratio',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: _getRatioColor(details['students'] as int, details['teachers'] as int),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Infrastructure Facilities
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Infrastructure Facilities',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFacilityItem('Electricity', infrastructure['electricity'] == true),
                      _buildFacilityItem('Water Supply', infrastructure['waterSupply'] == true),
                      _buildFacilityItem('Sanitation', infrastructure['sanitation'] == true),
                      _buildFacilityItem('Communication', infrastructure['communication'] == true),
                      _buildFacilityItem('Active Status', infrastructure['isActive'] == true),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityItem(String facility, bool isAvailable) {
    return ListTile(
      leading: Icon(
        isAvailable ? Icons.check_circle : Icons.cancel,
        color: isAvailable ? Colors.green : Colors.red,
      ),
      title: Text(facility),
      trailing: Chip(
        label: Text(isAvailable ? 'Available' : 'Not Available'),
        backgroundColor: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
      ),
    );
  }

  Widget _buildStatCircle(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getRatioColor(int students, int teachers) {
    if (teachers == 0) return Colors.red.shade100;
    double ratio = students / teachers;
    if (ratio <= 16) return Colors.green.shade100;
    else if (ratio <= 30) return Colors.lightGreen.shade100;
    else if (ratio <= 50) return Colors.yellow.shade100;
    else if (ratio <= 60) return Colors.orange.shade100;
    else return Colors.red.shade100;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.lightGreen;
      case 'C': return Colors.yellow;
      case 'D': return Colors.orange;
      case 'E': return Colors.red;
      case 'F': return Colors.red;
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
          final totalStudents = data['totalStudents'] as int;
          final totalTeachers = data['totalTeachers'] as int;
          final nationalRatio = data['nationalRatio'] as double;
          final dangerousBuildings = data['dangerousBuildings'] as List<dynamic>;
          final warningBuildings = data['warningBuildings'] as List<dynamic>;
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
                      'Danger Buildings',
                      dangerousBuildings.length.toString(),
                      Icons.dangerous,
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Warning Buildings',
                      warningBuildings.length.toString(),
                      Icons.warning_amber,
                      Colors.orange,
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
                else if (_selectedAnalysisType == 'teacher-ratio')
                  _buildTeacherRatioAnalysis(
                    data['schoolsByRatio'] as Map<String, List<String>>,
                    schoolDetails,
                    nationalRatio,
                  )
                else if (_selectedAnalysisType == 'building-conditions')
                  _buildBuildingConditionsAnalysis(dangerousBuildings, warningBuildings)
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
    final schoolTeacherStudentRatios = allData['schoolTeacherStudentRatios'] as Map<String, double>;
    final schoolRatioGrades = allData['schoolRatioGrades'] as Map<String, String>;
    final schoolIssuesDetails = allData['schoolIssuesDetails'] as Map<String, List<Map<String, dynamic>>>;
    final dangerousBuildings = allData['dangerousBuildings'] as List<dynamic>;
    final warningBuildings = allData['warningBuildings'] as List<dynamic>;
    
    final schoolName = details['name'] as String? ?? 'Unknown School';
    final issuesForSchool = schoolIssuesDetails[schoolName] ?? [];
    final ratio = schoolTeacherStudentRatios[schoolId] ?? 0;
    final ratioGrade = schoolRatioGrades[schoolId] ?? 'E';
    
    // Filter buildings for this school
    final schoolDangerousBuildings = dangerousBuildings
        .where((b) => (b['school'] as String) == schoolName)
        .toList();
    final schoolWarningBuildings = warningBuildings
        .where((b) => (b['school'] as String) == schoolName)
        .toList();
    
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
          
          // School Info Row
          Row(
            children: [
              _buildInfoItem('Students', details['students'].toString(), Icons.people),
              _buildInfoItem('Teachers', details['teachers'].toString(), Icons.person),
              _buildInfoItem('Ratio', '${ratio.toStringAsFixed(1)}:1', Icons.balance),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Dangerous/Warning Buildings
          if (schoolDangerousBuildings.isNotEmpty || schoolWarningBuildings.isNotEmpty)
            Column(
              children: [
                if (schoolDangerousBuildings.isNotEmpty)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dangerous Buildings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  '${schoolDangerousBuildings.length} building(s) need immediate repair',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (schoolWarningBuildings.isNotEmpty)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Buildings Needing Attention',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  '${schoolWarningBuildings.length} building(s) need inspection',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          
          // Ratio Grade
          Card(
            color: _getGradeColor(ratioGrade).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher-Student Ratio Grade',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${details['students']}:${details['teachers']} (${ratio.toStringAsFixed(1)}:1)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      'Grade $ratioGrade',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _getGradeColor(ratioGrade),
                  ),
                ],
              ),
            ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(schoolInfrastructureScores[schoolId] ?? 0).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (schoolInfrastructureScores[schoolId] ?? 0) >= 80 ? Colors.green :
                                 (schoolInfrastructureScores[schoolId] ?? 0) >= 60 ? Colors.orange : Colors.red,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.info, size: 16),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          _showSchoolInfrastructureDetails(context, details);
                        },
                      ),
                    ],
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
                      final reporterNic = issue['reporterNic'] as String?;
                      return ListTile(
                        onTap: () {
                          _showIssueDetails(context, issue, reporterNic);
                        },
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