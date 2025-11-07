import 'package:flutter/material.dart';

class ViewDamageDetailsPage extends StatelessWidget {
  const ViewDamageDetailsPage({super.key});

  // Define consistent colors
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _secondaryYellow = Color(0xFFFFC107); // Used for Edit button
  static const Color _backgroundColor = Color(0xFFF0F2F5);

  // Sample data for the Damage Details list
  final List<Map<String, String>> damageReports = const [
    {
      'school': 'G/Rippon Girls\' Collage',
      'details': 'Roof leakage in science lab.',
      'date': '2025/10/20',
      'status': 'Pending TO review',
    },
    {
      'school': 'Ambalangoda Central College',
      'details': 'Damaged boundary wall section.',
      'date': '2025/10/15',
      'status': 'Work in progress',
    },
    {
      'school': 'Galle Vidyalaya',
      'details': 'Electrical short circuit in library.',
      'date': '2025/10/01',
      'status': 'Completed',
    },
    {
      'school': 'Baddegama National School',
      'details': 'Floor damage in main hall.',
      'date': '2025/09/28',
      'status': 'Pending funding',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'View Damage Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar for Damage Reports
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),
            
            // Damage Report List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: damageReports.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final report = damageReports[index];
                  return _buildDamageTile(
                    context, 
                    report['school']!,
                    report['details']!,
                    report['date']!,
                    report['status']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Consistent Bottom Navigation Bar styling (as seen in previous images)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
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
        currentIndex: 1, // Profile (person) is selected
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
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
          hintText: 'Search Damage Reports..........',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Helper function to get status color
  Color _getStatusColor(String status) {
    if (status.contains('Pending')) {
      return Colors.orange;
    } else if (status.contains('progress')) {
      return _primaryBlue;
    } else if (status.contains('Completed')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  // Helper widget for a single damage report tile
  Widget _buildDamageTile(
      BuildContext context, String school, String details, String date, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for Title and Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              
              // Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          
          // Separator
          const Divider(height: 16),
          
          // Row for Date and Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reported: $date',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              Row(
                children: [
                  // 1. VIEW Button (Blue)
                  _buildActionButton(
                    context, 
                    'View', 
                    Icons.remove_red_eye, 
                    _primaryBlue,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing Report for: $school')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // 2. EDIT Button (Yellow)
                  _buildActionButton(
                    context, 
                    'Edit', 
                    Icons.edit, 
                    _secondaryYellow,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Editing Report for: $school')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for a consistent action button style
  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}