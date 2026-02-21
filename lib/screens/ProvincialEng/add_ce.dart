import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChiefEngRegistrationPage extends StatefulWidget {
  const ChiefEngRegistrationPage({super.key});

  @override
  State<ChiefEngRegistrationPage> createState() =>
      _ChiefEngRegistrationPageState();
}

class _ChiefEngRegistrationPageState extends State<ChiefEngRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final _userTypeController = TextEditingController(text: 'Chief Engineer');
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  
  // REMOVED: _petNameController and _nicknameController
  
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  String? _selectedOffice;
  final List<String> _offices = ['Galle', 'Matara', 'Hambantota'];

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Password validation UI state
  bool _isPasswordFocused = false;
  bool _has8Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _userTypeController.dispose();
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _officePhoneController.dispose();
    _mobileController.dispose();
    
    // REMOVED: _petNameController and _nicknameController disposal
    
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordController.removeListener(_validatePassword);
    _passwordFocusNode.dispose();
    super.dispose();
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

  Future<bool> _checkNicExists(String nic) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nic', isEqualTo: nic.toUpperCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking NIC: $e');
      return false;
    }
  }

  Future<bool> _checkEmailExistsInFirestore(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email in Firestore: $e');
      return false;
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(fontSize: 16, color: Colors.blueAccent)),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_has8Chars || !_hasLowercase || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Please ensure the password meets all security requirements.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nicExists = await _checkNicExists(_nicController.text.trim());
      if (nicExists) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'NIC Already Exists',
          'A user with NIC number "${_nicController.text.trim().toUpperCase()}" is already registered.',
        );
        return;
      }

      final emailExistsInFirestore =
          await _checkEmailExistsInFirestore(_emailController.text.trim());
      if (emailExistsInFirestore) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Email Already Registered',
          'An account with email "${_emailController.text.trim()}" already exists.',
        );
        return;
      }

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      await userCredential.user!.updateDisplayName(_nameController.text.trim());

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'nic': _nicController.text.trim().toUpperCase(),
        'email': _emailController.text.trim().toLowerCase(),
        'office': _selectedOffice,
        'officePhone': _officePhoneController.text.trim(),
        'mobilePhone': _mobileController.text.trim(),
        // REMOVED: securityQuestionPet and securityQuestionNickname
        'userType': 'Chief Engineer',
        'isActive': false,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✓ Registration Successful!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verification email sent to ${_emailController.text.trim()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration Failed';
      String errorDetails = '';

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Weak Password';
          errorDetails = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email Already Exists';
          errorDetails = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid Email';
          errorDetails = 'The email address format is invalid.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network Error';
          errorDetails = 'Please check your internet connection.';
          break;
        default:
          errorMessage = 'Registration Failed';
          errorDetails = e.message ?? 'An unknown error occurred.';
      }

      if (mounted) {
        _showErrorDialog(errorMessage, errorDetails);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Registration Failed',
          'An unexpected error occurred: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550), // Responsive Constraint
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
                      const Icon(Icons.engineering_outlined, size: 56, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Chief Engineer Signup',
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

                      // --- Form Fields ---
                      _buildLabeledTextField(
                          label: 'User Type',
                          isReadOnly: true,
                          controller: _userTypeController,
                          icon: Icons.work_outline,
                          validator: (value) => null),

                      _buildLabeledTextField(
                          label: 'Chief Engineer Name',
                          hint: 'Enter Your Name',
                          controller: _nameController,
                          icon: Icons.person_outline),

                      _buildLabeledTextField(
                          label: 'NIC Number',
                          hint: 'e.g., 123456789V or 199012345678',
                          controller: _nicController,
                          icon: Icons.credit_card,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'NIC cannot be empty';
                            final nicRegex = RegExp(r'^(\d{9}[vVxX]|\d{12})$');
                            if (!nicRegex.hasMatch(value)) return 'Invalid Sri Lankan NIC format';
                            return null;
                          }),

                      _buildLabeledDropdown(
                          label: 'Select Your Office',
                          hint: 'Select an Office',
                          value: _selectedOffice,
                          items: _offices,
                          icon: Icons.business_outlined,
                          onChanged: (newValue) =>
                              setState(() => _selectedOffice = newValue)),

                      _buildLabeledTextField(
                          label: 'Email Address',
                          hint: 'Enter Your Email Address',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email cannot be empty';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          }),

                      _buildLabeledTextField(
                          label: 'Office Phone Number',
                          hint: 'Enter 10-digit number',
                          controller: _officePhoneController,
                          icon: Icons.phone_in_talk_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Office number cannot be empty';
                            final phoneRegex = RegExp(r'^\d{10}$');
                            if (!phoneRegex.hasMatch(value)) return 'Office number must be 10 digits';
                            return null;
                          }),

                      _buildLabeledTextField(
                          label: 'Mobile Number',
                          hint: 'Enter 10-digit number',
                          controller: _mobileController,
                          icon: Icons.phone_iphone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Mobile number cannot be empty';
                            final phoneRegex = RegExp(r'^\d{10}$');
                            if (!phoneRegex.hasMatch(value)) return 'Mobile number must be 10 digits';
                            return null;
                          }),

                      // REMOVED: Security Questions divider and fields

                      const Divider(height: 40),
                      Text('Password', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 16),

                      _buildLabeledTextField(
                        label: 'Enter Your Password',
                        hint: 'Enter Your Password',
                        controller: _passwordController,
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        focusNode: _passwordFocusNode,
                        icon: Icons.lock_outline,
                        onVisibilityToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password cannot be empty';
                          if (!_has8Chars || !_hasLowercase || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
                            return 'Please meet all password requirements';
                          }
                          return null;
                        },
                      ),

                      if (_isPasswordFocused)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
                          child: _buildPasswordValidationUI(),
                        ),

                      _buildLabeledTextField(
                        label: 'Re-Enter Your Password',
                        hint: 'Re-Enter Your Password',
                        controller: _confirmPasswordController,
                        isPassword: true,
                        icon: Icons.lock_outline,
                        isPasswordVisible: _isConfirmPasswordVisible,
                        onVisibilityToggle: () => setState(() =>
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),

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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Complete Registration',
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
                          Text("Already Registered?", style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: const Text('Sign In',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent)),
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

  // --- Helper Widgets ---

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
          _buildValidationRow('Contains a lowercase letter', _hasLowercase),
          const SizedBox(height: 4),
          _buildValidationRow('Contains an uppercase letter', _hasUppercase),
          const SizedBox(height: 4),
          _buildValidationRow('Contains a number', _hasNumber),
          const SizedBox(height: 4),
          _buildValidationRow('Contains a special character', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.remove_circle_outline,
          color: isValid ? Colors.green : Colors.grey.shade500,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
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
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            readOnly: isReadOnly,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDecoration(
              hintText: hint,
              icon: icon,
              errorText: errorText,
              suffixIcon: suffixIcon ??
                  (isPassword
                      ? IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: onVisibilityToggle,
                        )
                      : null),
            ),
            validator: validator ?? (value) => value!.isEmpty ? '$label cannot be empty' : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          )
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items.map((String office) => DropdownMenuItem<String>(value: office, child: Text(office))).toList(),
            onChanged: onChanged,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: _inputDecoration(hintText: hint, icon: icon),
            validator: (value) => value == null ? 'Please select an option' : null,
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText, 
    IconData? icon, 
    Widget? suffixIcon, 
    String? errorText
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent.shade200) : null,
      suffixIcon: suffixIcon,
      errorText: errorText,
      hintStyle: TextStyle(color: Colors.grey.shade500),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
      ),
    );
  }
}