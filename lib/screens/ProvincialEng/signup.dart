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
      TextEditingController(text: 'Provincial Engineer');
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _petNameController = TextEditingController();
  final _nicknameController = TextEditingController();
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
    _petNameController.dispose();
    _nicknameController.dispose();
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
          'securityQuestionPet': _petNameController.text.trim(),
          'securityQuestionNickname': _nicknameController.text.trim(),
          'userType': 'Provincial Engineer',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register Provincial Engineer'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 248, 248, 248),
                    borderRadius: BorderRadius.circular(20)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabeledTextField(
                          label: 'User Type',
                          controller: _userTypeController,
                          isReadOnly: true),
                      
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
                          onChanged: (val) => setState(() => _selectedOffice = val)),

                      _buildLabeledTextField(
                          label: 'Office Phone',
                          hint: '10-digit number',
                          controller: _officePhoneController,
                          icon: Icons.phone,
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

                      const SizedBox(height: 16),
                      const Text('Security Questions',
                          style: TextStyle(
                              color: Color(0xFF53BDFF),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      _buildLabeledTextField(
                          label: 'First Pet Name',
                          hint: 'Answer',
                          controller: _petNameController),
                      _buildLabeledTextField(
                          label: 'Childhood Nickname',
                          hint: 'Answer',
                          controller: _nicknameController),

                      // Password Fields
                      _buildLabeledTextField(
                          label: 'Password',
                          hint: 'Enter Password',
                          controller: _passwordController,
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
                          padding: const EdgeInsets.only(
                              bottom: 16.0, left: 4.0),
                          child: _buildPasswordValidationUI(),
                        ),

                      _buildLabeledTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter Password',
                          controller: _confirmPasswordController,
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
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _registerUser,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF53BDFF),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30))),
                                child: const Text('Register',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                      
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () {
                             Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProvincialEngLoginPage(),
                              ),
                            );
                          },
                          child: const Text("Already have an account? Sign In",
                              style: TextStyle(
                                  color: Color(0xFF53BDFF),
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper UI Methods ---

  Widget _buildPasswordValidationUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildValidationRow('At least 8 characters', _has8Chars),
        _buildValidationRow('Contains lowercase', _hasLowercase),
        _buildValidationRow('Contains uppercase', _hasUppercase),
        _buildValidationRow('Contains number', _hasNumber),
        _buildValidationRow('Contains special char', _hasSpecialChar),
      ],
    );
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.remove_circle_outline,
              color: isValid ? Colors.green : Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: isValid ? Colors.green : Colors.grey, fontSize: 12)),
        ],
      ),
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
              style: const TextStyle(
                  color: Color.fromARGB(179, 0, 0, 0), fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
              controller: controller,
              focusNode: focusNode,
              readOnly: isReadOnly,
              obscureText: isPassword && !isPasswordVisible,
              keyboardType: keyboardType,
              decoration: _inputDecoration(
                hint,
                isChecking ? null : icon,
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
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF53BDFF)),
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

  Widget _buildLabeledDropdown(
      {required String label,
      required String hint,
      required String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: Color.fromARGB(179, 0, 0, 0), fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
<<<<<<< HEAD
              value: value,
=======
              initialValue: value,
>>>>>>> main
              items: items
                  .map((String office) => DropdownMenuItem<String>(
                      value: office, child: Text(office)))
                  .toList(),
              onChanged: onChanged,
              decoration: _inputDecoration(hint, null, null, null),
              validator: (value) =>
                  value == null ? 'Please select an option' : null)
        ]));
  }

  InputDecoration _inputDecoration(String hintText, IconData? icon,
      Widget? suffixIcon, String? errorText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Color(0xFF53BDFF), width: 2.0)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Colors.red, width: 1.0)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Colors.red, width: 2.0)),
      errorText: errorText,
      suffixIcon: suffixIcon ??
          (icon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(icon, color: const Color(0xFF53BDFF)))
              : null),
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
               SnackBar(content: Text('Welcome, ${userData['name']}!')),
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
               const SnackBar(content: Text('User data not found in system.')));
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
            SnackBar(content: Text(message), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Provincial Engineer Login'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_pin_circle_outlined,
                  size: 100, color: Color(0xFF53BDFF)),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _loginIdController,
                decoration: _inputDecoration('NIC or Email Address', Icons.person_outline),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF53BDFF)),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53BDFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProvincialEngRegistrationPage(),
                    ),
                  );
                },
                child: const Text("Don't have an account? Sign Up",
                    style: TextStyle(color: Color(0xFF53BDFF), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      suffixIcon: Icon(icon, color: const Color(0xFF53BDFF)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }
}