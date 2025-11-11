import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // **Firebase Import**

// Existing Imports
import 'manage_to_page.dart'; 
import 'manage_principals_page.dart';
import 'manage_schools_page.dart';
import 'pending_approvals_page.dart';

class DistrictEngDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DistrictEngDashboard({super.key, required this.userData});

  @override
  State<DistrictEngDashboard> createState() => _DistrictEngDashboardState();
}

class _DistrictEngDashboardState extends State<DistrictEngDashboard> {
  int _selectedIndex = 0; // State for BottomNavigationBar
  
  // State variables for fetched data
  int _totalSchools = 0;
  int _activeTOs = 0;
  int _pendingRequests = 0;
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchOverviewCounts(); // Start fetching data when the widget is created
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Handle navigation for other tabs (Profile, Settings)
  }

  // **FIRESTORE DATA FETCHING METHOD**
  Future<void> _fetchOverviewCounts() async {
    try {
      // 1. Total Schools Count (Assuming a 'schools' collection)
      final schoolsSnapshot = await FirebaseFirestore.instance.collection('schools').get();
      final schoolsCount = schoolsSnapshot.docs.length;

      // 2. Active TOs Count (Assuming a 'users' collection with userType: 'Technical Officer' and status: 'active')
      final tosSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'Technical Officer') // Match your Firestore field
          .where('status', isEqualTo: 'active') // Match your Firestore field
          .get();
      final tosCount = tosSnapshot.docs.length;
      
      // 3. Pending Approvals Count (Assuming a 'approvals' collection with status: 'pending')
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('approvals')
          .where('status', isEqualTo: 'pending') // Match your Firestore field
          .get();
      final pendingCount = pendingSnapshot.docs.length;


      // Update the state with the fetched counts
      if (mounted) {
        setState(() {
          _totalSchools = schoolsCount;
          _activeTOs = tosCount;
          _pendingRequests = pendingCount;
          _isLoading = false; // Data fetching complete
        });
      }
    } catch (e) {
      // Handle any errors during fetching (e.g., logging)
      print("Error fetching overview counts: $e");
      // Set counts to 0 and stop loading on error to prevent indefinite spinning
      if(mounted) {
        setState(() {
          _totalSchools = 0;
          _activeTOs = 0;
          _pendingRequests = 0;
          _isLoading = false;
        });
      }
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard data. Please check connection. Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    // Error Fix Applied: Using '??' for null safety on Map access.
    final userName = widget.userData['name'] ?? 'User';
    final userType = widget.userData['userType'] ?? 'District Engineer';
    
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
                'Welcome, $userName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userType,
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
    // Handle loading state
    if (_isLoading) {
      return _buildCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Use fetched data (already checked for null and initialized to 0)
    final totalSchools = _totalSchools.toString();
    final activeTOs = _activeTOs.toString();
    final pendingRequests = _pendingRequests.toString();

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

  Widget _buildManageButton(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            if (label == 'Manage Schools') {
              // Navigation for Manage Schools
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageSchoolsPage(),
                ),
              );
            } else if (label == 'Manage TOs') {
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
              // Default action
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
    // TODO: Use a StreamBuilder or FutureBuilder here to fetch and display the list from Firestore
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
    // TODO: Use a StreamBuilder or FutureBuilder here to fetch the latest request from Firestore
    return _buildCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text('• Manel Withana requested to register as a TO.'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingApprovalsPage(),
                ),
              );
            },
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