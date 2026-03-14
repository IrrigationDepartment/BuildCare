import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for Auth

// Keep your existing dashboard import
import 'dashboard.dart';

// -----------------------------------------------------------------------------
// --- 1. Provincial Engineer REGISTRATION (Sign Up) Page ---
// -----------------------------------------------------------------------------
class ProvincialEngRegistrationPage extends StatefulWidget {
  const ProvincialEngRegistrationPage({super.key});

  @override
  State<ProvincialEngRegistrationPage> createState() =>
      _ProvincialEngRegistrationPageState();
}

class _ProvincialEngRegistrationPageState
    extends State<ProvincialEngRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _userTypeController =
      TextEditingController(text: 'Provincial Director');
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Default Configuration
  final bool _initialIsActiveStatus = false; // User starts as deactivated
  final String _defaultProfileImageUrl =
      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_Ldbm8TwlbnL43PId23vLdI3MgqhaNYf5.jpg';

  // FocusNodes
  final _passwordFocusNode = FocusNode();
  final _nicFocusNode = FocusNode();

  String? _selectedOffice;
  final List<String> _offices = ['Galle', 'Matara', 'Hambantota'];

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Password Validation State
  bool _isPasswordFocused = false;
  bool _has8Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  // NIC Check State
  bool _isCheckingNic = false;
  bool _isNicDuplicate = false;

  @override
  void initState() {
    super.initState();
    // Password listener
    _passwordController.addListener(_validatePassword);
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });

    // NIC Focus listener
    _nicFocusNode.addListener(_onNicFocusChange);
  }

  @override
  void dispose() {
    _userTypeController.dispose();
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _officePhoneController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _passwordController.removeListener(_validatePassword);
    _passwordFocusNode.dispose();

    _nicFocusNode.removeListener(_onNicFocusChange);
    _nicFocusNode.dispose();
    super.dispose();
  }

  void _onNicFocusChange() {
    if (!_nicFocusNode.hasFocus) {
      _checkNicDuplication();
    }
  }

  Future<void> _checkNicDuplication() async {
    final nic = _nicController.text.trim().toUpperCase();

    if (nic.isEmpty) return;
    final nicRegex = RegExp(r'^(\d{9}[vVxX]|\d{12})$');
    if (!nicRegex.hasMatch(nic)) return;

    setState(() {
      _isCheckingNic = true;
      _isNicDuplicate = false;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: nic)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isNicDuplicate = query.docs.isNotEmpty;
        });
      }
    } catch (e) {
      // Handle silent error or log
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingNic = false;
        });
      }
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _has8Chars = password.length >= 8;
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });
  }

  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Password Complexity Check
    if (!_has8Chars ||
        !_hasLowercase ||
        !_hasUppercase ||
        !_hasNumber ||
        !_hasSpecialChar) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orange,
            content: Text(
                'Please ensure the password meets all security requirements.')));
      }
      return;
    }

    // Final NIC Check
    await _checkNicDuplication();
    if (_isNicDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('This NIC is already registered.'),
        ));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create User in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String? uid = userCredential.user?.uid;

      if (uid != null) {
        // 2. Create Data Map (No Password Stored)
        final userData = {
          'name': _nameController.text.trim(),
          'nic': _nicController.text.trim().toUpperCase(),
          'email': _emailController.text.trim(),
          'office': _selectedOffice,
          'officePhone': _officePhoneController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'userType': 'Provincial Director',
          'createdAt': Timestamp.now(),
          'isActive': _initialIsActiveStatus,
          'profile_image': _defaultProfileImageUrl,
        };

        // 3. Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Registration successful! Please Login.')),
          );
          
          // Navigate to Login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProvincialEngLoginPage(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';
      if (e.code == 'email-already-in-use') {
        message = 'The email address is already in use.';
      } else if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Registration failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Matching light background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550), // Web/Desktop restriction
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.architecture_outlined, size: 56, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Provincial Director Signup',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register for your administrative account',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),

                      _buildLabeledTextField(
                          label: 'User Type',
                          controller: _userTypeController,
                          isReadOnly: true,
                          icon: Icons.work_outline),
                      
                      _buildLabeledTextField(
                          label: 'Engineer\'s Name',
                          hint: 'Enter Name',
                          controller: _nameController,
                          icon: Icons.person_outline),

                      // NIC Field
                      _buildLabeledTextField(
                          label: 'NIC Number',
                          hint: 'e.g., 123456789V or 199012345678',
                          controller: _nicController,
                          icon: Icons.credit_card,
                          focusNode: _nicFocusNode,
                          isChecking: _isCheckingNic,
                          errorText: _isNicDuplicate
                              ? 'This NIC is already registered'
                              : null,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'NIC cannot be empty';
                            final nicRegex = RegExp(r'^(\d{9}[vVxX]|\d{12})$');
                            if (!nicRegex.hasMatch(value)) return 'Invalid NIC format';
                            return null;
                          }),

                      _buildLabeledTextField(
                          label: 'Email Address',
                          hint: 'Enter Email',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email cannot be empty';
                            if (!value.contains('@')) return 'Enter a valid email';
                            return null;
                          }),

                      _buildLabeledDropdown(
                          label: 'Select Office',
                          hint: 'Select an Office',
                          value: _selectedOffice,
                          items: _offices,
                          icon: Icons.business_outlined,
                          onChanged: (val) => setState(() => _selectedOffice = val)),

                      _buildLabeledTextField(
                          label: 'Office Phone',
                          hint: '10-digit number',
                          controller: _officePhoneController,
                          icon: Icons.phone_in_talk_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Field cannot be empty';
                            if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Must be 10 digits';
                            return null;
                          }),

                      _buildLabeledTextField(
                          label: 'Mobile Number',
                          hint: '10-digit number',
                          controller: _mobileController,
                          icon: Icons.phone_iphone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Field cannot be empty';
                            if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Must be 10 digits';
                            return null;
                          }),

                      const Divider(height: 40),
                      Text('Password', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 16),

                      // Password Fields
                      _buildLabeledTextField(
                          label: 'Password',
                          hint: 'Enter Password',
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          focusNode: _passwordFocusNode,
                          onVisibilityToggle: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter password';
                             if (!_has8Chars || !_hasLowercase || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
                                return 'Does not meet security requirements';
                             }
                            return null;
                          }),

                      if (_isPasswordFocused)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
                          child: _buildPasswordValidationUI(),
                        ),

                      _buildLabeledTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter Password',
                          controller: _confirmPasswordController,
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          onVisibilityToggle: () => setState(() =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible),
                          validator: (value) {
                            if (value != _passwordController.text) return 'Passwords do not match';
                            return null;
                          }),

                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Complete Registration',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2)),
                            ),
                      
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account?", style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () {
                               Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProvincialEngLoginPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: const Text("Sign In",
                                style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper UI Methods ---

  Widget _buildPasswordValidationUI() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildValidationRow('At least 8 characters', _has8Chars),
          const SizedBox(height: 4),
          _buildValidationRow('Contains lowercase letter', _hasLowercase),
          const SizedBox(height: 4),
          _buildValidationRow('Contains uppercase letter', _hasUppercase),
          const SizedBox(height: 4),
          _buildValidationRow('Contains number', _hasNumber),
          const SizedBox(height: 4),
          _buildValidationRow('Contains special character', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.remove_circle_outline,
            color: isValid ? Colors.green : Colors.grey.shade500, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: isValid ? Colors.green : Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    IconData? icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    bool isReadOnly = false,
    VoidCallback? onVisibilityToggle,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    String? errorText,
    bool isChecking = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
              controller: controller,
              focusNode: focusNode,
              readOnly: isReadOnly,
              obscureText: isPassword && !isPasswordVisible,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black87),
              decoration: _inputDecoration(
                hint,
                icon,
                isChecking
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : (isPassword
                        ? IconButton(
                            icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade600),
                            onPressed: onVisibilityToggle)
                        : null),
                errorText,
              ),
              validator: validator ??
                  (value) => value!.isEmpty ? '$label cannot be empty' : null),
        ],
      ),
    );
  }

  Widget _buildLabeledDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
              value: value,
              items: items
                  .map((String office) => DropdownMenuItem<String>(
                      value: office, child: Text(office)))
                  .toList(),
              onChanged: onChanged,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: _inputDecoration(hint, icon, null, null),
              validator: (value) =>
                  value == null ? 'Please select an option' : null)
        ]));
  }

  InputDecoration _inputDecoration(String hintText, IconData? icon,
      Widget? suffixIcon, String? errorText) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent.shade200) : null,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0)),
      errorText: errorText,
      suffixIcon: suffixIcon,
    );
  }
}

