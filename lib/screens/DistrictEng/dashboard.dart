import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
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
  
  int _totalSchools = 0;
  int _totalTOs = 0;
  int _totalPrincipals = 0;
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
          _totalTOs = counts.totalTOs; 
          _totalPrincipals = counts.totalPrincipals; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
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
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    Widget mainContent = SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF1E3A8A),
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 32),
              
              DashboardOverview(
                isLoading: _isLoading,
                totalSchools: _totalSchools,
                totalTOs: _totalTOs,
                totalPrincipals: _totalPrincipals,
                userNic: userNic, 
              ),
              const SizedBox(height: 28),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(flex: 5, child: RecentIssuesSection()),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: const [
                              RecentSchoolsSection(),
                              SizedBox(height: 24),
                              RecentUsersSection(),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Column(
                      children: [
                        RecentIssuesSection(),
                        SizedBox(height: 24),
                        RecentSchoolsSection(),
                        SizedBox(height: 24),
                        RecentUsersSection(),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24), 
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), 
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  elevation: 5,
                  useIndicator: true,
                  indicatorColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                  selectedIconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
                  unselectedIconTheme: IconThemeData(color: Colors.grey.shade500),
                  selectedLabelTextStyle: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profile')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Settings')),
                  ],
                ),
                Expanded(child: mainContent),
              ],
            )
          : mainContent,
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              elevation: 12,
              backgroundColor: Colors.white,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: const Color(0xFF1E3A8A),
              unselectedItemColor: Colors.grey.shade400,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              onTap: _onItemTapped,
            ),
    );
  }

  Widget _buildTopHeader() {
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    final DateTime? userCreationTime = currentUser?.metadata.creationTime;

    Query query = FirebaseFirestore.instance.collection('notifications');
    if (userCreationTime != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(userCreationTime));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: DashboardHeader(userData: widget.userData)),
        const SizedBox(width: 16),
        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            
            if (snapshot.hasData) {

              unreadCount = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final readBy = data['readBy'] as List<dynamic>? ?? [];
                return !readBy.contains(currentUserId);
              }).length;
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Badge(
                label: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                isLabelVisible: unreadCount > 0, 
                backgroundColor: const Color(0xFFE11D48), 
                offset: const Offset(-4, 4),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E3A8A), size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationPage()),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}