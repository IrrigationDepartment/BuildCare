import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. IMPORT FIREBASE AUTH

class TORegistrationPage extends StatefulWidget {
  const TORegistrationPage({super.key});

  @override
  State<TORegistrationPage> createState() => _TORegistrationPageState();
}

class _TORegistrationPageState extends State<TORegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all the fields
  final _userTypeController =
      TextEditingController(text: 'Technical Officer'); // MODIFIED
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _petNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // NEW: State for the 'isActive' flag
  final bool _initialIsActiveStatus = false; // User starts as deactivated

  // --- ADDED: Default Profile Image URL ---
  final String _defaultProfileImageUrl =
      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_Ldbm8TwlbnL43PId23vLdI3MgqhaNYf5.jpg';

  // NEW: FocusNodes
  final _passwordFocusNode = FocusNode();
  final _nicFocusNode = FocusNode(); // <-- For NIC check

  String? _selectedOffice;
  final List<String> _offices = ['Galle', 'Matara', 'Hambantota'];

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // NEW: State variables for password validation UI
  bool _isPasswordFocused = false;
  bool _has8Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  // --- NEW: State variables for NIC check ---
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

    // --- ADDED: NIC Focus listener ---
    _nicFocusNode.addListener(_onNicFocusChange);
  }

  @override
  void dispose() {
    // Dispose all controllers
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

    // Dispose listeners and FocusNodes
    _passwordController.removeListener(_validatePassword);
    _passwordFocusNode.dispose();

    // --- ADDED: Dispose NIC listener and node ---
    _nicFocusNode.removeListener(_onNicFocusChange);
    _nicFocusNode.dispose();

    super.dispose();
  }

  // --- ADDED: Function to check NIC when focus is lost ---
  void _onNicFocusChange() {
    // If the user is no longer focused on the NIC field, check the value
    if (!_nicFocusNode.hasFocus) {
      _checkNicDuplication();
    }
  }

  // --- ADDED: The database check logic ---
  Future<void> _checkNicDuplication() async {
    final nic = _nicController.text.trim().toUpperCase();

    // Don't check if empty or invalid format
    if (nic.isEmpty) return;
    final nicRegex = RegExp(r'^(\d{9}[vVxX]|\d{12})$');
    if (!nicRegex.hasMatch(nic)) return;

    setState(() {
      _isCheckingNic = true;
      _isNicDuplicate = false; // Reset status
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

  // NEW: Function to validate password in real-time
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

  // --- (!!!) MODIFIED: Firebase Registration Logic ---
  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is invalid
    }

    // Perform password validation check
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

    // --- ADDED: Final NIC check before submit ---
    // Run the check one last time in case the user didn't lose focus
    await _checkNicDuplication();
    if (_isNicDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('This NIC is already registered.'),
        ));
      }
      return; // Stop submission
    }
    // --- END ---

    setState(() => _isLoading = true);

    try {
      // --- 2. CREATE USER IN FIREBASE AUTH ---
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- 3. GET THE NEW USER'S UID ---
      String? uid = userCredential.user?.uid;

      if (uid != null) {
        // --- 4. CREATE THE DATA MAP (WITHOUT PASSWORD) ---
        final userData = {
          'name': _nameController.text.trim(),
          'nic': _nicController.text.trim().toUpperCase(),
          'email': _emailController.text.trim(),
          'office': _selectedOffice,
          'officePhone': _officePhoneController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'securityQuestionPet': _petNameController.text.trim(),
          'securityQuestionNickname': _nicknameController.text.trim(),
          // --- NO PASSWORD SAVED TO FIRESTORE ---
          'userType': 'Technical Officer',
          'createdAt': Timestamp.now(),
          'isActive': _initialIsActiveStatus, // Automatically set to false
          'profile_image': _defaultProfileImageUrl,
        };

        // --- 5. SAVE USER DATA TO FIRESTORE USING THE AUTH UID ---
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
      // --- 6. HANDLE AUTHENTICATION ERRORS ---
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
      // Handle general errors (e.g., Firestore write failed)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Registration failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Main Build Method ---
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
                        // --- Form Fields ---
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

                        // --- MODIFIED: NIC Field ---
                        _buildLabeledTextField(
                            label: 'NIC Number',
                            hint: 'e.g., 123456789V or 199012345678',
                            controller: _nicController,
                            icon: Icons.credit_card,
                            focusNode: _nicFocusNode, // <-- Added FocusNode
                            isChecking: _isCheckingNic, // <-- Added check state
                            errorText: _isNicDuplicate // <-- Added error
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
                        // --- END MODIFICATION ---

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
                        _buildLabeledTextField(
                            label: 'First Pet Name',
                            hint: 'Enter Your First Pet Name',
                            controller: _petNameController),
                        _buildLabeledTextField(
                            label: 'Childhood nickname',
                            hint: 'Enter Your Childhood nickname',
                            controller: _nicknameController),

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

  // --- Helper method to show info dialog ---
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: <Widget>[
            TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop())
          ],
        );
      },
    );
  }

  // NEW: Widget to display the entire password validation checklist
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

  // NEW: Widget for a single row in the validation checklist
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

  // --- Helper Widgets for Form Fields ---
  // --- MODIFIED: Added FocusNode, errorText, and isChecking ---
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
    String? infoMessage,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    String? errorText, // <-- For NIC error
    bool isChecking = false, // <-- For spinner
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color.fromARGB(179, 0, 0, 0), fontSize: 14)),
              if (infoMessage != null)
                IconButton(
                  icon: Icon(Icons.info_outline,
                      color: Colors.grey.shade500, size: 20),
                  onPressed: () =>
                      _showInfoDialog(context, 'Password Guide', infoMessage),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
              controller: controller,
              focusNode: focusNode, // <-- Use the FocusNode
              readOnly: isReadOnly,
              obscureText: isPassword && !isPasswordVisible,
              keyboardType: keyboardType,
              style: const TextStyle(color: Color.fromARGB(221, 58, 58, 58)),
              decoration: _inputDecoration(
                hint,
                isChecking ? null : icon, // <-- Hide icon if checking
                isChecking
                    ? const Padding(
                        // <-- Show spinner if checking
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                      )
                    : (isPassword // <-- Show password toggle
                        ? IconButton(
                            icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF53BDFF)),
                            onPressed: onVisibilityToggle)
                        : null),
                errorText, // <-- Pass error text
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
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: _inputDecoration(hint, null, null, null),
              validator: (value) =>
                  value == null ? 'Please select an option' : null)
        ]));
  }

  // --- MODIFIED: Added errorText parameter ---
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

        // --- MODIFIED: Pass the errorText ---
        errorText: errorText,
        suffixIcon: suffixIcon ?? // <-- Use the custom suffix first
            (icon != null // <-- Otherwise, use the default icon
                ? Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(icon, color: const Color(0xFF53BDFF)))
                : null));
  }
}