// -----------------------------------------------------------------------------
// --- 2. Provincial Engineer LOGIN Page (UPDATED FOR FIREBASE AUTH) ---
// -----------------------------------------------------------------------------
class ProvincialEngLoginPage extends StatefulWidget {
  const ProvincialEngLoginPage({super.key});

  @override
  State<ProvincialEngLoginPage> createState() => _ProvincialEngLoginPageState();
}

class _ProvincialEngLoginPageState extends State<ProvincialEngLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String loginId = _loginIdController.text.trim();
      final String password = _passwordController.text.trim();
      
      // Determine if likely Email or NIC
      final bool isEmail = loginId.contains('@');

      try {
        String emailToAuth = loginId;

        // If NIC entered, find the email first
        if (!isEmail) {
           final userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('nic', isEqualTo: loginId.toUpperCase())
              .limit(1)
              .get();
            
            if (userQuery.docs.isEmpty) {
              throw FirebaseAuthException(
                code: 'user-not-found', 
                message: 'No user found with this NIC.'
              );
            }
            emailToAuth = userQuery.docs.first['email'];
        }

        // Authenticate via Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: emailToAuth, password: password);

        // Check if data exists in Firestore
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (docSnapshot.exists) {
           final userData = docSnapshot.data()!;
           
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Welcome, ${userData['name']}!'),
                 backgroundColor: Colors.green,
               ),
             );
             
             // Navigate to Dashboard
             Navigator.pushAndRemoveUntil(
               context,
               MaterialPageRoute(
                 builder: (context) => ProvincialEngDashboard(userData: userData),
               ),
               (Route<dynamic> route) => false,
             );
           }
        } else {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('User data not found in system.'),
                 backgroundColor: Colors.redAccent,
               ));
          }
        }

      } on FirebaseAuthException catch (e) {
        String message = 'Login failed.';
        if (e.code == 'user-not-found') {
          message = 'No user found for this email/NIC.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password.';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email format.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Matching light background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450), // Mobile/web constraint
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.person_pin_circle_outlined, size: 80, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Provincial Director',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to access your dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 40),
                      
                      TextFormField(
                        controller: _loginIdController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: _inputDecoration('NIC or Email Address', Icons.person_outline),
                        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent.shade200),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
                          ),
                        ),
                        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 32),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign In',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                      
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?", style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () {
                               Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProvincialEngRegistrationPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: const Text("Sign Up",
                                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent.shade200),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
      ),
    );
  }
}