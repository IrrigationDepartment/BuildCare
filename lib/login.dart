import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/ProvincialEng/dashboard.dart';
import 'screens/ChiefEng/dashboard.dart';
import 'screens/DistrictEng/dashboard.dart';
import 'screens/Principal/dashboard.dart';
import 'screens/TO/dashboard.dart';
import 'screens/role_selection.dart';
import 'screens/forgot_password_flow.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay', style: TextStyle(color: Colors.blueAccent)),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _login() async {
    print('🔵 Login started');
    
    if (_nicController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      _showMessage('Error', 'Please enter both NIC and Password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📝 NIC entered: ${_nicController.text.trim()}');
      
      print('🔍 Searching for user in Firestore...');
      final querySnapshot = await _firestore
          .collection('users')
          .where('nic', isEqualTo: _nicController.text.trim().toUpperCase())
          .limit(1)
          .get();

      print(' Query result: ${querySnapshot.docs.length} documents found');

      if (querySnapshot.docs.isEmpty) {
        print(' No user found with this NIC');
        _showMessage('Login Failed', 'Invalid NIC or Password. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final email = userData['email'] as String;
      final isActive = userData['isActive'] as bool? ?? false;
      final userType = userData['userType'] as String?;

      print(' User found!');
      print(' Email: $email');
      print(' isActive: $isActive');
      print(' userType: $userType');

      if (!isActive) {
        print(' User account is not active');
        _showMessage(
          'Account Not Active',
          'Your account is not active. Please contact an administrator for activation.',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Step 4: Authenticate with Firebase Auth using email and password
      print(' Attempting Firebase Auth login...');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      print(' Login successful!');

      if (!mounted) return;

      Widget destination;
      switch (userType) {
        case 'Provincial Director':
          destination = ProvincialEngDashboard(userData: userData);
          break;
        case 'Chief Engineer':
          destination = ChiefEngDashboard(userData: userData);
          break;
        case 'District Engineer':
          destination = DistrictEngDashboard(userData: userData);
          break;
        case 'Principal':
          destination = PrincipalDashboard(userData: userData);
          break;
        case 'Technical Officer':
          destination = TODashboard(userData: userData);
          break;
        default:
          print(' Unknown user type: $userType');
          _showMessage(
            'Login Error',
            'Could not determine user role. Please contact support.',
          );
          setState(() => _isLoading = false);
          return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => destination),
      );

    } on FirebaseAuthException catch (e) {
      print(' FirebaseAuthException: ${e.code}');
      print(' Message: ${e.message}');

      String errorMessage = 'Login Failed';
      String errorDetails = '';

      switch (e.code) {
        case 'wrong-password':
          errorDetails = 'Invalid NIC or Password. Please try again.';
          break;
        case 'user-not-found':
          errorDetails = 'Invalid NIC or Password. Please try again.';
          break;
        case 'user-disabled':
          errorDetails = 'This account has been disabled. Contact support.';
          break;
        case 'invalid-email':
          errorDetails = 'Invalid account credentials. Please try again.';
          break;
        case 'network-request-failed':
          errorDetails = 'Network error. Please check your internet connection.';
          break;
        case 'too-many-requests':
          errorDetails = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorDetails = e.message ?? 'An error occurred. Please try again.';
      }

      _showMessage(errorMessage, errorDetails);
      
    } catch (e) {
      print(' General error: $e');
      _showMessage('Error', 'An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a light grey background for the full screen so the white card stands out
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            // ConstrainedBox is the secret to fixing the ultra-wide web layout!
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450), // Max width of 450px
              child: Container(
                padding: const EdgeInsets.all(40.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Image.asset(
                      'lib/assets/images/login.png',
                      height: 120, // Slightly smaller image to fit the card nicely
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.apartment, size: 80, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please log in to your BuildCare account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildTextField(
                      controller: _nicController,
                      labelText: 'National Identity Card (NIC)',
                      hintText: 'Enter your NIC',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const ForgotPasswordFlow(),
                          ));
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18, 
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const RoleSelectionPage(),
                            ));
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blueAccent.shade200),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent.shade200),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}