import 'package:flutter/material.dart';

// --- VISUAL CONSTANTS (Based on image analysis) ---
const _kPrimaryBlue = Color(0xFF2196F3); // Standard Material Blue 500
const _kBackgroundColor = Color(0xFFEFEFEF); // Very light gray background
const _kHeaderBackgroundColor = Color(0xFFDCDCDC); // Light gray background for header
const _kDarkTextColor = Color(0xFF333333);
const _kMediumGrayColor = Color(0xFF777777);

// Mock data for populating the Recent Activity list
const _mockActivities = [
  {
    'title': 'Thurstan Collage - Damaged Roof',
    'subtitle': 'Colombo - Status, Pending Review',
  },
  {
    'title': 'Christ Church Baddegama - Damaged Roof',
    'subtitle': 'Galle - Status, Pending Review',
  },
];

// --- DASHBOARD BUTTON WIDGET ---
class _DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _DashboardButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      // Matches the soft shadow appearance in the image
      elevation: 6,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: iconColor,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // Semi-bold/bold weight
                  color: _kDarkTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- RECENT ACTIVITY ITEM WIDGET ---
class _RecentActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDetailsTap;

  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Building Icon Container (Light gray background)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5), // Lighter gray for icon background
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: Color(0xFF666666),
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700, // Bold
                    fontSize: 15,
                    color: _kDarkTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kMediumGrayColor,
                    fontWeight: FontWeight.w400, // Regular
                  ),
                ),
              ],
            ),
          ),
          // View Details Button
          TextButton(
            onPressed: onDetailsTap,
            style: TextButton.styleFrom(
              minimumSize: Size.zero, // Remove default padding constraints
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              backgroundColor: _kPrimaryBlue.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'View Details',
              style: TextStyle(
                color: _kPrimaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM BOTTOM NAVIGATION BAR WIDGET ---
class _CustomBottomNavigationBar extends StatelessWidget {
  final Color primaryColor;

  const _CustomBottomNavigationBar({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Fixed height for visual consistency
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Home (Selected)
          IconButton(
            icon: Icon(Icons.home_outlined, size: 30, color: primaryColor),
            onPressed: () => print('Home tapped'),
          ),
          // Profile
          IconButton(
            icon: Icon(Icons.person_outline, size: 30, color: Colors.grey.shade600),
            onPressed: () => print('Profile tapped'),
          ),
          // Settings
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 30, color: Colors.grey.shade600),
            onPressed: () => print('Settings tapped'),
          ),
        ],
      ),
    );
  }
}

// --- MAIN DASHBOARD WIDGET ---
class TODashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const TODashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Safely extract user type, defaulting to 'Technical Officer' as seen in the image
    final String userType = userData['userType'] ?? 'Technical Officer';

    // The main content uses a padding value of 25.0, but the header card itself needs 
    // to match the width and be padded internally.

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Profile Header Section (New Container for the "Card" effect) ---
            Container(
              margin: const EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0, bottom: 30.0),
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
              decoration: BoxDecoration(
                color: Colors.white, // Changed from _kHeaderBackgroundColor to white for better contrast as seen in the full image
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFCCCCCC), // Faint outline color
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Icon Container (Large circle with light blue gradient effect)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Mimics the subtle blue gradient/shading seen in the image
                      gradient: LinearGradient(
                        colors: [
                          _kPrimaryBlue.withOpacity(0.9),
                          _kPrimaryBlue.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      // Added the very slight gray outline to the icon container itself
                      border: Border.all(
                        color: const Color(0xFFDCDCDC), 
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white, // White icon for better contrast
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Greeting Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome !',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900, // Extra Bold
                          color: _kDarkTextColor,
                        ),
                      ),
                      Text(
                        userType,
                        style: const TextStyle(
                          fontSize: 16,
                          color: _kMediumGrayColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // --- Rest of the Scrollable Content ---
            Expanded(
              child: SingleChildScrollView(
                // Applied horizontal padding only, vertical padding handled by main container's margin
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 2. Action Buttons Grid (2x2) ---
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.0, // Ensures square cards
                      children: [
                        _DashboardButton(
                          icon: Icons.business,
                          label: 'Manage School',
                          iconColor: const Color(0xFF3F51B5), // Indigo
                          onTap: () => print('Manage School tapped'),
                        ),
                        _DashboardButton(
                          icon: Icons.build_circle_outlined, 
                          label: 'Issues Report',
                          iconColor: const Color(0xFF3F51B5), // Red
                          onTap: () => print('Issues Report tapped'),
                        ),
                        _DashboardButton(
                          icon: Icons.edit_document, 
                          label: 'Contract Details',
                          iconColor: const Color(0xFF3F51B5), // Green
                          onTap: () => print('Contract Details tapped'),
                        ),
                        _DashboardButton(
                          icon: Icons.work, 
                          label: 'Contractor Details',
                          iconColor: const Color(0xFF3F51B5), // Orange
                          onTap: () => print('Contractor Details tapped'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- 3. Recent Activity Heading ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            color: _kDarkTextColor,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _kDarkTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- 4. Recent Activity List ---
                    ..._mockActivities.map((activity) {
                      return _RecentActivityItem(
                        title: activity['title']!,
                        subtitle: activity['subtitle']!,
                        onDetailsTap: () => print('Details for ${activity['title']} tapped'),
                      );
                    }).toList(),
                    // Extra padding at the very bottom
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            // --- 5. Custom Bottom Navigation Bar ---
            _CustomBottomNavigationBar(
              primaryColor: _kPrimaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
