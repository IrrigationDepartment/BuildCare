import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Import Firebase Auth

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  final PageController _pageController = PageController();
  bool _isLoading = false;

  // --- Controllers for the new flow ---
  // Step 1: Email
  final TextEditingController _emailController = TextEditingController();

  // --- We no longer need OTP or Password controllers ---

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Shows a dialog message
  void _showMessage(String title, String message) {
    if (!mounted) return;
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
            },
          )
        ],
      ),
    );
  }

  // --- Page 1 Logic: Send Password Reset Email ---
  Future<void> _sendResetEmail() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showMessage('Error', 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      // --- This is the new, correct Firebase Auth call ---
      // It sends the email template you saw in your Firebase console
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      // --- End of new call ---

      // Go to the success page
      _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn);

    } on FirebaseAuthException catch (e) {
      // Handle errors
      String message = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        // We show a generic message for security
        // But you can be specific if you prefer
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      _showMessage('Error', message);
    } catch (e) {
      _showMessage('Error', 'An error occurred: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- Page 2 Logic: Back to Login ---
  void _backToLogin() {
    Navigator.of(context).pop(); // Close this flow and return to Login
  }

  @override
  Widget build(BuildContext context) {
    // Define styles
    const textStyleTitle =
        TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
    const textStyleSubtitle = TextStyle(fontSize: 16, color: Colors.grey);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3498DB), // Blue color from design
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
    const textStyleButton =
        TextStyle(fontSize: 18, color: Colors.white);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Back To Login',
            style: TextStyle(color: Colors.black, fontSize: 18)),
      ),
      body: PageView(
        controller: _pageController,
        // Disable swiping between pages
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // --- Page 1 ---
          _buildEmailEntryPage(
              textStyleTitle, textStyleSubtitle, buttonStyle, textStyleButton),
          // --- Page 2 (The new success page) ---
          _buildSuccessPage(
              textStyleTitle, textStyleSubtitle, buttonStyle, textStyleButton),
        ],
      ),
    );
  }

  // --- Page 1: Enter Email ---
  Widget _buildEmailEntryPage(TextStyle title, TextStyle subtitle,
      ButtonStyle btnStyle, TextStyle btnText) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.network('https://i.imgur.com/g82d1l0.png', height: 200),
          const SizedBox(height: 30),
          Text('Forgot Password?', style: title, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text("Enter your email and we'll send you a reset link.",
              style: subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 30),
          _buildStyledTextField(
            controller: _emailController,
            labelText: 'Enter Your Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _sendResetEmail, // <-- Updated function
                  style: btnStyle,
                  child: Text('Send Reset Link', style: btnText), // <-- Updated text
                ),
        ],
      ),
    );
  }

  // --- Page 2: Success ---
  Widget _buildSuccessPage(TextStyle title, TextStyle subtitle,
      ButtonStyle btnStyle, TextStyle btnText) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 150),
          const SizedBox(height: 30),
          Text('Check Your Email!', style: title, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
              // Show the email they entered
              'We have sent a password reset link to ${_emailController.text.trim()}.',
              style: subtitle,
              textAlign: TextAlign.center),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _backToLogin,
            style: btnStyle,
            child: Text('Back to Login', style: btnText),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for TextFields ---
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
}