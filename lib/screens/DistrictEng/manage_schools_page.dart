import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_school_page.dart';
import '../../models/school.dart';

// --- PREMIUM THEME CONSTANTS ---
const Color _primaryColor = Color(0xFF1E3A8A); // Deep Indigo
const Color _secondaryColor = Color(0xFF0D9488); // Teal
const Color _bgLight = Color(0xFFF4F7FC); // Soft Light Gray
const Color _textDark = Color(0xFF111827);
const Color _dangerRed = Color(0xFFE11D48); // Rose Red
const Color _successGreen = Color(0xFF10B981); // Emerald

// --- User Profile Dialog ---
class UserProfileDialog extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String currentUserNic;
  const UserProfileDialog({Key? key, required this.userData, required this.currentUserNic}) : super(key: key);

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
    final isActive = userData['isActive'] == true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('User Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 24),
                
                // Profile Image and Basic Info
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [_primaryColor, _secondaryColor]),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          backgroundImage: profileImage != null && profileImage.isNotEmpty
                              ? CachedNetworkImageProvider(profileImage) as ImageProvider
                              : null,
                          child: profileImage == null || profileImage.isEmpty
                              ? const Icon(Icons.person_rounded, size: 40, color: _primaryColor)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(userData['name'] ?? 'N/A', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(userData['userType'] ?? 'N/A', style: const TextStyle(fontSize: 13, color: _primaryColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // User Details
                _buildDetailItem('NIC', userData['nic'] ?? 'N/A', Icons.badge_rounded),
                _buildDetailItem('Email', userData['email'] ?? 'N/A', Icons.email_rounded),
                _buildDetailItem('Mobile', userData['mobilPhone'] ?? userData['phone'] ?? 'N/A', Icons.phone_android_rounded),
                _buildDetailItem('Office Phone', userData['officePhone'] ?? 'N/A', Icons.phone_rounded),
                _buildDetailItem('Office/District', userData['office'] ?? 'N/A', Icons.location_city_rounded),
                
                const Divider(color: Color(0xFFF3F4F6), height: 32),
                
                _buildDetailItem('Created Date', _formatTimestamp(createdAt), Icons.calendar_today_rounded),
                if (updatedAt != null)
                  _buildDetailItem('Last Updated', _formatTimestamp(updatedAt), Icons.update_rounded),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateUserStatus(context, userData, !isActive),
                    icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 20),
                    label: Text(isActive ? 'Deactivate User' : 'Activate User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: isActive ? _dangerRed : _successGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: _primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
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
      if (userId == null) throw Exception('User ID not found');

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': newStatus,
        'updateAt': Timestamp.now(),
        'lastEditedByNic': currentUserNic,
      });

      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${newStatus ? "activated" : "deactivated"} successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: newStatus ? _successGreen : _dangerRed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _dangerRed));
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

  String _getSchoolDistrict(Map<String, dynamic> data) {
    return data['office'] as String? ?? data['district'] as String? ?? data['schoolDistrict'] as String? ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final district = _getSchoolDistrict(schoolData);
    final addedByNic = schoolData['addedByNic'] ?? 'N/A';
    final addedByName = addedByUserData?['name'] ?? addedByNic;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('School Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 24),
                
                _buildDetailItem('School Name', school.name, Icons.school_rounded),
                _buildDetailItem('Address', school.address, Icons.location_on_rounded),
                _buildDetailItem('Phone', school.phoneNumber, Icons.phone_rounded),
                _buildDetailItem('Type', school.type, Icons.category_rounded),
                _buildDetailItem('Zone', school.zone, Icons.map_rounded),
                _buildDetailItem('District', district, Icons.location_city_rounded),
                
                const SizedBox(height: 16),
                const Text('STATISTICS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatBadge('Students', school.students.toString(), Icons.people_rounded, const Color(0xFF3B82F6)),
                    _buildStatBadge('Teachers', school.teachers.toString(), Icons.menu_book_rounded, const Color(0xFFF59E0B)),
                  ],
                ),
                
                const Divider(color: Color(0xFFF3F4F6), height: 32),
                const Text('ADMIN INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                
                _buildDetailItem('Status', school.isActive ? 'Active' : 'Deactivated', Icons.info_outline_rounded, 
                    valueColor: school.isActive ? _successGreen : _dangerRed),
                
                // Clickable "Added By" section with profile image
                InkWell(
                  onTap: onViewAddedByProfile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        if (addedByUserData?['profile_image'] != null)
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: CachedNetworkImageProvider(addedByUserData!['profile_image']),
                          )
                        else
                          const CircleAvatar(radius: 18, backgroundColor: _primaryColor, child: Icon(Icons.person_rounded, color: Colors.white, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Added By', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                              Text(addedByName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryColor)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                _buildDetailItem('Last Edited', school.formattedLastEditedAt, Icons.history_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: _primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? _textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
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
  
  List<Map<String, dynamic>> _schoolsData = [];
  Map<String, Map<String, dynamic>> _addedByUsersCache = {};

  String _normalizeDistrict(String district) => district.trim().toLowerCase();

  String? _getSchoolDistrictFromData(Map<String, dynamic> data) {
    return data['office'] as String? ?? data['district'] as String? ?? data['schoolDistrict'] as String?;
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

  void _onSearchChanged() => setState(() => _searchQuery = _searchController.text.toLowerCase());

  Future<Map<String, dynamic>?> _fetchUserByNic(String? nic) async {
    if (nic == null || nic.isEmpty) return null;
    if (_addedByUsersCache.containsKey(nic)) return _addedByUsersCache[nic];
    
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').where('nic', isEqualTo: nic).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final userData = doc.data();
        userData['userId'] = doc.id; 
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
    
    if(context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => SchoolDetailsDialog(
          school: school,
          schoolData: schoolData,
          addedByUserData: addedByUserData,
          onViewAddedByProfile: () {
            Navigator.of(context).pop(); 
            if (addedByUserData != null) _showAddedByProfile(context, addedByUserData);
          },
        ),
      );
    }
  }

  void _showAddedByProfile(BuildContext context, Map<String, dynamic> userData) {
    showDialog(context: context, builder: (context) => UserProfileDialog(userData: userData, currentUserNic: widget.userNic));
  }

  void _navigateToEditPage(BuildContext context, School school) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditSchoolPage(school: school, userNic: widget.userNic)));
  }

  Future<void> _updateSchoolStatus(School school, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('schools').doc(school.id).update({
        'isActive': newStatus,
        'lastEditedAt': Timestamp.now(),
        'lastEditedByNic': widget.userNic,
      });

      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${school.name} ${newStatus ? "activated" : "deactivated"}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: newStatus ? _successGreen : _dangerRed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _dangerRed));
    }
  }

  String _getDistrictDisplayText(Map<String, dynamic> data) {
    return _getSchoolDistrictFromData(data) ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: Text(widget.district != null ? 'Schools' : 'Manage Schools', style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Perfect for responsive Desktop/Tablet
          child: Column(
            children: [
              // Sleek District Info Header
              if (widget.district != null && widget.district!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_primaryColor, _secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.location_on_rounded, size: 24, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Region', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('${widget.district} District', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildSearchBar(),
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('schools').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _primaryColor));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                    final docs = snapshot.data!.docs;
                    List<DocumentSnapshot> filteredDocs = docs;
                    
                    if (widget.district != null && widget.district!.isNotEmpty) {
                      final normalizedDistrict = _normalizeDistrict(widget.district!);
                      filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final schoolDistrict = _getSchoolDistrictFromData(data);
                        if (schoolDistrict == null) return false;
                        return _normalizeDistrict(schoolDistrict) == normalizedDistrict;
                      }).toList();
                    }

                    _schoolsData = filteredDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                    
                    final List<School> filteredSchools = filteredDocs.map((doc) => School.fromFirestore(doc)).where((school) {
                      if (_searchQuery.isEmpty) return true;
                      return school.name.toLowerCase().contains(_searchQuery) || school.address.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredSchools.isEmpty) return _buildEmptyState(isSearch: true);

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredSchools.length,
                      itemBuilder: (context, index) {
                        final school = filteredSchools[index];
                        final schoolData = _schoolsData[index];
                        
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _fetchUserByNic(schoolData['addedByNic']),
                          builder: (context, userSnapshot) {
                            final addedByUserData = userSnapshot.data;
                            final addedByName = addedByUserData?['name'] ?? schoolData['addedByNic'] ?? 'N/A';
                            final district = _getDistrictDisplayText(schoolData);
                            
                            return _buildSchoolCard(school, schoolData, district, addedByName, addedByUserData);
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
      ),
    );
  }

  Widget _buildEmptyState({bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(isSearch ? Icons.search_off_rounded : Icons.school_rounded, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            isSearch 
              ? 'No schools match "$_searchQuery"'
              : widget.district != null ? 'No schools found in ${widget.district}' : 'No schools found.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or address...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search_rounded, color: _primaryColor),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear_rounded, color: Colors.grey), onPressed: () => _searchController.clear()) 
            : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildSchoolCard(School school, Map<String, dynamic> schoolData, String district, String addedByName, Map<String, dynamic>? addedByUserData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showSchoolDetails(context, school, schoolData),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(school.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: school.isActive ? _successGreen.withOpacity(0.1) : _dangerRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      school.isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(color: school.isActive ? _successGreen : _dangerRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(school.address, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF3F4F6), height: 32),
              
              Row(
                children: [
                  Expanded(child: _buildInfoItem(Icons.location_city_rounded, district)),
                  Expanded(child: _buildInfoItem(Icons.people_alt_rounded, '${school.students} students')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInfoItem(Icons.phone_rounded, school.phoneNumber)),
                  Expanded(child: _buildInfoItem(Icons.category_rounded, school.type)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons (Responsive Row)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSchoolDetails(context, school, schoolData),
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                      label: const Text('View', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: const BorderSide(color: _primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateSchoolStatus(school, !school.isActive),
                      icon: Icon(school.isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 16),
                      label: Text(school.isActive ? 'Deactivate' : 'Activate', style: const TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: school.isActive ? _dangerRed : _successGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: IconButton(
                      onPressed: () => _navigateToEditPage(context, school),
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFFF59E0B)),
                      tooltip: 'Edit School',
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

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 14, color: _primaryColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: _textDark, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}