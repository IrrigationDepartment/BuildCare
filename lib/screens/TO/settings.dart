// settings.dart
<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the Forgot Password Flow (parent `screens/` folder)
import '../forgot_password_flow.dart';

class SettingsScreen extends StatefulWidget {
  // Optional: Callback to handle the "Back" arrow if used inside BottomNav
=======
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// මූලික Settings පිටුව
class SettingsScreen extends StatefulWidget {
>>>>>>> main
  final VoidCallback? onBackTap;

  const SettingsScreen({super.key, this.onBackTap});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
<<<<<<< HEAD
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
=======
  final User? user = FirebaseAuth.instance.currentUser;

  // Logout කිරීමේ ක්‍රියාවලිය
  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
>>>>>>> main
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

<<<<<<< HEAD
  void _showPlaceholder(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title clicked (Functionality coming soon)')),
    );
=======
  // Email Verification යැවීම
  Future<void> _sendVerificationEmail() async {
    try {
      if (user != null) {
        await user!.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
>>>>>>> main
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
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
=======
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Settings",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () {
>>>>>>> main
            if (widget.onBackTap != null) {
              widget.onBackTap!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
<<<<<<< HEAD
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
=======
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- User Info Card ---
                if (user != null) _buildUserCard(),

                const SizedBox(height: 20),
                const Text("Account Settings",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // --- Settings Options ---
                _buildSettingsOption(
                  icon: Icons.lock,
                  title: "Change Password",
                  subtitle: "Update your login password",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage()),
                  ),
                ),

                _buildSettingsOption(
                  icon: Icons.security,
                  title: "Security Questions",
                  subtitle: "Reset your security questions",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SecurityQuestionsPage()),
                  ),
                ),

                if (user != null && !user!.emailVerified)
                  _buildSettingsOption(
                    icon: Icons.mark_email_read,
                    title: "Verify Email",
                    subtitle: "Verify your email address",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VerifyEmailPage()),
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
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Log out",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
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
            child: Icon(Icons.person, color: Colors.blue.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.email ?? 'No email',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900)),
                Text('UID: ${user?.uid.substring(0, 10)}...',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Icon(
            user!.emailVerified ? Icons.verified : Icons.warning,
            color: user!.emailVerified ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// --- Change Password Page, Security Questions Page, Verify Email Page ---
// Implementations added here to avoid missing-class errors and provide basic functionality.

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _loading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No signed-in user found.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('New passwords do not match.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password updated successfully.'),
            backgroundColor: Colors.green),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentController,
                decoration:
                    const InputDecoration(labelText: 'Current password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter current password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                decoration: const InputDecoration(labelText: 'New password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Password too short' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                decoration:
                    const InputDecoration(labelText: 'Confirm new password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Confirm the password' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _changePassword,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecurityQuestionsPage extends StatefulWidget {
  const SecurityQuestionsPage({super.key});

  @override
  State<SecurityQuestionsPage> createState() => _SecurityQuestionsPageState();
}

class _SecurityQuestionsPageState extends State<SecurityQuestionsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _q1 = TextEditingController();
  final TextEditingController _q2 = TextEditingController();
  final TextEditingController _q3 = TextEditingController();

  @override
  void dispose() {
    _q1.dispose();
    _q2.dispose();
    _q3.dispose();
    super.dispose();
  }

  void _saveQuestions() {
    if (!_formKey.currentState!.validate()) return;
    // Placeholder: In a real app you would persist these securely (e.g., Firestore with encryption).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Security questions saved.'),
          backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Questions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _q1,
                decoration:
                    const InputDecoration(labelText: 'Question 1 answer'),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please provide an answer'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _q2,
                decoration:
                    const InputDecoration(labelText: 'Question 2 answer'),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please provide an answer'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _q3,
                decoration:
                    const InputDecoration(labelText: 'Question 3 answer'),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please provide an answer'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _saveQuestions, child: const Text('Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isSending = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      setState(() => _isVerified = user.emailVerified);
    }
  }

  Future<void> _sendVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No signed-in user.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verification email sent.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                _isVerified
                    ? 'Your email is verified.'
                    : 'Your email is not verified.',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isSending ? null : _sendVerification,
                  child: _isSending
                      ? const CircularProgressIndicator()
                      : const Text('Send verification email'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                    onPressed: _loadStatus, child: const Text('Refresh')),
              ],
>>>>>>> main
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD

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
=======
>>>>>>> main
}
