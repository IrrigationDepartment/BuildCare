import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the Manage Schools Page
import 'manage_schools_page.dart'; // ADD THIS IMPORT

import 'pending_approvals_page.dart';
import 'school_master_plan_page.dart';
import 'view_damage_details_page.dart';
import 'view_contract_details_page.dart';
import 'view_contractor_details_page.dart';
import 'manage_technical_officers_list.dart';

class ManageTechnicalOfficersPage extends StatelessWidget {
  const ManageTechnicalOfficersPage({super.key});

  static const Color _cardColor = Color(0xFFE3F2FD);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _backgroundColor = Color(0xFFF0F2F5);

  // Get current user's office from Firestore
  Future<String?> _getCurrentUserOffice() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        debugPrint('User office field: ${data['office']}');
        return data['office'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching current user office: $e');
      return null;
    }
  }

  // Normalize district name for case-insensitive comparison
  String _normalizeDistrict(String district) {
    return district.trim().toLowerCase();
  }

  Future<int> _getSchoolCountForDistrict(String? office) async {
    try {
      if (office == null || office.isEmpty) {
        debugPrint('Office is null or empty');
        return 0;
      }
      
      final normalizedOffice = _normalizeDistrict(office);
      debugPrint('Looking for schools with district (normalized): $normalizedOffice');
      
      // Query all schools
      final querySnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .get();
      
      debugPrint('Total schools in database: ${querySnapshot.docs.length}');
      
      // Check what fields exist in the first document
      if (querySnapshot.docs.isNotEmpty) {
        final firstDoc = querySnapshot.docs.first;
        debugPrint('First school document fields: ${firstDoc.data().keys}');
        debugPrint('First school office value: ${firstDoc.data()['office']}');
        debugPrint('First school district value: ${firstDoc.data()['district']}');
      }
      
      // Try different possible field names
      final filteredSchools = querySnapshot.docs.where((doc) {
        final data = doc.data();
        
        // Check multiple possible field names
        final schoolDistrict = data['office'] as String? ?? 
                             data['district'] as String? ?? 
                             data['schoolDistrict'] as String?;
        
        if (schoolDistrict == null) {
          debugPrint('School ${doc.id} has no district field');
          return false;
        }
        
        final normalizedSchoolDistrict = _normalizeDistrict(schoolDistrict);
        debugPrint('School ${doc.id}: $normalizedSchoolDistrict vs User: $normalizedOffice');
        
        return normalizedSchoolDistrict == normalizedOffice;
      }).length;
      
      debugPrint('Found $filteredSchools schools for district $office');
      return filteredSchools;
    } catch (e) {
      debugPrint('Error fetching school count for district $office: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Manage Technical Officers',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _getCurrentUserOffice(),
          builder: (context, officeSnapshot) {
            if (officeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (officeSnapshot.hasError) {
              return Center(child: Text('Error: ${officeSnapshot.error}'));
            }

            final currentUserOffice = officeSnapshot.data;

            return FutureBuilder<int>(
              future: _getSchoolCountForDistrict(currentUserOffice),
              builder: (context, schoolSnapshot) {
                if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totalSchools = schoolSnapshot.data ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('userType', isEqualTo: 'Technical Officer')
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (userSnapshot.hasError) {
                      return Center(child: Text('Error: ${userSnapshot.error}'));
                    }

                    final docs = userSnapshot.data?.docs ?? [];
                    
                    // Filter technical officers by office (case-insensitive)
                    final districtTOs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final toOffice = data['office'] as String?;
                      
                      if (currentUserOffice == null || toOffice == null) return false;
                      
                      debugPrint('Technical Officer office: $toOffice, User office: $currentUserOffice');
                      
                      return _normalizeDistrict(toOffice) == 
                            _normalizeDistrict(currentUserOffice);
                    }).toList();

                    final totalTOs = districtTOs.length;

                    final activeTOs = districtTOs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['isActive'] == true;
                    }).length;

                    final pendingTOs = districtTOs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['isActive'] == false;
                    }).length;

                    debugPrint('Stats - Technical Officers: $totalTOs, Active: $activeTOs, Pending: $pendingTOs, Schools: $totalSchools');

                    return _buildContent(
                      context, 
                      totalTOs, 
                      pendingTOs, 
                      activeTOs, 
                      totalSchools, 
                      currentUserOffice
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, int total, int pending, int active, int totalSchools, String? district) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // District Info Header
          if (district != null && district.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
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
                      'District: $district',
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
          
          _buildStatsGrid(context, total, pending, active, totalSchools, district), 
          const SizedBox(height: 24),
          _buildManagementOptions(context),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int total, int pending, int active, int totalSchools, String? district) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard('Total TOs', total.toString(), Icons.group_outlined),
            _buildStatCard(
              'Pending', 
              pending.toString(),
              Icons.pending_actions_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PendingApprovalsPage(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard(
              'Active TOs', 
              active.toString(), 
              Icons.how_to_reg_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageTechnicalOfficersListPage(
                      officeFilter: district,
                    ),
                  ),
                );
              },
            ),
            // MODIFIED THIS CARD TO REDIRECT TO MANAGE SCHOOLS PAGE
            _buildStatCard(
              'Schools in District', 
              totalSchools.toString(), 
              Icons.apartment_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageSchoolsPage(
                      district: district, // Pass the district as parameter
                      userNic: 'ADMIN', // Required parameter
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          height: 120,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    count,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Icon(icon, size: 36, color: _primaryBlue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementOptions(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(
            context, 
            'View School Master Plan', 
            Icons.description_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SchoolMasterPlanPage())),
        ),
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 
            'View Damage Details', 
            Icons.remove_red_eye_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewDamageDetailsPage(userNic: 'ADMIN'))),
        ), 
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 
            'View Contract Details', 
            Icons.edit_note_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractsListPage())),
        ), 
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 
            'View Contractor Details', 
            Icons.edit_note_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractorListScreen())),
        ), 
      ],
    );
  }

  Widget _buildOptionTile(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            Icon(icon, size: 28, color: _primaryBlue),
          ],
        ),
      ),
    );
  }
}