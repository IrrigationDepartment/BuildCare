import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore avashyae badge ekata

import 'dashboard_service.dart';
import 'dashboard_widgets.dart';
import 'profile.dart'; 
import 'settings.dart'; 
import 'notifications.dart'; 

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

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = index);
      _fetchData(); 
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                  // Header with Notification Badge
                  Stack(
                    children: [
                      DashboardHeader(userData: widget.userData),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: StreamBuilder<QuerySnapshot>(
                          // IsRead false notification pamanak count kirima
                          stream: FirebaseFirestore.instance
                              .collection('notifications')
                              .where('isRead', isEqualTo: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int unreadCount = 0;
                            if (snapshot.hasData) {
                              unreadCount = snapshot.data!.docs.length;
                            }

                            return Badge(
                              label: Text(unreadCount.toString()),
                              isLabelVisible: unreadCount > 0, // Count eka 0 nam badge eka pennanne na
                              backgroundColor: Colors.red,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.notifications_active_outlined, 
                                  color: Colors.black87, 
                                  size: 26,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationPage(),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
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