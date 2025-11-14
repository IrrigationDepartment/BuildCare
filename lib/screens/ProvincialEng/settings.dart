// settings.dart
import 'package:flutter/material.dart';
// 💡 අලුතින් එකතු කළ import එක (signup.dart file එකේ ඇති class එක භාවිත කිරීමට)
import 'signup.dart'; 

// -----------------------------------------------------------------------------
// --- Settings Page Screen ---
// -----------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
            onTap: () {
              // Action for "Change Password" click
            },
          ),
          const SizedBox(height: 20),

          // --- Support Section ---
          const _SectionHeader(title: 'Support'),
          _SettingsItem(
            title: 'Developer Team',
            onTap: () {
              // Action for "Developer Team" click
            },
          ),
          _SettingsItem(
            title: 'Report a Problem',
            onTap: () {
              // Action for "Report a Problem" click
            },
          ),
          _SettingsItem(
            title: 'Privacy Policy',
            onTap: () {
              // Action for "Privacy Policy" click
            },
          ),
          const SizedBox(height: 40),

          // 🚀 --- Log out Button (UPDATED LOGIC) --- 🚀
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Log out logic: Navigate to ProvincialEngRegistrationPage 
                // and remove all previous routes (Dashboard, etc.)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    // 🚨 Note: The Sign Up class in your file is ProvincialEngRegistrationPage
                    builder: (context) => const ProvincialEngRegistrationPage(), 
                  ),
                  (Route<dynamic> route) => false, // Remove all previous screens from the stack
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), // Red color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Log out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20), // Added some spacing
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- Helper Widget: _SectionHeader (Used in SettingsPage) ---
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// --- Helper Widget: _SettingsItem (Used in SettingsPage) ---
// -----------------------------------------------------------------------------
class _SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({required this.title, required this.onTap});

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
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}