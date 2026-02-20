// settings.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the Forgot Password Flow (parent `screens/` folder)
import '../forgot_password_flow.dart';

class SettingsScreen extends StatefulWidget {
  // Optional: Callback to handle the "Back" arrow if used inside BottomNav
  final VoidCallback? onBackTap;

  const SettingsScreen({super.key, this.onBackTap});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- Styles ---
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kRedColor = Color(0xFFFF5252);
  static const TextStyle kHeaderStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // --- Actions ---

  void _navigateToChangePassword() {
    // Navigate to the existing ForgotPasswordFlow
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordFlow()),
    );
  }

  void _handleLogout() async {
    // 1. Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      // 2. Navigate to Login Screen (Clear stack)
      // Assuming your login route is named '/' or you can pushReplacement
      // Adjust 'LoginScreen()' to your actual login widget class name
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _showPlaceholder(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title clicked (Functionality coming soon)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryBlue),
          onPressed: () {
            // If a callback is provided (from Dashboard), use it.
            // Otherwise pop the navigator.
            if (widget.onBackTap != null) {
              widget.onBackTap!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Save logic (if any)
            },
            child: const Text(
              'Save',
              style: TextStyle(color: kPrimaryBlue, fontSize: 16),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Account ---
            const Text('Account', style: kHeaderStyle),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Change Password',
                    onTap: _navigateToChangePassword,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Section 2: Support ---
            const Text('Support', style: kHeaderStyle),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Developer Team',
                    onTap: () => _showPlaceholder('Developer Team'),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    title: 'Report a Problem',
                    onTap: () => _showPlaceholder('Report a Problem'),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    title: 'Privacy Policy',
                    onTap: () => _showPlaceholder('Privacy Policy'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- Logout Button ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRedColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildListTile({required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16);
  }
}
