import 'package:flutter/material.dart';

// Import the two files we just created
import 'dashboard_service.dart';
import 'dashboard_widgets.dart';

// Main dashboard screen for District Engineer
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

  // --- 1. VARIABLE TO HOLD THE NIC ---
  late final String userNic;

  // Create an instance of the service
  final DashboardService _service = DashboardService();

  @override
  void initState() {
    super.initState();
    
    // --- 2. GET THE NIC FROM THE 'userData' MAP ---
    userNic = widget.userData['nic'] ?? 'No NIC Found';

    print('--- District Engineer Dashboard ---');
    print('Logged in User NIC: $userNic');
    print('Full User Data: ${widget.userData}');
    
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
                
                // 1. The Header
                DashboardHeader(userData: widget.userData),
                const SizedBox(height: 24),

                // 2. The Overview
                DashboardOverview(
                  isLoading: _isLoading,
                  totalSchools: _totalSchools,
                  activeTOs: _activeTOs,
                  pendingRequests: _pendingRequests,
                  userNic: userNic, // Passing the required userNic
                ),
                const SizedBox(height: 24),

                // 3. Recent Issues Section
                const RecentIssuesSection(),
                const SizedBox(height: 24), 

                // 4. Recent Schools Section (FIXED: Uses 'addDate' for correct sorting)
                const RecentSchoolsSection(),
                const SizedBox(height: 24), 

                // 5. Recent Users Section
                const RecentUsersSection(),
                const SizedBox(height: 24), 

                // 6. Approval Request
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

