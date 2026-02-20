import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  final PageController _pageController = PageController();
  bool _isLoading = false;

  // Step 1: Controllers
  final TextEditingController _nicController = TextEditingController();

  // Step 2: Controllers
  final TextEditingController _petController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  // Step 3: Controllers
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Stored data from Firebase
  String _userId = '';
  String _correctPetAnswer = '';
  String _correctNicknameAnswer = '';

  @override
  void dispose() {
    _pageController.dispose();
    _nicController.dispose();
    _petController.dispose();
    _nicknameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Shows a dialog message
  void _showMessage(String title, String message) {
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

  // --- Page 1 Logic: Verify NIC ---
  Future<void> _verifyNic() async {
    if (_nicController.text.isEmpty) {
      _showMessage('Error', 'Please enter your NIC.');
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: _nicController.text.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showMessage('Error', 'NIC not found. Please check and try again.');
      } else {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();

        // Store the details we need for the next steps
        _userId = userDoc.id;
        _correctPetAnswer = userData['securityQuestionPet'] ?? '';
        _correctNicknameAnswer = userData['securityQuestionNickname'] ?? '';

        // Check if security questions are set
        if (_correctPetAnswer.isEmpty || _correctNicknameAnswer.isEmpty) {
          _showMessage('Error',
              'Your account does not have security questions set up. Please contact an administrator.');
        } else {
          // Go to the next page
          _pageController.animateToPage(1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn);
        }
      }
    } catch (e) {
      _showMessage('Error', 'An error occurred: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- Page 2 Logic: Verify Security Answers ---
  void _verifySecurityAnswers() {
    final petAnswer = _petController.text.trim();
    final nicknameAnswer = _nicknameController.text.trim();

    if (petAnswer.isEmpty || nicknameAnswer.isEmpty) {
      _showMessage('Error', 'Please answer both security questions.');
      return;
    }

    // Case-insensitive comparison
    if (petAnswer.toLowerCase() == _correctPetAnswer.toLowerCase() &&
        nicknameAnswer.toLowerCase() == _correctNicknameAnswer.toLowerCase()) {
      // Answers are correct, move to page 3
      _pageController.animateToPage(2,
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      _showMessage('Error', 'One or both answers are incorrect.');
    }
  }

  // --- Page 3 Logic: Reset Password ---
  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Error', 'Please fill in both password fields.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Error', 'Passwords do not match.');
      return;
    }

    // --- TODO: Add password strength check here if you want ---
    if (newPassword.length < 6) {
      _showMessage(
          'Error', 'Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the password in Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({'password': newPassword});

      // Go to success page
      _pageController.animateToPage(3,
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } catch (e) {
      _showMessage('Error', 'Failed to update password: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- Page 4 Logic: Back to Login ---
  void _backToLogin() {
    Navigator.of(context).pop(); // Close this flow and return to Login
  }

  @override
  Widget build(BuildContext context) {
    // Define styles from your design
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
    final textStyleButton =
        const TextStyle(fontSize: 18, color: Colors.white);

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
          _buildNicEntryPage(
              textStyleTitle, textStyleSubtitle, buttonStyle, textStyleButton),
          _buildSecurityQuestionsPage(
              textStyleTitle, textStyleSubtitle, buttonStyle, textStyleButton),
          _buildNewPasswordPage(
              textStyleTitle, textStyleSubtitle, buttonStyle, textStyleButton),
          _buildSuccessPage(
              textStyleTitle, textStyleSubtitle, buttonStyle, textStyleButton),
        ],
      ),
    );
  }

  // --- Page 1: Enter NIC ---
  Widget _buildNicEntryPage(TextStyle title, TextStyle subtitle,
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
          Text("No worries, we'll help you out.",
              style: subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 30),
          _buildStyledTextField(
            controller: _nicController,
            labelText: 'Enter Your NIC', // Changed from Email to NIC
            icon: Icons.person,
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _verifyNic,
                  style: btnStyle,
                  child: Text('Find Account', style: btnText),
                ),
        ],
      ),
    );
  }

  // --- Page 2: Security Questions ---
  Widget _buildSecurityQuestionsPage(TextStyle title, TextStyle subtitle,
      ButtonStyle btnStyle, TextStyle btnText) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network('https://i.imgur.com/H0sYmNl.png', height: 200),
            const SizedBox(height: 30),
            Text('Security Questions',
                style: title, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Answer these questions to verify it\'s you.',
                style: subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            _buildStyledTextField(
              controller: _petController,
              labelText: 'What was your first pet\'s name?',
              icon: Icons.pets,
            ),
            const SizedBox(height: 20),
            _buildStyledTextField(
              controller: _nicknameController,
              labelText: 'What was your childhood nickname?',
              icon: Icons.child_care,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _verifySecurityAnswers,
                    style: btnStyle,
                    child: Text('Verify Answers', style: btnText),
                  ),
          ],
        ),
      ),
    );
  }

  // --- Page 3: Create New Password ---
  Widget _buildNewPasswordPage(TextStyle title, TextStyle subtitle,
      ButtonStyle btnStyle, TextStyle btnText) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network('https://i.imgur.com/T0b7orA.png', height: 200),
            const SizedBox(height: 30),
            Text('Create New Password',
                style: title, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Your new password must be different.',
                style: subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            _buildStyledTextField(
              controller: _newPasswordController,
              labelText: 'New Password',
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 20),
            _buildStyledTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm New Password',
// [----- AFTER (THE FIX) -----]
              icon: Icons.task_alt, // This is a nice checkmark icon              
              isPassword: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updatePassword,
                    style: btnStyle,
                    child: Text('Reset Password', style: btnText),
                  ),
          ],
        ),
      ),
    );
  }

  // --- Page 4: Success ---
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
          Text('Success!', style: title, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Your password has been reset successfully.',
              style: subtitle, textAlign: TextAlign.center),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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
