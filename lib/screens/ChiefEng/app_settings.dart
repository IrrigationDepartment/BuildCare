import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- PREMIUM THEME CONSTANTS ---
const Color _primaryColor = Color(0xFF1E3A8A); // Deep Indigo
const Color _secondaryColor = Color(0xFF0D9488); // Teal
const Color _bgLight = Color(0xFFF4F7FC); // Soft Light Gray
const Color _textDark = Color(0xFF111827);
const Color _dangerRed = Color(0xFFE11D48); // Rose Red
const Color _successGreen = Color(0xFF10B981); // Emerald

// Main Settings Page with options
class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBackTap;

  const SettingsScreen({super.key, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: true,
      ),
      body: Center(
        // Responsive constraint for large screens
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // User Info Card
              if (user != null)
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [_primaryColor, _secondaryColor]),
                        ),
                        child: const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person_rounded, color: _primaryColor, size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email ?? 'No email',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UID: ${user.uid.substring(0, 10)}...',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (user.emailVerified ? _successGreen : Colors.orange).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          user.emailVerified ? Icons.verified_rounded : Icons.warning_rounded,
                          color: user.emailVerified ? _successGreen : Colors.orange,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
                      child: Text('ACCOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                    ),
                    _buildSettingsOption(
                      context,
                      icon: Icons.lock_outline_rounded,
                      title: "Change Password",
                      subtitle: "Update your login password",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage())),
                    ),
                    
                    if (user != null && !user.emailVerified)
                      _buildSettingsOption(
                        context,
                        icon: Icons.mark_email_read_outlined,
                        title: "Verify Email",
                        subtitle: "Verify your email address",
                        iconColor: Colors.orange,
                        onTap: () => _sendVerificationEmail(context),
                      ),
                      
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Text('PREFERENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                    ),
                    _buildSettingsOption(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: "Notifications",
                      subtitle: "Manage notification settings",
                      onTap: () {},
                    ),
                    
                    const SizedBox(height: 32),
                    // App Info Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.grey.shade500, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("App Version 1.0.0", style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w600)),
                                if (user != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text("Signed in: ${user.email}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12), overflow: TextOverflow.ellipsis),
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
              const SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: CustomBottomNavBar(currentIndex: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final iColor = iconColor ?? _primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: iColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: _textDark)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _sendVerificationEmail(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification email sent! Check your inbox.'),
              backgroundColor: _successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: $e'), backgroundColor: _dangerRed),
        );
      }
    }
  }
}

// Change Password Page
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('No user signed in');
      return;
    }

    if (!user.emailVerified) {
      _showError('Please verify your email first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (user.email != null) {
        final credential = EmailAuthProvider.credential(email: user.email!, password: _currentPasswordController.text);
        await user.reauthenticateWithCredential(credential);
      }

      await user.updatePassword(_newPasswordController.text);
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Password updated successfully!'), backgroundColor: _successGreen, behavior: SnackBarBehavior.floating),
        );
        Future.delayed(const Duration(seconds: 1), () { if (mounted) Navigator.pop(context); });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to update password';
      switch (e.code) {
        case 'wrong-password': errorMessage = 'Current password is incorrect'; break;
        case 'weak-password': errorMessage = 'New password is too weak. Use at least 6 characters'; break;
        case 'requires-recent-login': errorMessage = 'Please sign in again to change password'; break;
        default: errorMessage = e.message ?? 'An error occurred';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: _dangerRed, behavior: SnackBarBehavior.floating));
  }

  Future<void> _sendPasswordResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to ${user.email}'), backgroundColor: _primaryColor, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      _showError('Failed to send reset email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user != null && !user.emailVerified)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Email not verified. Please verify your email to change password.', style: TextStyle(color: Colors.orange.shade900, fontSize: 14)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyEmailPage())),
                            child: Text('Verify', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Current Password'),
                        _buildPasswordField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          hintText: 'Enter current password',
                          onToggleVisibility: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                          validator: (v) => v == null || v.isEmpty ? 'Current password is required' : null,
                        ),
                        const SizedBox(height: 24),
                        
                        _buildLabel('New Password'),
                        _buildPasswordField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          hintText: 'Enter new password',
                          onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'New password is required';
                            if (v.length < 6) return 'Must be at least 6 characters';
                            if (v == _currentPasswordController.text) return 'New password must be different';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        _buildLabel('Confirm New Password'),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          hintText: 'Confirm new password',
                          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please confirm your password';
                            if (v != _newPasswordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: _sendPasswordResetEmail,
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: const Text('Forgot Password? Send reset email'),
                      style: TextButton.styleFrom(foregroundColor: _primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: _primaryColor.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textDark)),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required String hintText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: _bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade500),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }
}

// Verify Email Page
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isLoading = false;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isLoading = true);

    try {
      await user.sendEmailVerification();
      setState(() => _resendCooldown = 60);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCooldown > 0) {
          setState(() => _resendCooldown--);
        } else {
          timer.cancel();
        }
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Verification email sent! Check your inbox.'), backgroundColor: _successGreen, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send email: $e'), backgroundColor: _dangerRed, behavior: SnackBarBehavior.floating));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      
      if (updatedUser?.emailVerified == true) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Email verified successfully!'), backgroundColor: _successGreen, behavior: SnackBarBehavior.floating));
          Navigator.pop(context);
        }
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email not verified yet. Please check your inbox.'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error checking verification: $e'), backgroundColor: _dangerRed, behavior: SnackBarBehavior.floating));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("Verify Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 1,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 30)]),
                  child: const Icon(Icons.mark_email_unread_rounded, size: 80, color: _primaryColor),
                ),
                const SizedBox(height: 32),
                const Text('Verify Your Email', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textDark)),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? 'No email address',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: _primaryColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)]),
                  child: Column(
                    children: [
                      const Text(
                        'We\'ve sent a verification link to your email address. Click the link in the email to verify your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendVerificationEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _resendCooldown > 0 ? 'Resend in $_resendCooldown s' : 'Send Verification Email',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _checkVerification,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: _primaryColor, width: 1.5),
                          ),
                          child: const Text('I\'ve Verified My Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Keep CustomBottomNavBar as is
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isVisible;

  const CustomBottomNavBar({
    super.key, 
    required this.currentIndex, 
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // ... rest of your existing decoration and BottomNavigationBar code
    );
  }
}