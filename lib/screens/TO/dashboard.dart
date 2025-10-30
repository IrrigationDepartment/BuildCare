import 'package:flutter/material.dart';

// --- STUB SCREENS (Required for Navigation to Compile) ---
// You should replace these stubs with your actual screen files.
class ManageSchoolScreen extends StatelessWidget {
  const ManageSchoolScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Manage School')), body: const Center(child: Text('Manage School Content')));
  }
}
class IssueReportScreen extends StatelessWidget {
  const IssueReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Issues Report')), body: const Center(child: Text('Issues Report Content')));
  }
}
class ContractDetailsScreen extends StatelessWidget {
  const ContractDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Contract Details')), body: const Center(child: Text('Contract Details Content')));
  }
}
class ContractorDetailsScreen extends StatelessWidget {
  const ContractorDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Contractor Details')), body: const Center(child: Text('Contractor Details Content')));
  }
}
// --------------------------------------------------------

class HomeScreen extends StatelessWidget {
  // Color constants based on the screenshot
  static const Color darkBackgroundColor = Color(0xFF333333); // Main dark background
  static const Color lightCardColor = Color(0xFFE0E0E0);      // Grid button background
  static const Color blueAccent = Color(0xFF37B5FA);           // Blue accent color

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The main body is contained within a Stack to place the bottom navigation bar
      // exactly as a floating element over the content.
      body: Stack(
        children: [
          // 1. Scrollable Content (Header, Grid, Activity)
          Container(
            color: darkBackgroundColor, // Set the dark background for the whole screen area
            child: SafeArea(
              bottom: false, // Ensure content can flow behind the bottom nav bar
              child: SingleChildScrollView(
                // Add padding, reserving space for the bottom bar at the end
                padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 100.0), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header Title ---
                    /* const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'TO dashboard sample',
                        style: TextStyle(
                          color: Color(0xFFC7C7C7), // Light grey
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    */

                    // --- Welcome Section (Custom Card Look) ---
                    // This section uses the dark background, but we simulate the card look
                    // by adding padding and the specific color for the content inside.
                    Row(
                      children: [
                        // Profile Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: blueAccent,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 60),
                        ),
                        const SizedBox(width: 20),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome !',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Technical Officer',
                              style: TextStyle(
                                color: Color(0xFFC7C7C7),
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
                          icon: Icons.business, // Closest icon to Manage School in screenshot
                          label: 'Manage School',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSchoolScreen()));
                          },
                        ),
                        _buildGridButton(
                          context,
                          icon: Icons.settings_applications, // Closest icon to Issues Report in screenshot
                          label: 'Issues Report',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const IssueReportScreen()));
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
                          icon: Icons.edit_note, // Closest icon to Contract Details in screenshot
                          label: 'Contract Details',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractDetailsScreen()));
                          },
                        ),
                        _buildGridButton(
                          context,
                          icon: Icons.work, // Closest icon to Contractor Details in screenshot
                          label: 'Contractor Details',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractorDetailsScreen()));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // --- Recent Activity Section Header ---
                    const Row(
                      children: [
                        Icon(Icons.history, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Activity Items ---
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
          ),
          
          // 2. Floating Bottom Navigation Bar (Footer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavBar(context),
          ),
        ],
      ),
    );
  }

  // Helper widget for the 4 grid buttons
  Widget _buildGridButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    // Calculate width to ensure two buttons fit with padding/spacing
    double width = (MediaQuery.of(context).size.width - 60) / 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: width * 0.78, // Adjusted height for better visual match
        decoration: BoxDecoration(
          color: Colors.white, // Button background color in screenshot
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: darkBackgroundColor.withOpacity(0.7), size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkBackgroundColor,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.home_work_outlined, size: 36, color: darkBackgroundColor),
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
                    color: darkBackgroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // View Details button
          SizedBox(
            height: 35,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: blueAccent, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View Details',
                style: TextStyle(color: blueAccent, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper widget for the bottom navigation bar
  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 70 + MediaQuery.of(context).padding.bottom, // Add bottom padding for safe area
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25), // Rounded corners
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Button (Active/Blue)
          IconButton(
            icon: const Icon(Icons.home, color: blueAccent, size: 30),
            onPressed: () {},
          ),
          // Person Button
          IconButton(
            icon: const Icon(Icons.person_outline, color: darkBackgroundColor, size: 30),
            onPressed: () {},
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: darkBackgroundColor, size: 30),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}