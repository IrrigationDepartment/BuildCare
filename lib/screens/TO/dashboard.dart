import 'package:flutter/material.dart';
import 'manage_school_screen.dart';
import 'issue_report_screen.dart';
import 'contract_details_screen.dart';
import 'contractor_details_screen.dart';

// 1. Class name changed to TODashboard to match the LoginPage usage
class TODashboard extends StatelessWidget {
  // 2. Added userData parameter to the constructor
  final Map<String, dynamic> userData;

  const TODashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Safely get the user's name from userData, defaulting to 'Technical Officer'
    final String userName = userData['name'] as String? ?? 'Technical Officer';
    
    return Scaffold(
      backgroundColor: const Color(0xFF333333), // Dark background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Title ---
              const Text(
                'TO dashboard sample',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),

              // --- Welcome Section (Updated to use userName) ---
              Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF37B5FA),
                    child: Icon(Icons.person, color: Colors.white, size: 60),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Display the user's name here
                        'Welcome, $userName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Technical Officer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Grid Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGridButton(
                    context,
                    icon: Icons.school,
                    label: 'Manage School',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ManageSchoolScreen()),
                      );
                    },
                  ),
                  _buildGridButton(
                    context,
                    icon: Icons.build,
                    label: 'Issues Report',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const IssueReportScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGridButton(
                    context,
                    icon: Icons.description,
                    label: 'Contract Details',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ContractDetailsScreen()),
                      );
                    },
                  ),
                  _buildGridButton(
                    context,
                    icon: Icons.business_center,
                    label: 'Contractor Details',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ContractorDetailsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Recent Activity Section ---
              Row(
                children: [
                  Icon(Icons.history, color: Colors.white.withOpacity(0.8), size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildActivityItem(
                title: 'Thurstan Collage - Damaged Roof',
                subtitle: 'Colombo - Status, Pending Review',
              ),
              const SizedBox(height: 15),
              _buildActivityItem(
                title: 'Christ Church Baddegama - Damaged Roof',
                subtitle: 'Galle - Status, Pending Review',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the 4 grid buttons
  Widget _buildGridButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    // Calculate width to be roughly 45% of screen width, minus padding
    double width = (MediaQuery.of(context).size.width - 60) / 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: width * 0.9, // Make it slightly less tall than wide
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF37B5FA), size: 40),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the recent activity list items
  Widget _buildActivityItem({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined, size: 40, color: Color(0xFF555555)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF37B5FA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'View Details',
              style: TextStyle(color: Color(0xFF37B5FA)),
            ),
          ),
        ],
      ),
    );
  }
}