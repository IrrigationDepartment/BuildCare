import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the Manage Schools Page
import 'manage_schools_page.dart';

import 'pending_approvals_page.dart';
import 'school_master_plan_page.dart';
import 'view_damage_details_page.dart';
import 'view_contract_details_page.dart';
import 'view_contractor_details_page.dart';
import 'manage_technical_officers_list.dart';

class ManageTechnicalOfficersPage extends StatelessWidget {
  const ManageTechnicalOfficersPage({super.key});

  // --- PREMIUM THEME CONSTANTS ---
  static const Color _primaryColor = Color(0xFF1E3A8A); // Deep Indigo
  static const Color _secondaryColor = Color(0xFF0D9488); // Teal
  static const Color _backgroundColor = Color(0xFFF4F7FC); // Soft Light Gray
  static const Color _textDark = Color(0xFF111827);
  
  // Card Accent Colors
  static const Color _accentTotal = Color(0xFF4F46E5); // Bright Indigo
  static const Color _accentPending = Color(0xFFE11D48); // Rose Red
  static const Color _accentActive = Color(0xFF10B981); // Emerald
  static const Color _accentSchools = Color(0xFF0EA5E9); // Sky Blue

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

  // Normalize district name for case-insensitive comparison
  String _normalizeDistrict(String district) {
    return district.trim().toLowerCase();
  }

  Future<int> _getSchoolCountForDistrict(String? office) async {
    try {
      if (office == null || office.isEmpty) return 0;
      
      final normalizedOffice = _normalizeDistrict(office);
      final querySnapshot = await FirebaseFirestore.instance.collection('schools').get();
      
      final filteredSchools = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final schoolDistrict = data['office'] as String? ?? 
                               data['district'] as String? ?? 
                               data['schoolDistrict'] as String?;
        
        if (schoolDistrict == null) return false;
        return _normalizeDistrict(schoolDistrict) == normalizedOffice;
      }).length;
      
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
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Manage Technical Officers',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _getCurrentUserOffice(),
          builder: (context, officeSnapshot) {
            if (officeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _primaryColor));
            }
            if (officeSnapshot.hasError) {
              return Center(child: Text('Error: ${officeSnapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final currentUserOffice = officeSnapshot.data;

            return FutureBuilder<int>(
              future: _getSchoolCountForDistrict(currentUserOffice),
              builder: (context, schoolSnapshot) {
                if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _primaryColor));
                }

                final totalSchools = schoolSnapshot.data ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('userType', isEqualTo: 'Technical Officer')
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _primaryColor));
                    }
                    if (userSnapshot.hasError) {
                      return Center(child: Text('Error: ${userSnapshot.error}', style: const TextStyle(color: Colors.red)));
                    }

                    final docs = userSnapshot.data?.docs ?? [];
                    
                    final districtTOs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final toOffice = data['office'] as String?;
                      if (currentUserOffice == null || toOffice == null) return false;
                      return _normalizeDistrict(toOffice) == _normalizeDistrict(currentUserOffice);
                    }).toList();

                    final totalTOs = districtTOs.length;
                    final activeTOs = districtTOs.where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] == true).length;
                    final pendingTOs = districtTOs.where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] == false).length;

                    return Center(
                      // ConstrainedBox prevents ultra-wide stretching on Web/Desktop
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: _buildContent(context, totalTOs, pendingTOs, activeTOs, totalSchools, currentUserOffice),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleek District Info Header
          if (district != null && district.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
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
                        Text('$district District', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const Text('Overview Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 16),

          // Responsive Stats Grid (2x2 on mobile, 4x1 on desktop)
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final spacing = 16.0;
              final cardWidth = isDesktop 
                  ? (constraints.maxWidth - (spacing * 3)) / 4 
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildStatCard(width: cardWidth, title: 'Total TOs', count: total.toString(), icon: Icons.group_rounded, color: _accentTotal),
                  _buildStatCard(
                    width: cardWidth, title: 'Pending TOs', count: pending.toString(), icon: Icons.pending_actions_rounded, color: _accentPending,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingApprovalsPage())),
                  ),
                  _buildStatCard(
                    width: cardWidth, title: 'Active TOs', count: active.toString(), icon: Icons.how_to_reg_rounded, color: _accentActive,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageTechnicalOfficersListPage(officeFilter: district))),
                  ),
                  _buildStatCard(
                    width: cardWidth, title: 'Total Schools', count: totalSchools.toString(), icon: Icons.apartment_rounded, color: _accentSchools,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSchoolsPage(district: district, userNic: 'ADMIN'))),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 40),
          const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 16),

          // Responsive Options Grid (1 col on mobile, 2 cols on desktop)
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final spacing = 16.0;
              final tileWidth = isDesktop ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildOptionTile(
                      width: tileWidth, context: context, title: 'School Master Plan', icon: Icons.description_rounded, color: const Color(0xFF6366F1), // Indigo variant
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolMasterPlanPage()))),
                  _buildOptionTile(
                      width: tileWidth, context: context, title: 'View Damage Details', icon: Icons.report_problem_rounded, color: const Color(0xFFF59E0B), // Amber
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewDamageDetailsPage(userNic: 'ADMIN')))),
                  _buildOptionTile(
                      width: tileWidth, context: context, title: 'Contract Details', icon: Icons.assignment_rounded, color: const Color(0xFF8B5CF6), // Purple
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractsListPage()))),
                  _buildOptionTile(
                      width: tileWidth, context: context, title: 'Contractor Directory', icon: Icons.engineering_rounded, color: const Color(0xFF14B8A6), // Teal variant
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractorListScreen()))),
                ],
              );
            }
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- REUSABLE RESPONSIVE WIDGETS ---

  Widget _buildStatCard({required double width, required String title, required String count, required IconData icon, required Color color, VoidCallback? onTap}) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), spreadRadius: 0, blurRadius: 15, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_outward_rounded, color: Colors.grey.shade400, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color, height: 1.0)),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({required double width, required BuildContext context, required String title, required IconData icon, required Color color, VoidCallback? onTap}) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark)),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _backgroundColor, shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}