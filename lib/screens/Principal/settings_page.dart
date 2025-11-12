import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Primary color matching the app theme (used for icons, save button outline)
  static const Color _primaryColor = Color(0xFF53BDFF);
  // Red color for the Log out button
  static const Color _redColor = Color(0xFFF44336); 
  // Background color for the list items
  static const Color _cardColor = Colors.white;
  // Background color for the page body (Light grey)
  static const Color _backgroundColor = Color(0xFFF5F5F5); 

  // --- Helper function to show a confirmation dialog or action status ---
  void _showMessage(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            }
          )
        ],
      ),
    );
  }

  // --- Reusable Setting List Tile Widget (Card Style) ---
  Widget _buildSettingItem(
      BuildContext context, String title, VoidCallback onTap,
      {Color textColor = Colors.black87,
      Color iconColor = Colors.grey,
      bool showChevron = true}) {
    return Container(
      // Padding around items in the list to separate them visually
      margin: const EdgeInsets.only(bottom: 10), 
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10), 
        boxShadow: [
          // Subtle shadow to lift the card
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor),
                ),
                // Chevron icon on the right
                if (showChevron)
                  Icon(Icons.chevron_right, color: iconColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Section Title Widget (Account, Support) ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 25, 0, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // --- Log out Button Widget ---
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () {
            // Implement your logout logic here (e.g., clear session, navigate to login)
            _showMessage(context, 'Log Out', 'Logging out...');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _redColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Log out',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        // Back Button (Standard arrow icon, black color)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // --- Save Button (Outline Button with Blue Border) ---
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: () {
                // Action for saving settings
                _showMessage(context, 'Save', 'Settings saved successfully.');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor, // Text color
                side: const BorderSide(color: _primaryColor, width: 2), // Outline color and width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(60, 35), // Define minimum size
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Account Section ---
            _buildSectionTitle('Account'),
            _buildSettingItem(
              context,
              'Change Password',
              () {
                _showMessage(context, 'Action', 'Change Password screen coming soon.');
              },
            ),

            // --- Support Section ---
            _buildSectionTitle('Support'),
            _buildSettingItem(
              context,
              'Developer Team',
              () {
                _showMessage(context, 'Action', 'Navigating to Developer Team info.');
              },
            ),
            _buildSettingItem(
              context,
              'Report a Problem',
              () {
                _showMessage(context, 'Action', 'Opening Report a Problem form.');
              },
            ),
            _buildSettingItem(
              context,
              'Privacy Policy',
              () {
                _showMessage(context, 'Action', 'Viewing Privacy Policy.');
              },
            ),

            // --- Log out Button ---
            _buildLogoutButton(context),
            
            const SizedBox(height: 20), // Extra space above bottom bar
          ],
        ),
      ),
      // --- UPDATED Bottom Navigation Bar ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, 
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed, 
        // CHANGED: Set background color to White and added elevation for distinction
        backgroundColor: Colors.white, 
        elevation: 5, 
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 30),
              activeIcon: Icon(Icons.home, size: 30),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 30),
              activeIcon: Icon(Icons.person, size: 30),
              label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 30),
              activeIcon: Icon(Icons.settings, size: 30),
              label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigate back to the Dashboard/Home page
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            // Placeholder for navigating to Profile page
             _showMessage(context, 'Navigation', 'Navigating to Profile Page.');
          }
          // index 2 is Settings, do nothing since we are on this page
        },
      ),
    );
  }
}