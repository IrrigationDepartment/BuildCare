import 'package:flutter/material.dart';
//  Existing Import for Technical Officer Management
import 'manage_to_page.dart'; 

//  Import the file containing the Manage Principals page
import 'manage_principals_page.dart';

class DistrictEngDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DistrictEngDashboard({super.key, required this.userData});

  @override
  State<DistrictEngDashboard> createState() => _DistrictEngDashboardState();
}

class _DistrictEngDashboardState extends State<DistrictEngDashboard> {
  int _selectedIndex = 0; // State for BottomNavigationBar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Handle navigation for other tabs (Profile, Settings)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // A light grey background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildOverviewSection(),
                const SizedBox(height: 24),
                _buildSectionTitle('Recent Activity'),
                _buildRecentActivitySection(),
                const SizedBox(height: 24),
                _buildSectionTitle('Approval Request'),
                _buildApprovalRequestSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey, // Added for better visibility
        onTap: _onItemTapped,
      ),
    );
  }

  // --- WIDGET BUILDER HELPERS ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.userData['name'] ?? 'User'}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.userData['userType'] ?? 'District Engineer',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    // TODO: Fetch these counts from Firestore
    const totalSchools = '150';
    const activeTOs = '25';
    const pendingRequests = '5';

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewCard('Total Schools', totalSchools),
              _buildOverviewCard('Active TOs', activeTOs),
              _buildOverviewCard('Pending', pendingRequests),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildManageButton('Manage Schools'),
              _buildManageButton('Manage TOs'),
              _buildManageButton('Manage Principals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String count) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  //  Updated _buildManageButton with Navigation Logic for Manage Principals
  Widget _buildManageButton(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            if (label == 'Manage TOs') {
              // Navigation to the Manage Technical Officers page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageTechnicalOfficersPage(),
                ),
              );
            } else if (label == 'Manage Principals') {
              // Navigation to the Manage Principals page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManagePrincipalsPage(),
                ),
              );
            } else {
              // Action for 'Manage Schools' and other buttons
              // TODO: Implement navigation for 'Manage Schools'
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped: $label')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    // TODO: Fetch this list from Firestore
    return _buildCard(
      child: Column(
        children: [
          _buildActivityItem('Thurstan College - Damaged Roof',
              'Colombo - Status, Pending Review'),
          const Divider(),
          _buildActivityItem('Royal College - New Building',
              'Colombo - Status, Approved'),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined, color: Colors.teal, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalRequestSection() {
    // TODO: Fetch this request from Firestore
    return _buildCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text('• Manel Withana requested to register as a TO.'),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade300,
              foregroundColor: Colors.white,
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }
}