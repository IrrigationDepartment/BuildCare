import 'package:flutter/material.dart';

class ManageTechnicalOfficersPage extends StatelessWidget {
  const ManageTechnicalOfficersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background color matches the dashboard's light grey
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        // Transparent app bar to blend with the background, only showing the back button
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // Navigate back
        ),
        title: const Text(
          'Manage Technical Officers',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildManagementOptions(context),
            ],
          ),
        ),
      ),
      // Use the same Bottom Navigation Bar as the dashboard for consistency
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
        // The current index is 1 because the second icon (person) is highlighted in the image
        currentIndex: 1, 
        selectedItemColor: Colors.blueAccent,
        // onTap: (index) { /* TODO: Implement navigation for other tabs */ },
      ),
    );
  }

  // Helper widget to build the stats grid (Total TOs, Pending, Active, Schools)
  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard('Total TOs', '25', Icons.group, Colors.blue),
            _buildStatCard('Pending', '5', Icons.access_time, Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard('Active TOs', '20', Icons.group_add, Colors.green),
            _buildStatCard('Schools', '150', Icons.school, Colors.teal),
          ],
        ),
      ],
    );
  }

  // Helper widget for a single stat card in the grid
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  count,
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: color),
                ),
                Icon(icon, size: 40, color: color.withOpacity(0.6)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search TOs.......',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  // Helper widget to build the three main management option tiles
  Widget _buildManagementOptions(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(
            context, 'View School Master Plan', Icons.description_outlined),
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 'View Damage Details', Icons.dangerous_outlined),
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 'View Contract Details', Icons.edit_document),
      ],
    );
  }

  // Helper widget for a single option tile (Master Plan, Damage Details, Contract Details)
  Widget _buildOptionTile(
      BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        // TODO: Implement navigation or action for each option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped: $title')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Icon(icon, size: 28, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}