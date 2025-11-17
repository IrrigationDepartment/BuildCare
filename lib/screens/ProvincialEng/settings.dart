// settings.dart

import 'package:flutter/material.dart';

// NEW IMPORT: To navigate to LoginPage located in the login.dart file
// Note: Please ensure 'package:buildcare/login.dart' is the correct path/name.
import 'package:buildcare/login.dart'; 

// NEW IMPORT: To use CustomBottomNavBar from dashboard.dart
import 'dashboard.dart'; 

// ----------------------------------------------------------------------------
// --- Settings Page Screen (Main Content) ---
// ----------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Helper function for the Log Out action
  void _performLogout(BuildContext context) {
    // 1. (Optional) Perform Firebase/backend sign out here 
    // Example: await FirebaseAuth.instance.signOut();

    // 2. Navigate to the main LoginPage and clear the navigation stack
    // (Ensure you have a LoginPage class in login.dart file)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(), 
      ),
      (Route<dynamic> route) => false, // Clears all previous screens
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. App Bar 
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 1,
        // No back button needed if navigating from Bottom Nav Bar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Account Settings Section ---
            const _SectionHeader(title: 'Account'),
            _SettingsItem(
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to Edit Profile Page (Implement this page later)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Edit Profile...')),
                );
              },
              icon: Icons.person_outline,
            ),
            _SettingsItem(
              title: 'Change Password',
              onTap: () {
                // TODO: Navigate to Change Password Page (Implement this page later)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Change Password...')),
                );
              },
              icon: Icons.lock_outline,
            ),

            const SizedBox(height: 20),

            // --- General Settings Section ---
            const _SectionHeader(title: 'General'),
            _SettingsItem(
              title: 'Notifications',
              onTap: () {
                // TODO: Navigate to Notification Settings (Implement this page later)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Notifications...')),
                );
              },
              icon: Icons.notifications_none,
            ),
            _SettingsItem(
              title: 'Help & Support',
              onTap: () {
                // TODO: Navigate to Help/Support Page (Implement this page later)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Help & Support...')),
                );
              },
              icon: Icons.help_outline,
            ),
            
            const SizedBox(height: 30),

            // --- Logout Button (Functional) ---
            _SettingsItem(
              title: 'Log Out',
              onTap: () => _performLogout(context), // 🚀 Calls the functional Log Out method
              icon: Icons.logout,
              iconColor: Colors.red.shade600,
              textColor: Colors.red.shade600,
            ),
          ],
        ),
      ),
      // 2. Bottom Navigation Bar (Set currentIndex to 2 for Settings)
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2), 
    );
  }
}

// ----------------------------------------------------------------------------
// --- Helper Widget: _SectionHeader (Used in SettingsPage) ---
// ----------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 10.0, 4.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade800,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// --- Helper Widget: _SettingsItem (Used in SettingsPage) ---
// ----------------------------------------------------------------------------
class _SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsItem({
    super.key, 
    required this.title, 
    required this.onTap, 
    this.icon,
    this.iconColor,
    this.textColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: icon != null
            ? Icon(icon, color: iconColor ?? Colors.black87)
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}