import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import necessary pages to use in the Bottom Navigation Bar
// IMPORTANT: This import allows us to use 'CustomBottomNavBar' from dashboard
import 'dashboard.dart';
import 'profile_management.dart';

// Main Settings Page with options
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // User Info Card
          if (user != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email ?? 'No email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UID: ${user.uid.substring(0, 10)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    user.emailVerified ? Icons.verified : Icons.warning,
                    color: user.emailVerified ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                _buildSettingsOption(
                  context,
                  icon: Icons.lock,
                  title: "Change Password",
                  subtitle: "Update your login password",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  ),
                ),
                _buildSettingsOption(
                  context,
                  icon: Icons.security,
                  title: "Security Questions",
                  subtitle: "Reset your security questions",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SecurityQuestionsPage()),
                  ),
                ),
                if (user != null && !user.emailVerified)
                  _buildSettingsOption(
                    context,
                    icon: Icons.mark_email_read,
                    title: "Verify Email",
                    subtitle: "Verify your email address",
                    onTap: () => _sendVerificationEmail(context),
                  ),
                _buildSettingsOption(
                  context,
                  icon: Icons.notifications,
                  title: "Notifications",
                  subtitle: "Manage notification settings",
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "App Version 1.0.0",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (user != null)
                              Text(
                                "Signed in: ${user.email}",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- UPDATED BOTTOM NAVIGATION BAR ---
          // Using currentIndex: 2 to highlight 'Settings'
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CustomBottomNavBar(currentIndex: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color.fromARGB(255, 140, 64, 64)),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _sendVerificationEmail(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// --- SUB PAGES STUBS (To prevent errors if not already defined) ---
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Change Password")));
}

class SecurityQuestionsPage extends StatelessWidget {
  const SecurityQuestionsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Security Questions")));
}