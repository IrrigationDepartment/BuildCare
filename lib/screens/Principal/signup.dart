import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrincipalRegistrationPage extends StatefulWidget {
  const PrincipalRegistrationPage({super.key});

  @override
  State<PrincipalRegistrationPage> createState() =>
      _PrincipalRegistrationPageState();
}

class _PrincipalRegistrationPageState extends State<PrincipalRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controllers for fields
  final _nicController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _principalNameController = TextEditingController();
  final _principalMobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus Nodes
  final _nicFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Dropdown States
  String? _selectedSchoolType;
  final List<String> _schoolTypes = ['Provincial', 'Government'];

  String? _selectedDistrict;
  final List<String> _districts = ['Galle', 'Matara', 'Hambantota'];

  // Autocomplete Data
  List<String> _availableSchools = [];

  // State for UI
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

  // NIC Duplicate state
  bool _isCheckingNic = false;
  bool _isNicDuplicate = false;

  // Default values
  final String _defaultProfileImageUrl =
      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_Ldbm8TwlbnL43PId23vLdI3MgqhaNYf5.jpg';

  @override
  void initState() {
    super.initState();
    _fetchSchoolsForAutocomplete();

    // Password validation listeners
    _passwordController.addListener(_validatePassword);
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });

    // NIC focus listener for duplication check
    _nicFocusNode.addListener(() {
      if (!_nicFocusNode.hasFocus) {
        _checkNicExists(_nicController.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _nicController.dispose();
    _schoolNameController.dispose();
    _schoolEmailController.dispose();
    _schoolPhoneController.dispose();
    _principalNameController.dispose();
    _principalMobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // --- PASSWORD VALIDATION LOGIC ---
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

  // --- FETCH SCHOOLS FOR AUTOCOMPLETE ---
  Future<void> _fetchSchoolsForAutocomplete() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('schools').get();
      if (mounted) {
        setState(() {
          _availableSchools = snapshot.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['schoolName']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching schools: $e");
    }
  }

  // --- NIC DUPLICATE CHECK LOGIC ---
  Future<bool> _checkNicExists(String nic) async {
    if (nic.isEmpty) return false;
    
    // Check if it contains lowercase 'v' before firestore call
    if (nic.contains('v')) {
      setState(() => _isNicDuplicate = false);
      return false;
    }

    setState(() => _isCheckingNic = true);
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nic', isEqualTo: nic.toUpperCase())
          .limit(1)
          .get();

      setState(() {
        _isNicDuplicate = querySnapshot.docs.isNotEmpty;
        _isCheckingNic = false;
      });
      return _isNicDuplicate;
    } catch (e) {
      debugPrint('Error checking NIC: $e');
      setState(() => _isCheckingNic = false);
      return false;
    }
  }

  // --- ERROR DIALOG ---
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

  // --- REGISTRATION LOGIC ---
  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Check password requirements
    if (!_has8Chars || !_hasLowercase || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Please ensure the password meets all security requirements.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Final NIC Duplicate Check
      final nicExists = await _checkNicExists(_nicController.text.trim());
      if (nicExists) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'NIC Already Exists',
          'A user with NIC number "${_nicController.text.trim().toUpperCase()}" is already registered.',
        );
        return;
      }

      // Create Firebase Auth Account
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _schoolEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      // Update Auth Display Name
      await userCredential.user!.updateDisplayName(_principalNameController.text.trim());

      // Save to Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'userType': 'Principal',
        'nic': _nicController.text.trim().toUpperCase(),
        'schoolName': _schoolNameController.text.trim(),
        'schoolType': _selectedSchoolType,
        'office': _selectedDistrict,
        'email': _schoolEmailController.text.trim().toLowerCase(),
        'officePhone': _schoolPhoneController.text.trim(),
        'name': _principalNameController.text.trim(),
        'mobilePhone': _principalMobileController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': false,
        'profile_image': _defaultProfileImageUrl,
        'emailVerified': false,
      });

      // Send Verification Email
      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('✓ Registration Successful! Verification email sent to ${_schoolEmailController.text.trim()}'),
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
      String errorDetails = e.message ?? 'An unknown error occurred.';

      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email Already Registered';
        errorDetails = 'An account with email "${_schoolEmailController.text.trim()}" already exists.';
      }

      _showErrorDialog(errorMessage, errorDetails);
    } catch (e) {
      _showErrorDialog('Registration Failed', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
              constraints: const BoxConstraints(maxWidth: 600),
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
                      const Icon(Icons.school, size: 56, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Principal Registration',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register your school and administrative account',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),

                      _buildReadOnlyDropdown('User Type', 'Principal'),
                      _buildSchoolTypeDropdown(),
                      _buildDistrictDropdown(),
                      _buildSchoolAutocompleteField(),

                      // --- UPDATED NIC FIELD ---
                      _buildTextFormField(
                        controller: _nicController,
                        labelText: 'Principal NIC Number',
                        icon: Icons.badge_outlined,
                        focusNode: _nicFocusNode,
                        errorText: _isNicDuplicate ? 'This NIC is already registered' : null,
                        suffixIcon: _isCheckingNic
                            ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(4.0), child: CircularProgressIndicator(strokeWidth: 2)))
                            : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'NIC cannot be empty';
                          
                          // Reject simple 'v' or 'x'
                          if (value.contains('v') || value.contains('x')) {
                            return 'Simple "v" or "x" is not allowed. Use Capital "V" or "X"';
                          }

                          // Regex strictly for Uppercase V/X or 12 digits
                          final nicRegex = RegExp(r'^(\d{9}[VX]|\d{12})$');
                          if (!nicRegex.hasMatch(value.trim())) {
                            return 'Invalid format. Use 123456789V or 12 digits';
                          }
                          return null;
                        },
                      ),

                      _buildTextFormField(
                        controller: _principalNameController,
                        labelText: 'Principal Name',
                        icon: Icons.person_outline,
                        validator: (value) => value!.isEmpty ? 'Please enter the principal\'s name' : null,
                      ),

                      _buildTextFormField(
                        controller: _principalMobileController,
                        labelText: 'Principal\'s Mobile Number',
                        icon: Icons.phone_iphone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'This field cannot be empty';
                          if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter a valid 10-digit mobile number';
                          return null;
                        },
                      ),

                      _buildTextFormField(
                        controller: _schoolPhoneController,
                        labelText: 'School Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'This field cannot be empty';
                          if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter a valid 10-digit phone number';
                          return null;
                        },
                      ),

                      _buildTextFormField(
                        controller: _schoolEmailController,
                        labelText: 'Email Address (Login ID)',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'This field cannot be empty';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) return 'Enter a valid email address';
                          return null;
                        },
                      ),

                      const Divider(height: 40),
                      Text('Password & Security', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 16),

                      _buildPasswordFormField(),
                      if (_isPasswordFocused)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
                          child: _buildPasswordValidationUI(),
                        ),
                      _buildConfirmPasswordFormField(),

                      const SizedBox(height: 32),

                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Complete Registration',
                                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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
        Icon(isValid ? Icons.check_circle : Icons.remove_circle_outline, color: isValid ? Colors.green : Colors.grey.shade500, size: 16),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: isValid ? Colors.green : Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labelText, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            focusNode: focusNode,
            decoration: _inputDecoration(icon: icon, suffixIcon: suffixIcon, errorText: errorText),
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFormField() {
    return _buildTextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      labelText: 'Principal\'s Password',
      icon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password cannot be empty';
        if (!_has8Chars || !_hasLowercase || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
          return 'Please meet requirements';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordFormField() {
    return _buildTextFormField(
      controller: _confirmPasswordController,
      labelText: 'Confirm Password',
      icon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
      ),
      validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
    );
  }

  Widget _buildSchoolTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        value: _selectedSchoolType,
        decoration: _inputDecoration(icon: Icons.category_outlined, labelText: 'School Type'),
        items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setState(() => _selectedSchoolType = v),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        value: _selectedDistrict,
        decoration: _inputDecoration(icon: Icons.location_city_outlined, labelText: 'District'),
        items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
        onChanged: (v) => setState(() => _selectedDistrict = v),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildSchoolAutocompleteField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Autocomplete<String>(
        optionsBuilder: (v) => _availableSchools.where((s) => s.toLowerCase().contains(v.text.toLowerCase())),
        onSelected: (s) => _schoolNameController.text = s,
        fieldViewBuilder: (ctx, ctrl, focus, onSub) {
          ctrl.addListener(() => _schoolNameController.text = ctrl.text);
          return TextFormField(
            controller: ctrl,
            focusNode: focus,
            decoration: _inputDecoration(icon: Icons.account_balance_outlined, labelText: 'School Name'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyDropdown(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: _inputDecoration(icon: Icons.work_outline, labelText: label, fillColor: Colors.grey.shade100),
      ),
    );
  }

  InputDecoration _inputDecoration({IconData? icon, String? labelText, Widget? suffixIcon, String? errorText, Color? fillColor}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent.shade200) : null,
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: fillColor ?? Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
    );
  }
}