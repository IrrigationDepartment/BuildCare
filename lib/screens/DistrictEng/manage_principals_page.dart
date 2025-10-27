import 'package:flutter/material.dart';

class ManagePrincipalsPage extends StatelessWidget {
  const ManagePrincipalsPage({super.key});

  // Define the consistent light blue color from the image
  static const Color _cardColor = Color(0xFFE3F2FD); // A very light, gentle blue for the cards
  static const Color _primaryBlue = Color(0xFF1E88E5); // A standard blue for icons/text
  static const Color _backgroundColor = Color(0xFFF0F2F5); // The light grey background

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background color matches the dashboard's light grey
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        // Transparent app bar to blend with the background
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // Navigate back
        ),
        title: const Text(
          'Manage Principals',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              // The management options in the image are a bit brighter white, so we'll use white
              _buildManagementOptions(context),
            ],
          ),
        ),
      ),
      // Consistent Bottom Navigation Bar as seen in the image
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
        // The current index is 1 (person icon)
        currentIndex: 1, 
        selectedItemColor: _primaryBlue, // The highlighted icon is blue
        unselectedItemColor: Colors.grey, // Non-selected icons are grey
        showSelectedLabels: false, // The image doesn't show labels
        showUnselectedLabels: false,
        backgroundColor: Colors.white, // Assuming a white background for the bar
        type: BottomNavigationBarType.fixed, // To show all icons clearly
      ),
    );
  }
  
  //---

  // Helper widget to build the stats grid (Total Principals, Pending, Active, Schools)
  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total Principals - Group Icon
            _buildStatCard('Total Principals', '25', Icons.group, _cardColor, _primaryBlue),
            // Pending - Person with Clock Icon
            _buildStatCard('Pending', '5', Icons.person_add_outlined, _cardColor, _primaryBlue),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Active Principals - Group with 'Add' Icon (or similar)
            _buildStatCard('Active Principals', '20', Icons.group_add_outlined, _cardColor, _primaryBlue),
            // Schools - School/Building Icon
            _buildStatCard('Schools', '150', Icons.apartment_outlined, _cardColor, _primaryBlue),
          ],
        ),
      ],
    );
  }

  //---
  
  // Helper widget for a single stat card in the grid
  Widget _buildStatCard(String title, String count, IconData icon, Color cardColor, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        height: 120, // Give it a fixed height for consistent look
        decoration: BoxDecoration(
          color: cardColor, // Use the light blue color
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Very subtle shadow
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Icon(icon, size: 36, color: iconColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  //---

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
          hintText: 'Search Principals.......', 
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
  
  //---

  // Helper widget to build the three main management option tiles
  Widget _buildManagementOptions(BuildContext context) {
    // The icons in the image are a document icon, an eye/damage icon, and a pencil/contract icon
    return Column(
      children: [
        _buildOptionTile(
            context, 'View School Master Plan', Icons.description_outlined),
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 'View Damage Details', Icons.remove_red_eye_outlined), // Changed to an eye icon for "View"
        const SizedBox(height: 16),
        _buildOptionTile(
            context, 'View Contract Details', Icons.edit_note_outlined), // Changed to a pencil/edit icon
      ],
    );
  }

  //---

  // Helper widget for a single option tile
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white, // White background for the tiles
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            Icon(icon, size: 28, color: _primaryBlue),
          ],
        ),
      ),
    );
  }
}