import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TORegistrationPage extends StatefulWidget {
  const TORegistrationPage({super.key});

  @override
  State<TORegistrationPage> createState() => _TORegistrationPageState();
}

class _TORegistrationPageState extends State<TORegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all the fields
  final _userTypeController =
      TextEditingController(text: 'Technical Officer');
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State for the 'isActive' flag
  final bool _initialIsActiveStatus = false;

  // Default Profile Image URL
  final String _defaultProfileImageUrl =
      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_Ldbm8TwlbnL43PId23vLdI3MgqhaNYf5.jpg';

  final _passwordFocusNode = FocusNode();
  final _nicFocusNode = FocusNode();

  String? _selectedOffice;
  final List<String> _offices = ['Galle', 'Matara', 'Hambantota'];

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isPasswordFocused = false;
  bool _has8Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  bool _isCheckingNic = false;
  bool _isNicDuplicate = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error checking NIC: $e'),
          backgroundColor: Colors.red,
        ));
      }
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
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
          'userType': 'Technical Officer',
          'createdAt': Timestamp.now(),
          'isActive': _initialIsActiveStatus,
          'profile_image': _defaultProfileImageUrl,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                    'Registration successful! Your account is currently deactivated.')),
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Signup (TO)',
                    style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
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
                            isReadOnly: true,
                            controller: _userTypeController,
                            validator: (value) => null),
                        _buildLabeledTextField(
                            label: 'Technical Officer Name',
                            hint: 'Enter Your Name',
                            controller: _nameController,
                            icon: Icons.person_outline),
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
                              if (value == null || value.isEmpty) {
                                return 'NIC cannot be empty';
                              }
                              final nicRegex =
                                  RegExp(r'^(\d{9}[vVxX]|\d{12})$');
                              if (!nicRegex.hasMatch(value)) {
                                return 'Invalid Sri Lankan NIC format';
                              }
                              return null;
                            }),
                        _buildLabeledDropdown(
                            label: 'Select Your Office',
                            hint: 'Select an Office',
                            value: _selectedOffice,
                            items: _offices,
                            onChanged: (newValue) =>
                                setState(() => _selectedOffice = newValue)),
                        _buildLabeledTextField(
                            label: 'Email',
                            hint: 'Enter Your Email Adress',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email cannot be empty';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
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
                              if (!phoneRegex.hasMatch(value)) {
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
                              if (!phoneRegex.hasMatch(value)) {
                                return 'Mobile number must be 10 digits';
                              }
                              return null;
                            }),

                        // Password Field
                        _buildLabeledTextField(
                            label: 'Enter Your Password',
                            hint: 'Enter Your Password',
                            controller: _passwordController,
                            isPassword: true,
                            isPasswordVisible: _isPasswordVisible,
                            focusNode: _passwordFocusNode,
                            onVisibilityToggle: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password cannot be empty';
                              }
                              if (!_has8Chars ||
                                  !_hasLowercase ||
                                  !_hasUppercase ||
                                  !_hasNumber ||
                                  !_hasSpecialChar) {
                                return 'Please meet all password requirements';
                              }
                              return null;
                            }),

                        if (_isPasswordFocused)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 8.0, bottom: 8.0, left: 4.0),
                            child: _buildPasswordValidationUI(),
                          ),

                        _buildLabeledTextField(
                            label: 'Re-Enter Your Password',
                            hint: 'Re-Enter Your Password',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            isPasswordVisible: _isConfirmPasswordVisible,
                            onVisibilityToggle: () => setState(() =>
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            }),
                        const SizedBox(height: 30),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: _registerUser,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF53BDFF),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30))),
                                    child: const Text('Sign Up',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            fontWeight: FontWeight.bold))))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordValidationUI() {
    return Column(
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
    );
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.remove_circle_outline,
          color: isValid ? Colors.green : Colors.grey.shade600,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.grey.shade600,
            fontSize: 14,
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
              style: const TextStyle(color: Color.fromARGB(221, 58, 58, 58)),
              decoration: _inputDecoration(
                hint,
                isChecking ? null : icon,
                isChecking
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
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
                  (value) => value!.isEmpty ? '$label cannot be empty' : null)
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
              value: value,
              items: items
                  .map((String office) => DropdownMenuItem<String>(
                      value: office, child: Text(office)))
                  .toList(),
              onChanged: onChanged,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: _inputDecoration(hint, null, null, null),
              validator: (value) =>
                  value == null ? 'Please select an option' : null)
        ]));
  }

  InputDecoration _inputDecoration(
      String hintText, IconData? icon, Widget? suffixIcon, String? errorText) {
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
                : null));
  }
}