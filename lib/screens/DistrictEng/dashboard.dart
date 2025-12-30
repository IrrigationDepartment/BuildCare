import 'package:flutter/material.dart';

// Imports for dashboard logic and UI components
import 'dashboard_service.dart';
import 'dashboard_widgets.dart';
import 'profile.dart'; 
import 'settings.dart'; 
import 'notifications.dart'; // නිවේදන පිටුව සඳහා නව import එක

class DistrictEngDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DistrictEngDashboard({super.key, required this.userData});

  @override
  State<DistrictEngDashboard> createState() => _DistrictEngDashboardState();
}

class _DistrictEngDashboardState extends State<DistrictEngDashboard> {
  int _selectedIndex = 0;
  
  // State variables for dashboard metrics
  int _totalSchools = 0;
  int _activeTOs = 0;
  int _pendingRequests = 0;
  bool _isLoading = true; 

  late final String userNic;
  final DashboardService _service = DashboardService();

  @override
  void initState() {
    super.initState();
    // Get NIC from passed user data
    userNic = widget.userData['nic'] ?? 'No NIC Found';
    _fetchData(); 
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
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
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle Bottom Navigation Clicks
  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = index);
      _fetchData(); 
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), 
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header සහ Notification Icon එක පෙන්වන Row එක
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DashboardHeader(userData: widget.userData),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined, 
                          color: Colors.black87,
                          size: 28,
                        ),
                        onPressed: () {
                          // Notification Page එකට navigate වීම
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DashboardOverview(
                    isLoading: _isLoading,
                    totalSchools: _totalSchools,
                    activeTOs: _activeTOs,
                    pendingRequests: _pendingRequests,
                    userNic: userNic, 
                  ),
                  const SizedBox(height: 24),
                  const RecentIssuesSection(),
                  const SizedBox(height: 24), 
                  const RecentSchoolsSection(),
                  const SizedBox(height: 24), 
                  const RecentUsersSection(),
                  const SizedBox(height: 24), 
                  const SectionTitle('Approval Request'),
                  const ApprovalRequestSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}