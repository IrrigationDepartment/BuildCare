import 'package:flutter/material.dart';

class ViewContractDetailsPage extends StatelessWidget {
  const ViewContractDetailsPage({super.key});

  // Define consistent colors
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _secondaryGreen = Color(0xFF4CAF50); // Used for Download button/Completed status
  static const Color _backgroundColor = Color(0xFFF0F2F5);

  // Sample data for the Contract Details list
  final List<Map<String, String>> contractReports = const [
    {
      'title': 'G/Rippon Girls\' - New Block Construction',
      'contractor': 'ABC Construction (Pvt) Ltd',
      'value': 'Rs. 45 Million',
      'status': 'Work in progress',
      'updated_date': '2025/11/01',
    },
    {
      'title': 'Ambalangoda Central - Boundary Wall Repair',
      'contractor': 'Saman & Sons Engineers',
      'value': 'Rs. 2.5 Million',
      'status': 'Completed',
      'updated_date': '2025/10/25',
    },
    {
      'title': 'Galle Vidyalaya - Electrical Upgrades',
      'contractor': 'Electric Solutions Co.',
      'value': 'Rs. 1.8 Million',
      'status': 'Pending Approval',
      'updated_date': '2025/10/01',
    },
    {
      'title': 'Baddegama National - Main Hall Ceiling',
      'contractor': 'K.L. Builders',
      'value': 'Rs. 5 Million',
      'status': 'Work in progress',
      'updated_date': '2025/09/10',
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
          'View Contract Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar for Contracts
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),
            
            // Contract List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: contractReports.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final report = contractReports[index];
                  return _buildContractTile(
                    context, 
                    report['title']!,
                    report['contractor']!,
                    report['value']!,
                    report['status']!,
                    report['updated_date']!,
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
          hintText: 'Search Contracts..........',
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
      return _secondaryGreen;
    }
    return Colors.grey;
  }

  // Helper widget for a single contract tile
  Widget _buildContractTile(
      BuildContext context, String title, String contractor, String value, String status, String date) {
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
          // Title and Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
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
          
          // Contractor and Value
          Text(
            'Contractor: $contractor',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            'Value: $value',
            style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          
          const Divider(height: 20),
          
          // Action Buttons and Update Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Update: $date',
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
                    Icons.visibility, 
                    _primaryBlue,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing full contract: $title')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // 2. DOWNLOAD Button (Green)
                  _buildActionButton(
                    context, 
                    'Download', 
                    Icons.file_download, 
                    _secondaryGreen,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading contract: $title')),
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