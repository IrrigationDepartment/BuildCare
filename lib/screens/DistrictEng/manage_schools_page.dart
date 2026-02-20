import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:flutter/services.dart';
import 'edit_school_page.dart';
import '../../models/school.dart';

// --- Updated Modern School Details Dialog ---
class SchoolDetailsDialog extends StatelessWidget {
  final School school;
  const SchoolDetailsDialog({Key? key, required this.school}) : super(key: key);

  @override
  Widget build(BuildContext context) {
=======
import 'package:cached_network_image/cached_network_image.dart'; // Add this package
import 'edit_school_page.dart';
import '../../models/school.dart';

// --- User Profile Dialog ---
class UserProfileDialog extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String currentUserNic;
  const UserProfileDialog({Key? key, required this.userData, required this.currentUserNic}) : super(key: key);

  // Format timestamp to readable date
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = userData['profile_image'] as String?;
    final createdAt = userData['createdAt'] as Timestamp?;
    final updatedAt = userData['updateAt'] as Timestamp?;

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
                    'User Profile',
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
              
              // Profile Image and Basic Info
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileImage != null && profileImage.isNotEmpty
                          ? CachedNetworkImageProvider(profileImage) as ImageProvider
                          : const AssetImage('assets/default_avatar.png'),
                      child: profileImage == null || profileImage.isEmpty
                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userData['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      userData['userType'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // User Details
              _buildDetailItem('NIC', userData['nic'] ?? 'N/A', Icons.badge_outlined),
              _buildDetailItem('Email', userData['email'] ?? 'N/A', Icons.email_outlined),
              _buildDetailItem('Mobile', userData['mobilPhone'] ?? userData['phone'] ?? 'N/A', Icons.phone_outlined),
              _buildDetailItem('Office Phone', userData['officePhone'] ?? 'N/A', Icons.phone_android_outlined),
              _buildDetailItem('Office/District', userData['office'] ?? 'N/A', Icons.location_city_outlined),
              
              // Dates
              _buildDetailItem('Created Date', _formatTimestamp(createdAt), Icons.calendar_today_outlined),
              if (updatedAt != null)
                _buildDetailItem('Last Updated', _formatTimestamp(updatedAt), Icons.update_outlined),
              
              const Divider(height: 20),
              
              // Status Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: ${userData['isActive'] == true ? 'ACTIVE' : 'INACTIVE'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: userData['isActive'] == true ? Colors.green : Colors.red,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: userData['isActive'] == true ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userData['isActive'] == true ? '✓ Active' : '✗ Inactive',
                      style: TextStyle(
                        color: userData['isActive'] == true ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _updateUserStatus(context, userData, !(userData['isActive'] == true));
                    },
                    icon: Icon(
                      userData['isActive'] == true ? Icons.block : Icons.check_circle,
                      size: 20,
                    ),
                    label: Text(userData['isActive'] == true ? 'Deactivate' : 'Activate'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: userData['isActive'] == true ? Colors.red : Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
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
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserStatus(BuildContext context, Map<String, dynamic> userData, bool newStatus) async {
    try {
      final userId = userData['userId'] ?? userData['id'];
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User ID not found')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': newStatus,
        'updateAt': Timestamp.now(),
        'lastEditedByNic': currentUserNic,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${newStatus ? "activated" : "deactivated"} successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newStatus ? Colors.green : Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// --- Updated Modern School Details Dialog ---
class SchoolDetailsDialog extends StatelessWidget {
  final School school;
  final Map<String, dynamic> schoolData;
  final Map<String, dynamic>? addedByUserData;
  final VoidCallback onViewAddedByProfile;
  
  const SchoolDetailsDialog({
    Key? key, 
    required this.school, 
    required this.schoolData,
    this.addedByUserData,
    required this.onViewAddedByProfile,
  }) : super(key: key);

  // Helper method to get district from school data
  String _getSchoolDistrict(Map<String, dynamic> data) {
    return data['office'] as String? ?? 
           data['district'] as String? ?? 
           data['schoolDistrict'] as String? ?? 
           'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final district = _getSchoolDistrict(schoolData);
    final addedByNic = schoolData['addedByNic'] ?? 'N/A';
    final addedByName = addedByUserData?['name'] ?? addedByNic;

>>>>>>> main
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
<<<<<<< HEAD
=======
              _buildDetailItem('District', district, Icons.location_city_outlined),
>>>>>>> main
              
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
<<<<<<< HEAD
              _buildDetailItem('Added By', school.addedByNic ?? 'N/A', Icons.person_outline),
=======
              
              // Clickable "Added By" section with profile image
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_add_outlined, size: 18, color: Colors.blueAccent.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Added By', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                          InkWell(
                            onTap: onViewAddedByProfile,
                            child: Row(
                              children: [
                                // Profile image thumbnail
                                if (addedByUserData?['profile_image'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(addedByUserData!['profile_image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                Text(
                                  addedByName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                              ],
                            ),
                          ),
                          if (addedByUserData?['userType'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                addedByUserData!['userType'],
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
>>>>>>> main
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
<<<<<<< HEAD
  final String userNic;
  const ManageSchoolsPage({Key? key, required this.userNic}) : super(key: key);
=======
  final String? district;
  final String userNic;
  const ManageSchoolsPage({Key? key, this.district, required this.userNic}) : super(key: key);
>>>>>>> main

  @override
  State<ManageSchoolsPage> createState() => _ManageSchoolsPageState();
}

class _ManageSchoolsPageState extends State<ManageSchoolsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
<<<<<<< HEAD
=======
  
  // Store the document data alongside schools
  List<Map<String, dynamic>> _schoolsData = [];
  Map<String, Map<String, dynamic>> _addedByUsersCache = {};

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
>>>>>>> main

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

<<<<<<< HEAD
  void _showSchoolDetails(BuildContext context, School school) {
    showDialog(
      context: context,
      builder: (BuildContext context) => SchoolDetailsDialog(school: school),
=======
  // Fetch user data by NIC - UPDATED for your Firestore structure
  Future<Map<String, dynamic>?> _fetchUserByNic(String? nic) async {
    if (nic == null || nic.isEmpty) return null;
    
    // Check cache first
    if (_addedByUsersCache.containsKey(nic)) {
      return _addedByUsersCache[nic];
    }
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: nic)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final userData = doc.data();
        userData['userId'] = doc.id; // Store document ID for updates
        _addedByUsersCache[nic] = userData;
        return userData;
      }
    } catch (e) {
      debugPrint('Error fetching user by NIC $nic: $e');
    }
    
    return null;
  }

  void _showSchoolDetails(BuildContext context, School school, Map<String, dynamic> schoolData) async {
    final addedByNic = schoolData['addedByNic'];
    final addedByUserData = await _fetchUserByNic(addedByNic);
    
    showDialog(
      context: context,
      builder: (BuildContext context) => SchoolDetailsDialog(
        school: school,
        schoolData: schoolData,
        addedByUserData: addedByUserData,
        onViewAddedByProfile: () {
          Navigator.of(context).pop(); // Close school details
          if (addedByUserData != null) {
            _showAddedByProfile(context, addedByUserData);
          }
        },
      ),
    );
  }

  void _showAddedByProfile(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (BuildContext context) => UserProfileDialog(
        userData: userData,
        currentUserNic: widget.userNic,
      ),
>>>>>>> main
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

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft background color
      appBar: AppBar(
        title: const Text('Manage Schools', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
=======
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
>>>>>>> main
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
<<<<<<< HEAD
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
=======
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
>>>>>>> main
            child: _buildSearchBar(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('schools').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
<<<<<<< HEAD
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No schools found.'));
                }

                final List<School> filteredSchools = snapshot.data!.docs
                    .map((doc) => School.fromFirestore(doc))
                    .where((s) => s.name.toLowerCase().contains(_searchQuery) || s.address.toLowerCase().contains(_searchQuery))
                    .toList();
=======
                
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

                // Store the data for use in list view
                _schoolsData = filteredDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                
                // Create School objects
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
>>>>>>> main

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredSchools.length,
<<<<<<< HEAD
                  itemBuilder: (context, index) => _buildSchoolCard(filteredSchools[index]),
=======
                  itemBuilder: (context, index) {
                    final school = filteredSchools[index];
                    final schoolData = _schoolsData[index];
                    
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchUserByNic(schoolData['addedByNic']),
                      builder: (context, userSnapshot) {
                        final addedByUserData = userSnapshot.data;
                        final addedByName = addedByUserData?['name'] ?? schoolData['addedByNic'] ?? 'N/A';
                        final district = _getDistrictDisplayText(schoolData);
                        
                        return _buildSchoolCard(
                          school, 
                          schoolData, 
                          district, 
                          addedByName,
                          addedByUserData,
                        );
                      },
                    );
                  },
>>>>>>> main
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
<<<<<<< HEAD
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()) 
=======
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E88E5)),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () => _searchController.clear(),
              ) 
>>>>>>> main
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

<<<<<<< HEAD
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
=======
  Widget _buildSchoolCard(
    School school, 
    Map<String, dynamic> schoolData, 
    String district,
    String addedByName,
    Map<String, dynamic>? addedByUserData,
  ) {
    final profileImage = addedByUserData?['profile_image'] as String?;
    
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
        onTap: () => _showSchoolDetails(context, school, schoolData),
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
              
              // Added By section - Clickable with profile image
              const SizedBox(height: 8),
              InkWell(
                onTap: addedByUserData != null 
                    ? () => _showAddedByProfile(context, addedByUserData)
                    : null,
                child: Row(
                  children: [
                    // Profile image thumbnail
                    if (profileImage != null && profileImage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(profileImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const Icon(Icons.person_add, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Added by: $addedByName',
                        style: TextStyle(
                          fontSize: 12,
                          color: addedByUserData != null ? Colors.blue : Colors.black54,
                          decoration: addedByUserData != null ? TextDecoration.underline : TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (addedByUserData != null)
                      const Icon(Icons.chevron_right, size: 16, color: Colors.blueGrey),
                  ],
                ),
              ),
              
              const Divider(height: 20),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // View Details Button
                  ElevatedButton.icon(
                    onPressed: () => _showSchoolDetails(context, school, schoolData),
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
>>>>>>> main
            ],
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
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
=======
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
>>>>>>> main
    );
  }
}