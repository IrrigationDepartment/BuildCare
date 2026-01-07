import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_school_page.dart';
import '../../models/school.dart';

// --- Updated Modern School Details Dialog ---
class SchoolDetailsDialog extends StatelessWidget {
  final School school;
  const SchoolDetailsDialog({Key? key, required this.school}) : super(key: key);

  // Helper method to get district from school data
  String _getSchoolDistrict(Map<String, dynamic> data) {
    return data['office'] as String? ?? 
           data['district'] as String? ?? 
           data['schoolDistrict'] as String? ?? 
           'N/A';
  }

  @override
  Widget build(BuildContext context) {
    // Get the raw data from school
    final schoolData = school.toJson();
    final district = _getSchoolDistrict(schoolData);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'School Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildDetailItem('School Name', school.name, Icons.school_outlined),
              _buildDetailItem('Address', school.address, Icons.location_on_outlined),
              _buildDetailItem('Phone', school.phoneNumber, Icons.phone_outlined),
              _buildDetailItem('Type', school.type, Icons.category_outlined),
              _buildDetailItem('Zone', school.zone, Icons.map_outlined),
              _buildDetailItem('District', district, Icons.location_city_outlined),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ),
              
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildStatBadge('Students: ${school.students}', Colors.blue),
                  _buildStatBadge('Teachers: ${school.teachers}', Colors.orange),
                ],
              ),
              
              const Divider(height: 30),
              const Text('Admin Information', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              _buildDetailItem('Status', school.isActive ? 'Active' : 'Deactivated', Icons.info_outline, 
                  valueColor: school.isActive ? Colors.green : Colors.red),
              _buildDetailItem('Added By', school.addedByNic ?? 'N/A', Icons.person_outline),
              _buildDetailItem('Last Edited', school.formattedLastEditedAt, Icons.history),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class ManageSchoolsPage extends StatefulWidget {
  final String? district;
  final String userNic;
  const ManageSchoolsPage({Key? key, this.district, required this.userNic}) : super(key: key);

  @override
  State<ManageSchoolsPage> createState() => _ManageSchoolsPageState();
}

class _ManageSchoolsPageState extends State<ManageSchoolsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Helper method to normalize district name for comparison
  String _normalizeDistrict(String district) {
    return district.trim().toLowerCase();
  }

  // Helper method to get district from school document data
  String? _getSchoolDistrictFromData(Map<String, dynamic> data) {
    return data['office'] as String? ?? 
           data['district'] as String? ?? 
           data['schoolDistrict'] as String?;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _showSchoolDetails(BuildContext context, School school) {
    showDialog(
      context: context,
      builder: (BuildContext context) => SchoolDetailsDialog(school: school),
    );
  }

  void _navigateToEditPage(BuildContext context, School school) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSchoolPage(school: school, userNic: widget.userNic),
      ),
    );
  }

  Future<void> _updateSchoolStatus(School school, bool newStatus) async {
    try {
      final String currentUserNic = widget.userNic;
      await FirebaseFirestore.instance.collection('schools').doc(school.id).update({
        'isActive': newStatus,
        'lastEditedAt': Timestamp.now(),
        'lastEditedByNic': currentUserNic,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${school.name} ${newStatus ? "activated" : "deactivated"}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newStatus ? Colors.green : Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Helper method to get district display text for a school
  String _getDistrictDisplayText(Map<String, dynamic> data) {
    final district = _getSchoolDistrictFromData(data);
    return district ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(
          widget.district != null ? 'Schools in ${widget.district}' : 'Manage Schools',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // District Info Header (only show if district is provided)
          if (widget.district != null && widget.district!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16, bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.blue.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'District: ${widget.district}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildSearchBar(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('schools').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          widget.district != null 
                            ? 'No schools found in ${widget.district}'
                            : 'No schools found.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                debugPrint('Total schools in database: ${docs.length}');
                
                // Filter by district if provided - using same logic as first code
                List<DocumentSnapshot> filteredDocs = docs;
                
                if (widget.district != null && widget.district!.isNotEmpty) {
                  final normalizedDistrict = _normalizeDistrict(widget.district!);
                  debugPrint('Filtering schools for district (normalized): $normalizedDistrict');
                  
                  filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final schoolDistrict = _getSchoolDistrictFromData(data);
                    
                    if (schoolDistrict == null) {
                      debugPrint('School ${doc.id} has no district field');
                      return false;
                    }
                    
                    final normalizedSchoolDistrict = _normalizeDistrict(schoolDistrict);
                    debugPrint('School ${doc.id}: $normalizedSchoolDistrict vs Filter: $normalizedDistrict');
                    
                    return normalizedSchoolDistrict == normalizedDistrict;
                  }).toList();
                  
                  debugPrint('Found ${filteredDocs.length} schools for district ${widget.district}');
                }

                // Apply search filter
                final List<School> filteredSchools = filteredDocs.map((doc) {
                  return School.fromFirestore(doc);
                }).where((school) {
                  if (_searchQuery.isEmpty) return true;
                  
                  return school.name.toLowerCase().contains(_searchQuery) || 
                         school.address.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredSchools.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          widget.district != null
                            ? 'No schools found in ${widget.district} matching "$_searchQuery"'
                            : 'No schools match your search criteria.',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredSchools.length,
                  itemBuilder: (context, index) {
                    final school = filteredSchools[index];
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final district = _getDistrictDisplayText(data);
                    
                    return _buildSchoolCard(school, district);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or address...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E88E5)),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () => _searchController.clear(),
              ) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSchoolCard(School school, String district) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showSchoolDetails(context, school),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      school.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: school.isActive 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      school.isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        color: school.isActive ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                school.address,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // School info row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(Icons.location_city_outlined, district),
                  ),
                  Expanded(
                    child: _buildInfoItem(Icons.people_outline, '${school.students} students'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(Icons.phone_outlined, school.phoneNumber),
                  ),
                  Expanded(
                    child: _buildInfoItem(Icons.category_outlined, school.type),
                  ),
                ],
              ),
              const Divider(height: 20),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // View Details Button
                  ElevatedButton.icon(
                    onPressed: () => _showSchoolDetails(context, school),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  // Toggle Status Button
                  TextButton.icon(
                    onPressed: () => _updateSchoolStatus(school, !school.isActive),
                    icon: Icon(
                      school.isActive ? Icons.block : Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: Text(school.isActive ? 'Deactivate' : 'Activate'),
                    style: TextButton.styleFrom(
                      foregroundColor: school.isActive ? Colors.red : Colors.green,
                      backgroundColor: (school.isActive ? Colors.red : Colors.green).withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  // Edit Button
                  IconButton(
                    onPressed: () => _navigateToEditPage(context, school),
                    icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                    tooltip: 'Edit School',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}