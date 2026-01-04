import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for current user

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
        return data['office'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching current user office: $e');
      return null;
    }
  }

  Future<int> _getCollectionCount(String collectionName, {String? office}) async {
    try {
      Query query = FirebaseFirestore.instance.collection(collectionName);
      
      // Apply office filter for schools if office is provided
      if (collectionName == 'schools' && office != null) {
        query = query.where('office', isEqualTo: office);
      }
      
      final querySnapshot = await query.count().get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error fetching count for $collectionName: $e');
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
              future: _getCollectionCount('schools', office: currentUserOffice),
              builder: (context, schoolSnapshot) {
                if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totalSchools = schoolSnapshot.data ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('userType', isEqualTo: 'Technical Officer')
                      .where('office', isEqualTo: currentUserOffice)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (userSnapshot.hasError) {
                      return Center(child: Text('Error: ${userSnapshot.error}'));
                    }

                    if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                      return _buildContent(context, 0, 0, 0, totalSchools);
                    }

                    final docs = userSnapshot.data!.docs;
                    final totalTOs = docs.length;

                    final activeTOs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['isActive'] == true;
                    }).length;

                    final pendingTOs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['isActive'] == false;
                    }).length;

                    return _buildContent(context, totalTOs, pendingTOs, activeTOs, totalSchools);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, int total, int pending, int active, int totalSchools) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(context, total, pending, active, totalSchools), 
          const SizedBox(height: 24),
          _buildManagementOptions(context),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int total, int pending, int active, int totalSchools) {
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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingApprovalsPage())),
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
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => ManageTechnicalOfficersListPage(
                  // Pass office filter to the list page if needed
                  officeFilter: _getCurrentUserOffice(),
                ),
              )),
            ),
            _buildStatCard('Schools', totalSchools.toString(), Icons.apartment_outlined),
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