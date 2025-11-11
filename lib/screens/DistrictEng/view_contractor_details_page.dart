import 'package:flutter/material.dart';

class ViewContractorDetailsPage extends StatelessWidget {
  const ViewContractorDetailsPage({super.key});

  // Define consistent colors
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _secondaryYellow = Color(0xFFFFC107); 
  static const Color _backgroundColor = Color(0xFFF0F2F5);

  // Sample data for the Contractor Details list
  final List<Map<String, String>> contractors = const [
    {
      'name': 'ABC Construction (Pvt) Ltd',
      'contact': '091-2234567',
      'email': 'abc@lanka.com',
      'specialization': 'General Building',
      'status': 'Active',
    },
    {
      'name': 'Saman & Sons Engineers',
      'contact': '077-1234567',
      'email': 'saman@eng.lk',
      'specialization': 'Civil/Roads',
      'status': 'Active',
    },
    {
      'name': 'Electric Solutions Co.',
      'contact': '011-5551234',
      'email': 'electric@sol.lk',
      'specialization': 'Electrical Works',
      'status': 'Under Review',
    },
    {
      'name': 'K.L. Builders',
      'contact': '071-9876543',
      'email': 'klbuild@yahoo.com',
      'specialization': 'Roofing/Ceilings',
      'status': 'Active',
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
          'Contractor Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar for Contractors
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),
            
            // Contractor List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: contractors.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final contractor = contractors[index];
                  return _buildContractorTile(
                    context, 
                    contractor['name']!,
                    contractor['specialization']!,
                    contractor['contact']!,
                    contractor['status']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Consistent Bottom Navigation Bar styling
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
          hintText: 'Search Contractors..........',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Helper function to get status color
  Color _getStatusColor(String status) {
    if (status.contains('Review')) {
      return Colors.orange;
    } else if (status.contains('Active')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  // Helper widget for a single contractor tile
  Widget _buildContractorTile(
      BuildContext context, String name, String specialization, String contact, String status) {
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
          // Name and Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
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
          const SizedBox(height: 8),
          
          // Details
          Text(
            'Specialization: $specialization',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact: $contact',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          
          const Divider(height: 20),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 1. VIEW Button (Blue)
              _buildActionButton(
                context, 
                'View', 
                Icons.visibility, 
                _primaryBlue,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing profile for: $name')),
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
                    SnackBar(content: Text('Editing profile for: $name')),
                  );
                },
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