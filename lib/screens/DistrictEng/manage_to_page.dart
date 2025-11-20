import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

// Import for the Pending Approvals Page 
import 'pending_approvals_page.dart';

// Import the School Master Plan Page
import 'school_master_plan_page.dart'; 

// Import the View Damage Details Page
import 'view_damage_details_page.dart';

// Import the Contract List Page 
import 'view_contract_details_page.dart';

// Import the View Contractor Details Page
import 'view_contractor_details_page.dart';

// --- IMPORT THE NEW LIST PAGE HERE ---
import 'manage_technical_officers_list.dart'; 

class ManageTechnicalOfficersPage extends StatelessWidget {
  const ManageTechnicalOfficersPage({super.key});

  // Define the consistent colors
  static const Color _cardColor = Color(0xFFE3F2FD);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _backgroundColor = Color(0xFFF0F2F5);

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
        child: StreamBuilder<QuerySnapshot>(
          // Query: Get all users where userType is 'Technical Officer'
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('userType', isEqualTo: 'Technical Officer')
              .snapshots(),
          builder: (context, snapshot) {
            // 1. Handle Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Handle Error State
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // 3. Process Data
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
               // Show empty state with 0 counts if no data found
               return _buildContent(context, 0, 0, 0);
            }

            final docs = snapshot.data!.docs;
            final totalTOs = docs.length;

            // Count Active (isActive == true)
            final activeTOs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isActive'] == true;
            }).length;

            // Count Inactive/Pending (isActive == false)
            final pendingTOs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isActive'] == false;
            }).length;

            // 4. Return the Main UI with calculated data
            return _buildContent(context, totalTOs, pendingTOs, activeTOs);
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: 1,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Extracted the main content scrolling view to keep StreamBuilder clean
  Widget _buildContent(BuildContext context, int total, int pending, int active) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pass the calculated numbers to the grid
          _buildStatsGrid(context, total, pending, active), 
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildManagementOptions(context),
        ],
      ),
    );
  }

  // Updated widget to accept dynamic data
  Widget _buildStatsGrid(BuildContext context, int total, int pending, int active) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total TOs (Live Data)
            _buildStatCard('Total TOs', total.toString(), Icons.group_outlined),

            // Pending / Inactive (Live Data)
            _buildStatCard(
              'Pending', // or 'Deactivated'
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
            // Active TOs (Live Data) - NOW LINKED
            _buildStatCard(
              'Active TOs', 
              active.toString(), 
              Icons.how_to_reg_outlined,
              onTap: () {
                // Navigate to the new Manage/List page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageTechnicalOfficersListPage(),
                  ),
                );
              },
            ),
            
            // Note: Schools data usually comes from a different collection ('schools').
            // Keeping this hardcoded or fetch separately if needed.
            _buildStatCard('Schools', '150', Icons.apartment_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, {VoidCallback? onTap}) {
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
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search TOs.......',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SchoolMasterPlanPage(),
                ),
              );
            },
        ),
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 
            'View Damage Details', 
            Icons.remove_red_eye_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewDamageDetailsPage(userNic: 'ADMIN'),
                ),
              );
            },
        ), 
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 
            'View Contract Details', 
            Icons.edit_note_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContractsListPage(),
                ),
              );
            },
        ), 
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 
            'View Contractor Details', 
            Icons.edit_note_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContractorListScreen(),
                ),
              );
            },
        ), 
      ],
    );
  }

  Widget _buildOptionTile(
      BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
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
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            Icon(icon, size: 28, color: _primaryBlue),
          ],
        ),
      ),
    );
  }
}