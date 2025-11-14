// settings.dart

import 'package:flutter/material.dart';

//  NEW AND CORRECT IMPORT: To navigate to LoginPage located in the login.dart file
import 'package:buildcare/login.dart'; 

// ----------------------------------------------------------------------------
// --- Settings Page Screen ---
// ----------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Helper function for the Log Out action
  void _performLogout(BuildContext context) {
    // 1. (Optional) Perform Firebase/backend sign out here 
   

    // 2. Navigate to the main LoginPage and clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        // Assuming 'LoginPage' is the name of the main class located in the login.dart file
        builder: (context) => const LoginPage(), 
      ),
      (Route<dynamic> route) => false, // Clears all previous screens from the navigation stack
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. App Bar 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // Back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // Navigate back to the Dashboard
            Navigator.pop(context);
          },
        ),
        // Title
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // Save button
        actions: [
          TextButton(
            onPressed: () {
              // Action when the Save button is clicked
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings Saved (Placeholder)')),
              );
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),

      // 2. Body
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Account Section ---
          const _SectionHeader(title: 'Account'),
          _SettingsItem(
            title: 'Change Password',
            icon: Icons.lock_outline,
            onTap: () {
              // Action for "Change Password" click
            },
          ),
          
          const SizedBox(height: 20),

          // --- Support Section ---
          const _SectionHeader(title: 'Support'),
          _SettingsItem(
            title: 'Developer Team',
            icon: Icons.groups_outlined,
            onTap: () {
              // Action for "Developer Team" click
            },
          ),
          _SettingsItem(
            title: 'Privacy Policy',
            icon: Icons.policy_outlined,
            onTap: () {
              // Action for "Privacy Policy" click
            },
          ),
          
          const SizedBox(height: 30),
          
          // LOG OUT BUTTON (Updated Navigation to login.dart)
          _SettingsItem(
            title: 'Log Out',
            icon: Icons.logout,
            iconColor: Colors.red.shade700,
            textColor: Colors.red.shade700,
            onTap: () {
              // Call the logout function which navigates to LoginPage
              _performLogout(context); 
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// --- Helper Widget: _SectionHeader (Used in SettingsPage) ---
// ----------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// --- Helper Widget: _SettingsItem (Fixed to support icon and color parameters) ---
// ----------------------------------------------------------------------------
class _SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;

  // Constructor now includes the optional parameters to match usage above.
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }
}