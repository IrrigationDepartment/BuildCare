import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ============================================================================
// 1. ALL SCHOOLS PAGE (LIST & FILTER)
// ============================================================================
class AllSchoolsPage extends StatefulWidget {
  const AllSchoolsPage({super.key});

  @override
  State<AllSchoolsPage> createState() => _AllSchoolsPageState();
}

class _AllSchoolsPageState extends State<AllSchoolsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedDistrict = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('School Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('schools').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allSchools = snapshot.data?.docs ?? [];

          // Dynamically extract unique districts from the data for the filter
          final Set<String> uniqueDistricts = {'All'};
          for (var doc in allSchools) {
            final data = doc.data() as Map<String, dynamic>;
            // Fallback to educationalZone if district isn't explicitly set, or use 'Unknown'
            final district = data['district'] as String? ?? data['educationalZone'] as String? ?? 'Unknown';
            uniqueDistricts.add(district);
          }

          // Filter the list based on selected district
          final filteredSchools = allSchools.where((doc) {
            if (_selectedDistrict == 'All') return true;
            final data = doc.data() as Map<String, dynamic>;
            final district = data['district'] as String? ?? data['educationalZone'] as String? ?? 'Unknown';
            return district == _selectedDistrict;
          }).toList();

          return Column(
            children: [
              // Filter Section
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    const Text('Filter by District:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: uniqueDistricts.contains(_selectedDistrict) ? _selectedDistrict : 'All',
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.deepPurple),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDistrict = newValue!;
                            });
                          },
                          items: uniqueDistricts.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Results List
              Expanded(
                child: filteredSchools.isEmpty
                    ? const Center(child: Text('No schools found for this district.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSchools.length,
                        itemBuilder: (context, index) {
                          final doc = filteredSchools[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final schoolId = doc.id;
                          
                          return _buildSchoolCard(context, schoolId, data);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSchoolCard(BuildContext context, String schoolId, Map<String, dynamic> data) {
    final schoolName = data['schoolName'] as String? ?? 'Unknown School';
    final district = data['district'] as String? ?? data['educationalZone'] as String? ?? 'Unknown';
    final schoolType = data['schoolType'] as String? ?? 'Unknown Type';
    final numStudents = data['numStudents'] as int? ?? 0;
    final isActive = data['isActive'] as bool? ?? false;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SchoolDetailPage(schoolId: schoolId, schoolData: data),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isActive ? Colors.green.shade50 : Colors.grey.shade200,
                child: Icon(Icons.school, color: isActive ? Colors.green : Colors.grey, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(district, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('$numStudents', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(schoolType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.blue.shade50,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. SCHOOL DETAIL PAGE (MASTER PLANS, INFRASTRUCTURE, STATS)
// ============================================================================
class SchoolDetailPage extends StatelessWidget {
  final String schoolId;
  final Map<String, dynamic> schoolData;

  const SchoolDetailPage({super.key, required this.schoolId, required this.schoolData});

  @override
  Widget build(BuildContext context) {
    final schoolName = schoolData['schoolName'] as String? ?? 'Unknown School';
    final isActive = schoolData['isActive'] as bool? ?? false;
    final lastEditedAt = schoolData['lastEditedAt'] as Timestamp?;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('School Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schoolName,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    schoolData['schoolType'] as String? ?? 'Unknown Type',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                  ),
                  if (lastEditedAt != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy').format(lastEditedAt.toDate())}',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ]
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      _buildStatCard('Students', (schoolData['numStudents'] as int? ?? 0).toString(), Icons.people, Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard('Teachers', (schoolData['numTeachers'] as int? ?? 0).toString(), Icons.person, Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard('Staff', (schoolData['numNonAcademic'] as int? ?? 0).toString(), Icons.group_work, Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Contact & Location Card
                  _buildSectionHeader('Contact & Location'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.location_city, 'Zone', schoolData['educationalZone'] as String? ?? 'N/A'),
                          const Divider(height: 24),
                          _buildDetailRow(Icons.map, 'Address', schoolData['schoolAddress'] as String? ?? 'N/A'),
                          const Divider(height: 24),
                          _buildDetailRow(Icons.email, 'Email', schoolData['schoolEmail'] as String? ?? 'N/A'),
                          const Divider(height: 24),
                          _buildDetailRow(Icons.phone, 'Phone', schoolData['schoolPhone'] as String? ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Infrastructure Card
                  _buildSectionHeader('Infrastructure Available'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfraRow('Electricity', Icons.electrical_services, _getInfraStatus('electricity')),
                          const Divider(height: 16),
                          _buildInfraRow('Water Supply', Icons.water_drop, _getInfraStatus('waterSupply')),
                          const Divider(height: 16),
                          _buildInfraRow('Sanitation', Icons.wash, _getInfraStatus('sanitation')),
                          const Divider(height: 16),
                          _buildInfraRow('Communication', Icons.router, _getInfraStatus('communication')),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Master Plans Section (Requested Feature)
                  _buildSectionHeader('Master Plans & Development'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current active development and master plans for this school.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          
                          // Placeholder for actual Master Plan data
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.shade100),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                                  child: const Icon(Icons.architecture, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Primary Building Renovation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                                      Text('Phase 1: Foundation & Roofing', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.indigo),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to full Master Plans list or PDF viewer
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Master Plan Documents...')));
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('View All Master Plan Documents'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepPurple,
                                side: const BorderSide(color: Colors.deepPurple),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

  bool _getInfraStatus(String key) {
    final infraMap = schoolData['infrastructure'] as Map<String, dynamic>? ?? {};
    return infraMap[key] == true;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1C1E),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 16),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildInfraRow(String label, IconData icon, bool isAvailable) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isAvailable ? Colors.green : Colors.red, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        if (isAvailable)
          const Chip(label: Text('Available', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, side: BorderSide(color: Colors.green))
        else
          const Chip(label: Text('Missing', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, side: BorderSide(color: Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
