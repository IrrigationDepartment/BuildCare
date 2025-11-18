import 'package:flutter/material.dart';

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

class ManageTechnicalOfficersPage extends StatelessWidget {
  const ManageTechnicalOfficersPage({super.key});

  // Define the consistent colors from the ManagePrincipalsPage
  static const Color _cardColor = Color(0xFFE3F2FD);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _backgroundColor = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the consistent background color
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        // Transparent app bar to blend with the background
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // Navigate back
        ),
        title: const Text(
          'Manage Technical Officers',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Use consistent padding
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(context), // Pass context to the grid builder
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              // Pass context to _buildManagementOptions to allow navigation
              _buildManagementOptions(context), 
            ],
          ),
        ),
      ),
      // Consistent Bottom Navigation Bar styling
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), // Changed to outlined home icon
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
        // The current index is 1 (person icon)
        currentIndex: 1,
        selectedItemColor: _primaryBlue, // The highlighted icon is blue
        unselectedItemColor: Colors.grey, // Non-selected icons are grey
        showSelectedLabels: false, // Hide labels for a cleaner look
        showUnselectedLabels: false,
        backgroundColor: Colors.white, // White background for the bar
        type: BottomNavigationBarType.fixed, // To show all icons clearly
      ),
    );
  }

  // Helper widget to build the stats grid (Total TOs, Pending, Active, Schools)
  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total TOs - Group Icon
            _buildStatCard('Total TOs', '25', Icons.group_outlined),

            // PENDING CARD - NOW CLICKABLE
            _buildStatCard(
              'Pending',
              '5',
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
            // Active TOs - Group with 'Add' Icon
            _buildStatCard('Active TOs', '20', Icons.how_to_reg_outlined),
            // Schools - School/Building Icon
            _buildStatCard('Schools', '150', Icons.apartment_outlined),
          ],
        ),
      ],
    );
  }

  // Helper widget for a single stat card in the grid
  Widget _buildStatCard(
      String title, String count, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap, // Apply the onTap function here
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          height: 120, // Give it a fixed height for consistent look
          decoration: BoxDecoration(
            color: _cardColor, // Use the light blue card color
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Subtle shadow
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
                  Icon(icon, size: 36, color: _primaryBlue), // Use primary blue icon color
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the search bar
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
          contentPadding: EdgeInsets.symmetric(vertical: 12), // Consistent padding
        ),
      ),
    );
  }

  // Helper widget to build the three main management option tiles
  Widget _buildManagementOptions(BuildContext context) {
    return Column(
      children: [
        // Master Plan Navigation
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

        // Damage Details Navigation
        _buildOptionTile(
            context, 
            'View Damage Details', 
            Icons.remove_red_eye_outlined,
            onTap: () {
              // Note: The ViewDamageDetailsPage requires a userNic parameter. 
              // Assuming a placeholder or default NIC for navigation from this admin page.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewDamageDetailsPage(userNic: 'ADMIN_NIC_123'),
                ),
              );
            },
        ), 
        const SizedBox(height: 16),

        // Contract Details Navigation
        _buildOptionTile(
            context, 
            'View Contract Details', 
            Icons.edit_note_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // FIX: Use the ContractsListPage class
                  builder: (context) => const ContractsListPage(),
                ),
              );
            },
        ), 
        const SizedBox(height: 16),

        // Contractor Details Navigation
        _buildOptionTile(
            context, 
            'View Contractor Details', 
            Icons.edit_note_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // FIX: Use the ContractorListScreen class from view_contractor_details_page.dart
                  builder: (context) => const ContractorListScreen(),
                ),
              );
            },
        ), 
      ],
    );
  }

  // Helper widget for a single option tile
  Widget _buildOptionTile(
      BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {
        // Default action for unlinked options
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped: $title - Navigation not set')),
        );
      },
      child: Container(
        width: double.infinity,
        // Used consistent vertical padding
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white, // White background for the tiles
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
            Icon(icon, size: 28, color: _primaryBlue), // Use primary blue icon color
          ],
        ),
      ),
    );
  }
}