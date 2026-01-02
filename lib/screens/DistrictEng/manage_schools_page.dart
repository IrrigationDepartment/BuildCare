import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'edit_school_page.dart';
import '../../models/school.dart';

// --- Updated Modern School Details Dialog ---
class SchoolDetailsDialog extends StatelessWidget {
  final School school;
  const SchoolDetailsDialog({Key? key, required this.school}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
  final String userNic;
  const ManageSchoolsPage({Key? key, required this.userNic}) : super(key: key);

  @override
  State<ManageSchoolsPage> createState() => _ManageSchoolsPageState();
}

class _ManageSchoolsPageState extends State<ManageSchoolsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft background color
      appBar: AppBar(
        title: const Text('Manage Schools', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  return const Center(child: Text('No schools found.'));
                }

                final List<School> filteredSchools = snapshot.data!.docs
                    .map((doc) => School.fromFirestore(doc))
                    .where((s) => s.name.toLowerCase().contains(_searchQuery) || s.address.toLowerCase().contains(_searchQuery))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredSchools.length,
                  itemBuilder: (context, index) => _buildSchoolCard(filteredSchools[index]),
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
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSchoolCard(School school) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status Vertical Bar
              Container(width: 5, color: school.isActive ? Colors.green : Colors.red),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(school.name, 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                          ),
                          _buildStatusChip(school.isActive),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(school.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 12),
                      
                      // Card Details Grid
                      _buildMiniDetail(Icons.person_outline, 'By: ${school.addedByNic ?? 'N/A'}'),
                      _buildMiniDetail(Icons.calendar_today_outlined, 'On: ${school.formattedAddedAt}'),
                      if (school.lastEditedAt != null)
                        _buildMiniDetail(Icons.edit_outlined, 'Edit: ${school.formattedLastEditedAt}'),
                      
                      const Divider(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Action Buttons Group
                          Row(
                            children: [
                              _buildCircularAction(Icons.remove_red_eye, Colors.blue, () => _showSchoolDetails(context, school)),
                              const SizedBox(width: 8),
                              _buildCircularAction(Icons.edit, Colors.orange, () => _navigateToEditPage(context, school)),
                            ],
                          ),
                          // Toggle Status Button
                          TextButton.icon(
                            onPressed: () => _updateSchoolStatus(school, !school.isActive),
                            icon: Icon(school.isActive ? Icons.block : Icons.check_circle_outline, size: 16),
                            label: Text(school.isActive ? 'Deactivate' : 'Activate'),
                            style: TextButton.styleFrom(
                              foregroundColor: school.isActive ? Colors.red : Colors.green,
                              backgroundColor: (school.isActive ? Colors.red : Colors.green).withOpacity(0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(isActive ? 'ACTIVE' : 'INACTIVE', 
        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMiniDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildCircularAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}