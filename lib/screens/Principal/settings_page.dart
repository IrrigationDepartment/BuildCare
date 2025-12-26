import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase
import '../forgot_password_flow.dart'; // Import your ForgotPasswordFlow

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _redColor = Color(0xFFF44336);
  static const Color _cardColor = Colors.white;
  static const Color _backgroundColor = Color(0xFFF5F5F5);

  // --- Updated: Handle Logout with Firebase ---
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        // Navigate to login and clear the navigation stack
        // Replace '/' with your actual login route name
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      _showMessage(context, 'Error', 'Failed to log out: $e');
    }
  }

  // --- Updated: Navigate to Change Password ---
  void _navigateToChangePassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordFlow()),
    );
  }

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
              onPressed: () => Navigator.of(ctx).pop())
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, VoidCallback onTap,
      {Color textColor = Colors.black87,
      Color iconColor = Colors.grey,
      bool showChevron = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
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
                if (showChevron)
                  Icon(Icons.chevron_right, color: iconColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  // --- Updated Logout Button UI ---
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () => _handleLogout(context), // Trigger Firebase Sign Out
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: () {
                _showMessage(context, 'Save', 'Settings saved successfully.');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _primaryColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(60, 35),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
            _buildSectionTitle('Account'),
            // --- Linked to ForgotPasswordFlow ---
            _buildSettingItem(
              context,
              'Change Password',
              () => _navigateToChangePassword(context),
            ),

            _buildSectionTitle('Support'),
            _buildSettingItem(
              context,
              'Developer Team',
              () => _showMessage(context, 'Action', 'Navigating to Team info.'),
            ),
            _buildSettingItem(
              context,
              'Report a Problem',
              () => _showMessage(context, 'Action', 'Opening Report Form.'),
            ),
            _buildSettingItem(
              context,
              'Privacy Policy',
              () => _showMessage(context, 'Action', 'Viewing Privacy Policy.'),
            ),

            _buildLogoutButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 5,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 30), activeIcon: Icon(Icons.home, size: 30), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 30), activeIcon: Icon(Icons.person, size: 30), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 30), activeIcon: Icon(Icons.settings, size: 30), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
          if (index == 1) _showMessage(context, 'Navigation', 'Navigating to Profile Page.');
        },
      ),
    );
  }
}