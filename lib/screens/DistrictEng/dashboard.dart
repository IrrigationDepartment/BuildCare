//
// 📁 FILENAME: district_eng_dashboard.dart
//
import 'package:flutter/material.dart';

// Import the two files we just created
import 'dashboard_service.dart';
import 'dashboard_widgets.dart';

class DistrictEngDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DistrictEngDashboard({super.key, required this.userData});

  @override
  State<DistrictEngDashboard> createState() => _DistrictEngDashboardState();
}

class _DistrictEngDashboardState extends State<DistrictEngDashboard> {
  int _selectedIndex = 0;
  
  // State variables for fetched data
  int _totalSchools = 0;
  int _activeTOs = 0;
  int _pendingRequests = 0;
  bool _isLoading = true; // Loading state

  // Create an instance of the service
  final DashboardService _service = DashboardService();

  @override
  void initState() {
    super.initState();
    _fetchData(); // Start fetching data
  }

  // New method to call the service and handle state
  Future<void> _fetchData() async {
    try {
      final counts = await _service.fetchOverviewCounts();
      
      if (mounted) {
        setState(() {
          _totalSchools = counts.totalSchools;
          _activeTOs = counts.activeTOs;
          _pendingRequests = counts.pendingRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle errors
      if(mounted) {
        setState(() {
          _isLoading = false;
          _totalSchools = 0;
          _activeTOs = 0;
          _pendingRequests = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                // --- THIS IS YOUR NEW, CLEAN UI ---
                
                // 1. The Header
                DashboardHeader(userData: widget.userData),
                const SizedBox(height: 24),

                // 2. The Overview
                DashboardOverview(
                  isLoading: _isLoading,
                  totalSchools: _totalSchools,
                  activeTOs: _activeTOs,
                  pendingRequests: _pendingRequests,
                ),
                const SizedBox(height: 24),

                // 3. Recent Activity
                const SectionTitle('Recent Activity'),
                const RecentActivitySection(),
                const SizedBox(height: 24),

                // 4. Approval Request
                const SectionTitle('Approval Request'),
                const ApprovalRequestSection(),
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
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}