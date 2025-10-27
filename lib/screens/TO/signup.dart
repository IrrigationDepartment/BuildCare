import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class TORegistrationPage extends StatefulWidget {
  const TORegistrationPage({super.key});

  @override
  State<TORegistrationPage> createState() => _TORegistrationPageState();
}

class _TORegistrationPageState extends State<TORegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all the new fields
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _petNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State for User Type Dropdown
  String? _selectedUserType = 'Technical Officer'; // Pre-selected as in image
  final List<String> _userTypes = [
    //'Principal',
    'Technical Officer',
    //'District Eng.',
    //'Chief Eng.'
  ];

  // State for Office Dropdown
  String? _selectedOffice;
  final List<String> _offices = ['Galle', 'Matara', 'Hambantota'];

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    // Dispose all controllers to free up resources
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _officePhoneController.dispose();
    _mobileController.dispose();
    _petNameController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance.collection('users').add({
          'name': _nameController.text.trim(),
          'nic': _nicController.text.trim(),
          'email': _emailController.text.trim(),
          'office': _selectedOffice,
          'officePhone': _officePhoneController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'securityQuestionPet': _petNameController.text.trim(),
          'securityQuestionNickname': _nicknameController.text.trim(),
          'password': _passwordController.text.trim(), // Storing the password
          'userType': _selectedUserType, // Use the selected user type
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful! Please login.')),
        );
        Navigator.of(context)
            .popUntil((route) => route.isFirst); // Go back to login
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark background like in the image
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: SingleChildScrollView(
          // Padding for the whole screen
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // "Signup (TO)" Title
              const Text(
                'Signup (TO)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // The white form card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- FORM FIELDS ---
                      _buildLabel('User Type'),
                      _buildUserTypeDropdown(),
                      const SizedBox(height: 16),

                      _buildLabel('Technical Officer Name'),
                      _buildTextFormField(
                        controller: _nameController,
                        hintText: 'Enter Your Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('NIC Number'),
                      _buildTextFormField(
                        controller: _nicController,
                        hintText: 'Enter Your NIC',
                        icon: Icons.badge_outlined, // Icon from image
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Select Your Office'),
                      _buildOfficeDropdown(),
                      const SizedBox(height: 16),

                      _buildLabel('Email'),
                      _buildTextFormField(
                        controller: _emailController,
                        hintText: 'Enter Your Email Adress', // Typo matches image
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Office Phone Number'),
                      _buildTextFormField(
                        controller: _officePhoneController,
                        hintText: 'Enter Your Office Phone Number',
                        icon: Icons.local_phone_outlined, // Icon from image
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Mobile Number'),
                      _buildTextFormField(
                        controller: _mobileController,
                        hintText: 'Enter Your Mobile Number',
                        icon: Icons.phone_android_outlined, // Icon from image
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('First Pet Name'),
                      _buildTextFormField(
                        controller: _petNameController,
                        hintText: 'Enter Your First Pet Name',
                        // No icon
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Childhood nickname'),
                      _buildTextFormField(
                        controller: _nicknameController,
                        hintText: 'Enter Your Childhood nickname',
                        // No icon
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Enter Your Password'),
                      _buildPasswordFormField(),
                      const SizedBox(height: 16),

                      _buildLabel('Enter Password Again'),
                      _buildConfirmPasswordFormField(),
                      const SizedBox(height: 30),

                      // --- SIGN UP BUTTON ---
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _registerUser,
                              style: ElevatedButton.styleFrom(
                                // Bright blue from image
                                backgroundColor: const Color(0xFF37B5FA),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Footer: Moved outside the card ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already Registered?",
                    style: TextStyle(color: Colors.grey), // Text on dark bg
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: Color(0xFF37B5FA), // Match button blue
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS FOR FORM FIELDS ---

  /// Helper widget to create the label above the text field
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Helper for standard text fields
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        suffixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No border by default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.blueAccent, width: 2), // Blue on focus
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5), // Light grey fill
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) =>
          value!.isEmpty ? 'This field cannot be empty' : null,
    );
  }

  /// Helper for the Password field
  Widget _buildPasswordFormField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Enter Your Password',
        hintStyle: TextStyle(color: Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  /// Helper for the Confirm Password field
  Widget _buildConfirmPasswordFormField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Re-Enter Your Password',
        hintStyle: TextStyle(color: Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  /// Helper for the Office selection dropdown
  Widget _buildOfficeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedOffice,
      hint: Text('select your office',
          style: TextStyle(color: Colors.grey[500])),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // This focused border will match the blue highlight in the image
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedOffice = newValue;
        });
      },
      items: _offices.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select an office' : null,
    );
  }

  /// Helper for the User Type selection dropdown
  Widget _buildUserTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUserType,
      hint: Text('Select Your Roll',
          style: TextStyle(color: Colors.grey[500])),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedUserType = newValue;
        });
      },
      items: _userTypes.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select a role' : null,
    );
  }
}