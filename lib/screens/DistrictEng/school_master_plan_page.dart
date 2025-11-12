import 'package:flutter/material.dart';

class SchoolMasterPlanPage extends StatelessWidget {
  const SchoolMasterPlanPage({super.key});

  // Define consistent colors
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _backgroundColor = Color(0xFFF0F2F5);

  // Sample data for the Master Plan list
  final List<Map<String, String>> masterPlans = const [
    // I've added a dummy image path here. You should replace 'assets/master_plan_image.jpg'
    // with the actual path to your image asset or a network image URL.
    {
      'title': 'Master Plan 2020-2025',
      'school': 'G/Rippon Girls\' Collage',
      'updated': '2024/05/12',
      'size': '5.4MB',
      'image_path': 'assets/master_plan_image.jpg', // Placeholder image path
    },
    {
      'title': 'Master Plan 2020-2025',
      'school': 'G/Rippon Girls\' Collage',
      'updated': '2024/05/12',
      'size': '5.4MB',
      'image_path': 'assets/master_plan_image.jpg',
    },
    {
      'title': 'Master Plan 2020-2025',
      'school': 'G/Rippon Girls\' Collage',
      'updated': '2024/05/12',
      'size': '5.4MB',
      'image_path': 'assets/master_plan_image.jpg',
    },
    {
      'title': 'Master Plan 2020-2025',
      'school': 'G/Rippon Girls\' Collage',
      'updated': '2024/05/12',
      'size': '5.4MB',
      'image_path': 'assets/master_plan_image.jpg',
    },
    // You can add more data here
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
          'School Master Plan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),

            // Master Plan List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: masterPlans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final plan = masterPlans[index];
                  // Pass the whole plan map to the tile
                  return _buildPlanTile(context, plan);
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
        currentIndex: 1, // Profile (person) is selected in the image
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
  
  // --- NEW FUNCTION: Show Master Plan Dialog ---
  void _showMasterPlanDialog(BuildContext context, String title, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // We use Dialog for a custom shape and content
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Rounded corners for the dialog
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header Row (Title and Close Button)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'View Master Plan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.grey, size: 24), // 'x' close button
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Master Plan Image
                // NOTE: Using Image.asset requires you to have the image in your assets folder
                // and updated pubspec.yaml. For a real app, you might use Image.network().
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      height: MediaQuery.of(context).size.height * 0.5, // Take up half of screen height
                      // For demonstration, use a placeholder if the asset isn't available
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: Text(
                              'Image for Master Plan not found at:\n$imagePath',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Optional: Master Plan Title/Details
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          hintText: 'Search Master Plan..........',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Helper widget for a single master plan document tile (UPDATED to accept map)
  Widget _buildPlanTile(BuildContext context, Map<String, String> plan) {
    final String title = plan['title']!;
    final String school = plan['school']!;
    final String updated = plan['updated']!;
    final String size = plan['size']!;
    final String imagePath = plan['image_path']!; // Get the image path

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  school,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Updated Date: $updated\nPDF ($size)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // View Button
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // *** ACTION: Call the dialog function here ***
                  _showMasterPlanDialog(context, title, imagePath);
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(100, 35),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              const SizedBox(height: 8),
              // Download Button
              ElevatedButton.icon(
                onPressed: () {
                  // Action for Download
                },
                icon: const Icon(Icons.download, size: 18, color: Colors.black54),
                label: const Text('Download', style: TextStyle(color: Colors.black54)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F0F0),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(100, 35),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}