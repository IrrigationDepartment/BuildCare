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

  @override
  void initState() {
    super.initState();
    _analysisData = _fetchAnalysisData();
  }

  // ---------------------------------------------------------
  // 1. DATA FETCHING & PROCESSING
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> _fetchAnalysisData() async {
    final schoolsSnapshot = await _firestore.collection('schools').get();
    final issuesSnapshot = await _firestore.collection('issues').get();
    final usersSnapshot = await _firestore.collection('users').get();

    final schools = schoolsSnapshot.docs;
    final issues = issuesSnapshot.docs;
    final users = usersSnapshot.docs;

    Map<String, Map<String, dynamic>> userMap = {};
    for (var user in users) {
      userMap[user.id] = user.data();
    }

    int totalSchools = schools.length;
    int totalStudents = 0;
    int totalTeachers = 0;

    Map<String, int> schoolsByDistrict = {};
    Map<String, double> schoolInfrastructureScores = {};
    Map<String, double> schoolTeacherStudentRatios = {};
    Map<String, String> schoolRatioGrades = {};
    Map<String, Map<String, dynamic>> schoolDetails = {};

    Map<String, Map<String, int>> buildingIssuesByType = {};
    Map<String, List<Map<String, dynamic>>> buildingIssuesDetails = {};
    Map<String, String> buildingCondition = {};
    Map<String, String> buildingSchoolMap = {};

    for (var school in schools) {
      final data = school.data();
      final schoolId = school.id;
      final district = data['district'] as String? ?? 'Unknown';
      schoolsByDistrict[district] = (schoolsByDistrict[district] ?? 0) + 1;

      final students = data['numStudents'] as int? ?? 0;
      final teachers = data['numTeachers'] as int? ?? 0;

      totalStudents += students;
      totalTeachers += teachers;

      double ratio = teachers > 0 ? students / teachers : double.infinity;
      schoolTeacherStudentRatios[schoolId] = ratio;

      String ratioGrade = _getRatioGrade(ratio);
      schoolRatioGrades[schoolId] = ratioGrade;

      schoolDetails[schoolId] = {
        'name': data['schoolName'] as String? ??
            data['name'] as String? ??
            'Unknown School',
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

      double infrastructureScore = 0;
      final infra = data['infrastructure'] as Map<String, dynamic>?;
      if (infra != null) {
        int totalFacilities = 0;
        int availableFacilities = 0;

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

    Map<String, int> issuesBySchool = {};
    Map<String, List<Map<String, dynamic>>> schoolIssuesDetails = {};
    Map<String, int> issuesByYear = {};
    Map<String, int> issuesByDamageType = {};
    Map<String, List<Map<String, dynamic>>> reporterIssues = {};

    for (var issue in issues) {
      final data = issue.data();
      final schoolName = data['schoolName'] as String? ?? 'Unknown';
      final timestamp = data['timestamp'] as Timestamp?;
      final damageType = data['damageType'] as String? ?? 'Unknown';
      final buildingName = data['buildingName'] as String? ?? 'Unknown';
      final reporterNic = data['addedByNic'] as String? ?? 'Unknown';
      final issueId = issue.id;

      buildingSchoolMap[buildingName] = schoolName;

      if (!buildingIssuesByType.containsKey(buildingName)) {
        buildingIssuesByType[buildingName] = {};
      }
      if (!buildingIssuesDetails.containsKey(buildingName)) {
        buildingIssuesDetails[buildingName] = [];
      }

      buildingIssuesByType[buildingName]![damageType] =
          (buildingIssuesByType[buildingName]![damageType] ?? 0) + 1;

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

      issuesBySchool[schoolName] = (issuesBySchool[schoolName] ?? 0) + 1;

      if (timestamp != null) {
        final year = DateFormat('yyyy').format(timestamp.toDate());
        issuesByYear[year] = (issuesByYear[year] ?? 0) + 1;
      }

      issuesByDamageType[damageType] =
          (issuesByDamageType[damageType] ?? 0) + 1;

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

    buildingIssuesByType.forEach((buildingName, damageTypes) {
      int totalIssues = damageTypes.values.fold(0, (sum, count) => sum + count);
      String condition = 'Good';

      if (totalIssues >= 6) {
        condition = 'Danger';
      } else if (totalIssues >= 3) {
        condition = 'Warning';
      }

      if (damageTypes.containsKey('Structural Damage') ||
          damageTypes.containsKey('Roofing Damage') ||
          damageTypes.containsKey('Foundation Damage')) {
        if (damageTypes['Structural Damage'] != null &&
                damageTypes['Structural Damage']! >= 2 ||
            damageTypes['Roofing Damage'] != null &&
                damageTypes['Roofing Damage']! >= 2 ||
            damageTypes['Foundation Damage'] != null &&
                damageTypes['Foundation Damage']! >= 2) {
          condition = 'Danger';
        } else if (condition == 'Good') {
          condition = 'Warning';
        }
      }

      damageTypes.forEach((type, count) {
        if (count >= 3) {
          condition = 'Danger';
        } else if (count >= 2 && condition == 'Good') {
          condition = 'Warning';
        }
      });

      buildingCondition[buildingName] = condition;
    });

    final schoolsByInfrastructure =
        _gradeSchoolsByInfrastructure(schoolInfrastructureScores);
    final schoolsByRatio = _gradeSchoolsByRatio(schoolRatioGrades);

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
    if (ratio <= 16)
      return 'A';
    else if (ratio <= 30)
      return 'B';
    else if (ratio <= 50)
      return 'C';
    else if (ratio <= 60)
      return 'D';
    else
      return 'E';
  }

  Map<String, List<String>> _gradeSchoolsByInfrastructure(
      Map<String, double> scores) {
    final grades = <String, List<String>>{
      'A': [],
      'B': [],
      'C': [],
      'D': [],
      'F': [],
    };

    scores.forEach((schoolId, score) {
      if (score >= 80)
        grades['A']!.add(schoolId);
      else if (score >= 60)
        grades['B']!.add(schoolId);
      else if (score >= 40)
        grades['C']!.add(schoolId);
      else if (score >= 20)
        grades['D']!.add(schoolId);
      else
        grades['F']!.add(schoolId);
    });

    return grades;
  }

  Map<String, List<String>> _gradeSchoolsByRatio(
      Map<String, String> ratioGrades) {
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

  // ---------------------------------------------------------
  // 2. MODERN UI WIDGETS (RESPONSIVE)
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('School Analysis & Health',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              setState(() {
                _analysisData = _fetchAnalysisData();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analysisData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text("Crunching the numbers...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final totalSchools = data['totalSchools'] as int;
          final totalIssues = data['totalIssues'] as int;
          final dangerousBuildings =
              data['dangerousBuildings'] as List<dynamic>;
          final warningBuildings = data['warningBuildings'] as List<dynamic>;
          final schoolDetails =
              data['schoolDetails'] as Map<String, Map<String, dynamic>>;
          final nationalRatio = data['nationalRatio'] as double;

          return Center(
            child: ConstrainedBox(
              // Constrain the maximum width for desktop/web
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(builder: (context, constraints) {
                // Adaptive Grid Layout logic
                int crossAxisCount;
                double childAspectRatio;

                if (constraints.maxWidth >= 1024) {
                  crossAxisCount = 4;
                  childAspectRatio = 1.8;
                } else if (constraints.maxWidth >= 768) {
                  crossAxisCount = 4;
                  childAspectRatio = 1.3;
                } else if (constraints.maxWidth >= 480) {
                  crossAxisCount = 2;
                  childAspectRatio = 1.6;
                } else {
                  crossAxisCount = 1; // Narrow phones
                  childAspectRatio = 3.0;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Quick Guide Banner ---
                      _buildUserGuideCard(),

                      const SizedBox(height: 24),

                      // --- Statistics Cards Grid ---
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        children: [
                          _buildModernStatCard(
                              'Total Schools',
                              totalSchools.toString(),
                              Icons.school,
                              Colors.blue),
                          _buildModernStatCard(
                              'Total Issues',
                              totalIssues.toString(),
                              Icons.bug_report,
                              Colors.orange),
                          _buildModernStatCard(
                              'Danger Buildings',
                              dangerousBuildings.length.toString(),
                              Icons.dangerous,
                              Colors.red),
                          _buildModernStatCard(
                              'Warning Buildings',
                              warningBuildings.length.toString(),
                              Icons.warning_amber,
                              Colors.amber),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // --- Category Tabs ---
                      _buildModernCategoryTabs(),

                      const SizedBox(height: 20),

                      // --- Display selected analysis ---
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildSelectedAnalysisView(
                            data,
                            schoolDetails,
                            nationalRatio,
                            dangerousBuildings,
                            warningBuildings),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to use this Dashboard',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  '1. Check the quick stats below to see overall health.\n'
                  '2. Scroll the tabs (Infrastructure, Safety, etc.) to switch reports.\n'
                  '3. Tap on any listed school or building to open a detailed full report.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCategoryTabs() {
    final categories = [
      {
        'id': 'infrastructure',
        'title': 'Infrastructure',
        'icon': Icons.apartment
      },
      {
        'id': 'teacher-ratio',
        'title': 'Teacher Ratio',
        'icon': Icons.people_alt
      },
      {
        'id': 'building-conditions',
        'title': 'Building Safety',
        'icon': Icons.health_and_safety
      },
      {'id': 'issues', 'title': 'Issues Report', 'icon': Icons.pie_chart},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedAnalysisType == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAnalysisType = cat['id'] as String;
                });
              },
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color:
                        isSelected ? Colors.deepPurple : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData,
                        size: 18,
                        color:
                            isSelected ? Colors.white : Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      cat['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedAnalysisView(
      Map<String, dynamic> data,
      Map<String, Map<String, dynamic>> schoolDetails,
      double nationalRatio,
      List<dynamic> dangerousBuildings,
      List<dynamic> warningBuildings) {
    switch (_selectedAnalysisType) {
      case 'teacher-ratio':
        return _buildTeacherRatioAnalysis(
            data['schoolsByRatio'], schoolDetails, nationalRatio, data);
      case 'building-conditions':
        return _buildBuildingConditionsAnalysis(
            dangerousBuildings, warningBuildings);
      case 'issues':
        return _buildIssuesAnalysis(data);
      case 'infrastructure':
      default:
        return _buildInfrastructureAnalysis(
            data['schoolsByInfrastructure'], schoolDetails, data);
    }
  }

  Widget _buildModernStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 3. POPUP MODALS (WEB RESPONSIVE)
  // ---------------------------------------------------------

  // Custom wrapper to ensure bottom sheets don't stretch fully on web
  void _showResponsiveBottomSheet(
      {required BuildContext context, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      // Constraints limit width on desktop/web views
      constraints: const BoxConstraints(maxWidth: 800),
      builder: (context) => child,
    );
  }

  void _showSchoolPopup(BuildContext context, String schoolId,
      Map<String, dynamic> details, Map<String, dynamic> allData) {
    _showResponsiveBottomSheet(
      context: context,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: SafeArea(
                  top: false,
                  child: _buildSchoolDetailsCard(schoolId, details, allData),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 4. ANALYSIS VIEWS
  // ---------------------------------------------------------
  Widget _buildInfrastructureAnalysis(
      Map<String, List<String>> grades,
      Map<String, Map<String, dynamic>> schoolDetails,
      Map<String, dynamic> allData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Infrastructure Grading',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              'Grades are based on available facilities (Water, Electricity, Sanitation, Comm). Tap a grade to expand.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          ...grades.entries.map((gradeEntry) {
            final grade = gradeEntry.key;
            final schools = gradeEntry.value;
            final color = _getGradeColor(grade);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.3), width: 1.5)),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      CircleAvatar(
                          backgroundColor: color,
                          radius: 16,
                          child: Text(grade,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text('${schools.length} Schools',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                    ],
                  ),
                  children: schools.map((schoolId) {
                    final details = schoolDetails[schoolId];
                    final schoolName =
                        details?['name'] as String? ?? 'Unknown School';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 4),
                      leading: Icon(Icons.school_rounded,
                          color: color.withOpacity(0.8), size: 22),
                      title: Text(schoolName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle:
                          Text('${details?['district'] ?? 'Unknown'} District'),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.deepPurple),
                      ),
                      onTap: () => _showSchoolPopup(
                          context, schoolId, details ?? {}, allData),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeacherRatioAnalysis(
      Map<String, List<String>> grades,
      Map<String, Map<String, dynamic>> schoolDetails,
      double nationalRatio,
      Map<String, dynamic> allData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Teacher-Student Ratios',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('National Standard',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRatioStat('Ideal Ratio', '16:1', Colors.green),
                    Container(
                        height: 30, width: 1, color: Colors.blue.shade200),
                    _buildRatioStat(
                        'National Avg',
                        '${nationalRatio.toStringAsFixed(1)}:1',
                        Colors.blueGrey),
                  ],
                ),
                const Divider(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRatioLegend('A', '≤16:1', Colors.green),
                      const SizedBox(width: 12),
                      _buildRatioLegend('B', '17-30', Colors.lightGreen),
                      const SizedBox(width: 12),
                      _buildRatioLegend('C', '31-50', Colors.yellow.shade700),
                      const SizedBox(width: 12),
                      _buildRatioLegend('D', '51-60', Colors.orange),
                      const SizedBox(width: 12),
                      _buildRatioLegend('E', '>60:1', Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...grades.entries.map((gradeEntry) {
            final grade = gradeEntry.key;
            final schools = gradeEntry.value;
            final color = _getGradeColor(grade);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.3), width: 1.5)),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      CircleAvatar(
                          backgroundColor: color,
                          radius: 16,
                          child: Text(grade,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text('${schools.length} Schools',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                    ],
                  ),
                  children: schools.map((schoolId) {
                    final details = schoolDetails[schoolId];
                    final schoolName =
                        details?['name'] as String? ?? 'Unknown School';
                    final students = details?['students'] as int? ?? 0;
                    final teachers = details?['teachers'] as int? ?? 0;
                    final ratio =
                        teachers > 0 ? students / teachers : double.infinity;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 4),
                      leading:
                          Icon(Icons.groups, color: color.withOpacity(0.8)),
                      title: Text(schoolName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('$students Students • $teachers Teachers'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${ratio.toStringAsFixed(1)}:1',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  fontSize: 16)),
                          const Text('Ratio',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      onTap: () => _showSchoolPopup(
                          context, schoolId, details ?? {}, allData),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRatioStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildBuildingConditionsAnalysis(
      List<dynamic> dangerousBuildings, List<dynamic> warningBuildings) {
    return Column(
      children: [
        if (dangerousBuildings.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.red.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.dangerous, color: Colors.red)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('High Risk Buildings',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          Text('Tap building for detailed issue reports',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...dangerousBuildings.map((building) {
                  final buildingName = building['building'] as String;
                  final schoolName = building['school'] as String;
                  final issues = building['issues'] as List<dynamic>;

                  return Card(
                    color: Colors.red.shade50,
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(buildingName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                            '$schoolName\n${issues.length} severe issues logged',
                            style: TextStyle(
                                color: Colors.red.shade900, height: 1.4)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_ios,
                            color: Colors.red, size: 16),
                      ),
                      onTap: () => _showBuildingDetails(
                          context, buildingName, schoolName, issues, 'Danger'),
                    ),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (warningBuildings.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber,
                            color: Colors.orange)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Needs Attention',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                          Text('Tap building for detailed issue reports',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...warningBuildings.map((building) {
                  final buildingName = building['building'] as String;
                  final schoolName = building['school'] as String;
                  final issues = building['issues'] as List<dynamic>;

                  return Card(
                    color: Colors.orange.shade50,
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.orange.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(buildingName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                            '$schoolName\n${issues.length} issues logged',
                            style: TextStyle(
                                color: Colors.orange.shade900, height: 1.4)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_ios,
                            color: Colors.orange, size: 16),
                      ),
                      onTap: () => _showBuildingDetails(
                          context, buildingName, schoolName, issues, 'Warning'),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildIssuesAnalysis(Map<String, dynamic> data) {
    final issuesByYear = data['issuesByYear'] as Map<String, int>;
    final schoolsWithMostIssues =
        data['schoolsWithMostIssues'] as List<MapEntry<String, int>>;
    final schoolIssuesDetails =
        data['schoolIssuesDetails'] as Map<String, List<Map<String, dynamic>>>;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Issues Logged by Year',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(
                      majorGridLines: MajorGridLines(width: 0)),
                  primaryYAxis: NumericAxis(
                      majorGridLines: MajorGridLines(
                          color: Colors.grey.shade200,
                          dashArray: const [5, 5])),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <ColumnSeries<MapEntry<String, int>, String>>[
                    ColumnSeries<MapEntry<String, int>, String>(
                      dataSource: issuesByYear.entries.toList(),
                      xValueMapper: (entry, _) => entry.key,
                      yValueMapper: (entry, _) => entry.value,
                      color: Colors.deepPurpleAccent,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                      dataLabelSettings:
                          const DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Most Affected Schools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Tap a school to view all logged issues',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              ...schoolsWithMostIssues.map((entry) {
                final schoolName = entry.key;
                final issueCount = entry.value;
                final issues = schoolIssuesDetails[schoolName] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text(issueCount.toString(),
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18))),
                    ),
                    title: Text(schoolName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text('Active Issues')),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.deepPurple),
                    ),
                    onTap: () =>
                        _showSchoolIssuesDetails(context, schoolName, issues),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 5. INNER POPUP DETAILS & HELPERS
  // ---------------------------------------------------------
  Widget _buildSchoolDetailsCard(String schoolId, Map<String, dynamic> details,
      Map<String, dynamic> allData) {
    final schoolInfrastructureScores =
        allData['schoolInfrastructureScores'] as Map<String, double>;
    final schoolTeacherStudentRatios =
        allData['schoolTeacherStudentRatios'] as Map<String, double>;
    final schoolRatioGrades =
        allData['schoolRatioGrades'] as Map<String, String>;
    final schoolIssuesDetails = allData['schoolIssuesDetails']
        as Map<String, List<Map<String, dynamic>>>;
    final dangerousBuildings = allData['dangerousBuildings'] as List<dynamic>;
    final warningBuildings = allData['warningBuildings'] as List<dynamic>;

    final schoolName = details['name'] as String? ?? 'Unknown School';
    final issuesForSchool = schoolIssuesDetails[schoolName] ?? [];
    final ratio = schoolTeacherStudentRatios[schoolId] ?? 0;
    final ratioGrade = schoolRatioGrades[schoolId] ?? 'E';

    final schoolDangerousBuildings = dangerousBuildings
        .where((b) => (b['school'] as String) == schoolName)
        .toList();
    final schoolWarningBuildings = warningBuildings
        .where((b) => (b['school'] as String) == schoolName)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(schoolName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildInfoItem(
                'Students', details['students'].toString(), Icons.people),
            _buildInfoItem(
                'Teachers', details['teachers'].toString(), Icons.person),
            _buildInfoItem(
                'Ratio', '${ratio.toStringAsFixed(1)}:1', Icons.balance),
          ],
        ),
        const SizedBox(height: 20),
        if (schoolDangerousBuildings.isNotEmpty ||
            schoolWarningBuildings.isNotEmpty)
          Column(
            children: [
              if (schoolDangerousBuildings.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dangerous Buildings',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                            Text(
                                '${schoolDangerousBuildings.length} building(s) need immediate repair',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (schoolWarningBuildings.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Buildings Needing Attention',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange)),
                            Text(
                                '${schoolWarningBuildings.length} building(s) need inspection',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Card(
          elevation: 0,
          color: _getGradeColor(ratioGrade).withOpacity(0.1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Teacher-Student Ratio Grade',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          '${details['students']}:${details['teachers']} (${ratio.toStringAsFixed(1)}:1)',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                ),
                Chip(
                    label: Text('Grade $ratioGrade',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: _getGradeColor(ratioGrade)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Infrastructure Score',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (schoolInfrastructureScores[schoolId] ?? 0) / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (schoolInfrastructureScores[schoolId] ?? 0) >= 80
                          ? Colors.green
                          : (schoolInfrastructureScores[schoolId] ?? 0) >= 60
                              ? Colors.yellow
                              : (schoolInfrastructureScores[schoolId] ?? 0) >=
                                      40
                                  ? Colors.orange
                                  : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(schoolInfrastructureScores[schoolId] ?? 0).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: (schoolInfrastructureScores[schoolId] ?? 0) >= 80
                            ? Colors.green
                            : (schoolInfrastructureScores[schoolId] ?? 0) >= 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Facilities'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () =>
                          _showSchoolInfrastructureDetails(context, details),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (issuesForSchool.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Recent Issues',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...issuesForSchool.take(3).map((issue) {
            final reporterNic = issue['reporterNic'] as String?;
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => _showIssueDetails(context, issue, reporterNic),
                leading: CircleAvatar(
                    backgroundColor:
                        _getStatusColor(issue['status'] as String? ?? 'Pending')
                            .withOpacity(0.2),
                    child: Icon(
                        _getStatusIcon(issue['status'] as String? ?? 'Pending'),
                        color: _getStatusColor(
                            issue['status'] as String? ?? 'Pending'))),
                title: Text(issue['title'] as String? ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${issue['damageType']} • ${issue['building']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            );
          }),
          if (issuesForSchool.length > 3)
            Center(
              child: TextButton(
                onPressed: () => _showSchoolIssuesDetails(
                    context, schoolName, issuesForSchool),
                child: const Text('View all issues'),
              ),
            ),
        ],
      ],
    );
  }

  void _showBuildingDetails(BuildContext context, String buildingName,
      String schoolName, List<dynamic> issues, String condition) {
    _showResponsiveBottomSheet(
      context: context,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10)))),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(buildingName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('School: $schoolName',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: condition == 'Danger'
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: condition == 'Danger'
                                    ? Colors.red
                                    : Colors.orange,
                                width: 1)),
                        child: Row(
                          children: [
                            Icon(
                                condition == 'Danger'
                                    ? Icons.warning
                                    : Icons.warning_amber,
                                color: condition == 'Danger'
                                    ? Colors.red
                                    : Colors.orange,
                                size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      condition == 'Danger'
                                          ? 'DANGEROUS BUILDING'
                                          : 'NEEDS ATTENTION',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: condition == 'Danger'
                                              ? Colors.red
                                              : Colors.orange)),
                                  const SizedBox(height: 4),
                                  Text(
                                      condition == 'Danger'
                                          ? 'Multiple serious issues reported.'
                                          : 'Several issues reported.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Wrapped stats so they don't overflow on small screens
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.spaceAround,
                        children: [
                          _buildBuildingStat('Total Issues',
                              issues.length.toString(), Icons.list),
                          _buildBuildingStat(
                              'Active',
                              issues
                                  .where((i) =>
                                      (i['status'] as String? ?? '') ==
                                      'Pending')
                                  .length
                                  .toString(),
                              Icons.pending),
                          _buildBuildingStat(
                              'In Progress',
                              issues
                                  .where((i) =>
                                      (i['status'] as String? ?? '') ==
                                      'In Progress')
                                  .length
                                  .toString(),
                              Icons.build),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('All Reported Issues:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              ...issues.map((issueDynamic) {
                                final issue =
                                    issueDynamic as Map<String, dynamic>;
                                final timestamp =
                                    issue['timestamp'] as DateTime?;
                                final reporterNic =
                                    issue['reporterNic'] as String?;
                                return Card(
                                  elevation: 0,
                                  color: Colors.grey.shade50,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                          color: Colors.grey.shade200)),
                                  child: ListTile(
                                    onTap: () => _showIssueDetails(
                                        context, issue, reporterNic),
                                    leading: Icon(
                                        _getStatusIcon(
                                            issue['status'] as String? ??
                                                'Pending'),
                                        color: _getStatusColor(
                                            issue['status'] as String? ??
                                                'Pending')),
                                    title: Text(issue['title'] as String? ??
                                        'Untitled'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Damage: ${issue['damageType']}'),
                                        if (timestamp != null)
                                          Text(
                                              'Reported: ${DateFormat('MMM dd, yyyy').format(timestamp)}'),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSchoolIssuesDetails(BuildContext context, String schoolName,
      List<Map<String, dynamic>> issues) {
    _showResponsiveBottomSheet(
      context: context,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10)))),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text('Issues: $schoolName',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SafeArea(
                  top: false,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('All Issues:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          ...issues.map((issueDynamic) {
                            final issue = issueDynamic;
                            final timestamp = issue['timestamp'] as DateTime?;
                            final reporterNic = issue['reporterNic'] as String?;
                            return Card(
                              elevation: 0,
                              color: Colors.grey.shade50,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side:
                                      BorderSide(color: Colors.grey.shade200)),
                              child: ListTile(
                                onTap: () => _showIssueDetails(
                                    context, issue, reporterNic),
                                leading: Icon(
                                    _getStatusIcon(issue['status'] as String? ??
                                        'Pending'),
                                    color: _getStatusColor(
                                        issue['status'] as String? ??
                                            'Pending')),
                                title: Text(
                                    issue['title'] as String? ?? 'Untitled'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Building: ${issue['building']}'),
                                    Text('Damage: ${issue['damageType']}'),
                                    if (timestamp != null)
                                      Text(
                                          'Date: ${DateFormat('MMM dd, yyyy').format(timestamp)}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSchoolInfrastructureDetails(
      BuildContext context, Map<String, dynamic> details) {
    final infrastructure =
        details['infrastructure'] as Map<String, dynamic>? ?? {};

    _showResponsiveBottomSheet(
      context: context,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10)))),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text('Infrastructure: ${details['name']}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('School Information',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 16),
                              _buildInfoRow('District',
                                  details['district'] as String? ?? 'Unknown'),
                              _buildInfoRow('Zone',
                                  details['zone'] as String? ?? 'Unknown'),
                              _buildInfoRow('Type',
                                  details['type'] as String? ?? 'Unknown'),
                              _buildInfoRow(
                                  'Address',
                                  details['address'] as String? ??
                                      'Not provided'),
                              _buildInfoRow(
                                  'Email',
                                  details['email'] as String? ??
                                      'Not provided'),
                              _buildInfoRow(
                                  'Phone',
                                  details['phone'] as String? ??
                                      'Not provided'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Infrastructure Facilities',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 12),
                              _buildFacilityItem('Electricity',
                                  infrastructure['electricity'] == true),
                              _buildFacilityItem('Water Supply',
                                  infrastructure['waterSupply'] == true),
                              _buildFacilityItem('Sanitation',
                                  infrastructure['sanitation'] == true),
                              _buildFacilityItem('Communication',
                                  infrastructure['communication'] == true),
                              _buildFacilityItem('Active Status',
                                  infrastructure['isActive'] == true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueDetails(BuildContext context, Map<String, dynamic> issue,
      String? reporterNic) async {
    final Map<String, dynamic>? reporterData =
        reporterNic != null ? await _getReporterData(reporterNic) : null;
    final images = issue['images'] as List<dynamic>? ?? [];
    final timestamp = issue['timestamp'] as DateTime?;
    final occurrenceDate = issue['occurrenceDate'] as DateTime?;

    _showResponsiveBottomSheet(
      context: context,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10)))),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(issue['title'] as String? ?? 'Issue Details',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                label: Text(issue['status'] as String? ?? 'Pending',
                    style: const TextStyle(color: Colors.white)),
                backgroundColor:
                    _getStatusColor(issue['status'] as String? ?? 'Pending'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow('Building',
                                  issue['building'] as String? ?? 'Unknown'),
                              _buildDetailRow('School',
                                  issue['school'] as String? ?? 'Unknown'),
                              _buildDetailRow('Damage Type',
                                  issue['damageType'] as String? ?? 'Unknown'),
                              if ((issue['classrooms'] as int? ?? 0) > 0)
                                _buildDetailRow(
                                    'Classrooms',
                                    ((issue['classrooms'] as int?) ?? 0)
                                        .toString()),
                              if ((issue['floors'] as int? ?? 0) > 0)
                                _buildDetailRow(
                                    'Floors',
                                    ((issue['floors'] as int?) ?? 0)
                                        .toString()),
                              if (timestamp != null)
                                _buildDetailRow(
                                    'Reported Date',
                                    DateFormat('MMM dd, yyyy HH:mm')
                                        .format(timestamp)),
                              if (occurrenceDate != null)
                                _buildDetailRow(
                                    'Occurrence Date',
                                    DateFormat('MMM dd, yyyy')
                                        .format(occurrenceDate)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if ((issue['description'] as String? ?? '').isNotEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Description:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(issue['description'] as String? ?? ''),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (images.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Images:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
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
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      if (reporterData != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reported By:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blue.shade100,
                                      backgroundImage:
                                          reporterData['profile_image'] != null
                                              ? NetworkImage(
                                                  reporterData['profile_image']
                                                      as String)
                                              : null,
                                      child:
                                          reporterData['profile_image'] == null
                                              ? const Icon(Icons.person,
                                                  color: Colors.blue)
                                              : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              reporterData['name'] as String? ??
                                                  'Unknown',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(reporterData['userType']
                                                  as String? ??
                                              ''),
                                          Text(
                                              'NIC: ${reporterData['nic'] as String? ?? ''}'),
                                          Text(reporterData['email']
                                                  as String? ??
                                              ''),
                                          if (reporterData['office'] != null)
                                            Text(
                                                'Office: ${reporterData['office']}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getReporterData(String nic) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('nic', isEqualTo: nic)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return query.docs.first.data();
    } catch (e) {
      debugPrint('Error fetching reporter data: $e');
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text('$label:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text('$label:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildFacilityItem(String facility, bool isAvailable) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isAvailable ? Icons.check_circle : Icons.cancel,
          color: isAvailable ? Colors.green : Colors.red),
      title: Text(facility),
      trailing: Chip(
          label: Text(isAvailable ? 'Available' : 'Not Available',
              style: TextStyle(
                  color: isAvailable
                      ? Colors.green.shade800
                      : Colors.red.shade800)),
          backgroundColor:
              isAvailable ? Colors.green.shade100 : Colors.red.shade100),
    );
  }

  Widget _buildRatioLegend(String grade, String ratio, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(grade,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(ratio, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
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
                borderRadius: BorderRadius.circular(25)),
            child: Icon(icon, color: Colors.blue, size: 24)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'E':
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.error;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
