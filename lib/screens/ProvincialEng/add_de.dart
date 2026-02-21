import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DistrictEngRegistrationPage extends StatefulWidget {
  const DistrictEngRegistrationPage({super.key});

  @override
  State<DistrictEngRegistrationPage> createState() =>
      _DistrictEngRegistrationPageState();
}

class _DistrictEngRegistrationPageState
    extends State<DistrictEngRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all the fields
  final _userTypeController = TextEditingController(text: 'District Engineer');
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final bool _initialIsActiveStatus = false; // User starts as deactivated

  final String _defaultProfileImageUrl =
      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_Ldbm8TwlbnL43PId23vLdI3MgqhaNYf5.jpg';

  // FocusNodes
  final _passwordFocusNode = FocusNode();
  final _nicFocusNode = FocusNode(); // <-- For real-time NIC check

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

  // State variables for NIC check
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

  // --- Real-time NIC check when focus is lost ---
  void _onNicFocusChange() {
    if (!_nicFocusNode.hasFocus) {
      _checkNicDuplication();
    }
  }

  Future<void> _checkNicDuplication() async {
    final nic = _nicController.text.trim().toUpperCase();

    // Don't check if empty or invalid format
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
      print("Error checking NIC: $e");
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

    if (!_has8Chars || !_hasLowercase || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Please ensure the password meets all security requirements.')));
      return;
    }

    // Final NIC check before submit to prevent race conditions
    await _checkNicDuplication();
    if (_isNicDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('This NIC is already registered. Please check again.'),
      ));
      return; 
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String? uid = userCredential.user?.uid;

      if (uid != null) {
        final userData = {
          'name': _nameController.text.trim(),
          'nic': _nicController.text.trim().toUpperCase(),
          'email': _emailController.text.trim(),
          'office': _selectedOffice,
          'officePhone': _officePhoneController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'userType': 'District Engineer',
          'createdAt': Timestamp.now(),
          'isActive': _initialIsActiveStatus, 
          'profile_image': _defaultProfileImageUrl,
        };

        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Registration successful! Your account is pending approval.')),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The email address is already in use by another account.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.redAccent, content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent, content: Text('Registration failed: $e')));
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
                      const Icon(Icons.map_outlined, size: 56, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'District Engineer Signup',
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
                          label: 'District Engineer Name',
                          hint: 'Enter Your Name',
                          controller: _nameController,
                          icon: Icons.person_outline),

                      // --- NIC Field (with real-time check) ---
                      _buildLabeledTextField(
                        label: 'NIC Number',
                        hint: 'e.g., 123456789V or 199012345678',
                        controller: _nicController,
                        icon: Icons.credit_card,
                        focusNode: _nicFocusNode,
                        errorText: _isNicDuplicate ? 'This NIC is already registered' : null,
                        suffixIcon: _isCheckingNic
                            ? const Padding(
                                padding: EdgeInsets.all(14.0),
                                child: SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NIC cannot be empty';
                          }
                          final nicRegex = RegExp(r'^(\d{9}[vVxX]|\d{12})$');
                          if (!nicRegex.hasMatch(value.trim())) {
                            return 'Invalid Sri Lankan NIC format';
                          }
                          return null;
                        },
                      ),

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
                            if (value == null || value.isEmpty) {
                              return 'Email cannot be empty';
                            }
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
                            if (value == null || value.isEmpty) {
                              return 'Office number cannot be empty';
                            }
                            final phoneRegex = RegExp(r'^\d{10}$');
                            if (!phoneRegex.hasMatch(value.trim())) {
                              return 'Office number must be 10 digits';
                            }
                            return null;
                          }),

                      _buildLabeledTextField(
                          label: 'Mobile Number',
                          hint: 'Enter 10-digit number',
                          controller: _mobileController,
                          icon: Icons.phone_iphone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mobile number cannot be empty';
                            }
                            final phoneRegex = RegExp(r'^\d{10}$');
                            if (!phoneRegex.hasMatch(value.trim())) {
                              return 'Mobile number must be 10 digits';
                            }
                            return null;
                          }),

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