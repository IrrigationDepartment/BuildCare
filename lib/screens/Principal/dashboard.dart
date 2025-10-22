import 'package:flutter/material.dart';

class PrincipalDashboard extends StatelessWidget {
  final Map<String, dynamic>? userData; // Make userData nullable

  const PrincipalDashboard({super.key, required this.userData});

  static const Color _primaryColor = Color(0xFF53BDFF);

  @override
  Widget build(BuildContext context) {
    // --- FIX: Check if userData is valid before building the UI ---
    if (userData == null || userData!['name'] == null) {
      // If data is missing, show an error/loading screen instead of crashing.
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 16),
              Text(
                'Could not load user data.',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // If data is valid, build the dashboard.
    final String principalName = userData!['name'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: null, // No AppBar in the design
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildWelcomeHeader(principalName),
                const SizedBox(height: 30),
                _buildActionButton(
                  icon: Icons.add,
                  text: 'Add Your School Details',
                  onTap: () {},
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  icon: Icons.build_outlined,
                  text: 'Add Building Issues',
                  onTap: () {},
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  icon: Icons.map_outlined,
                  text: 'Manage Master Plans',
                  onTap: () {},
                ),
                const SizedBox(height: 30),
                _buildReportedIssuesSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 30), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 30), label: 'Settings'),
        ],
      ),
    );
  }

  // --- All the helper widgets from before remain the same ---

  Widget _buildWelcomeHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: _primaryColor,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Icon(icon, size: 30, color: _primaryColor),
                ),
                const SizedBox(width: 20),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportedIssuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'My Reported Issues',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 15),
        _buildIssueCard(
          title: 'Thurstan Collage - Damaged Roof',
          status: 'Colombo - Status, Pending Review',
          date: '2025-09-09',
        ),
        _buildIssueCard(
          title: 'Thurstan Collage - Damaged Roof',
          status: 'Colombo - Status, Pending Review',
          date: '2025-09-09',
        ),
      ],
    );
  }

  Widget _buildIssueCard(
      {required String title, required String status, required String date}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: Colors.grey.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.home_work_outlined, size: 40, color: Colors.grey[700]),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  Text(
                    date,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primaryColor),
                foregroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('View Details', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}