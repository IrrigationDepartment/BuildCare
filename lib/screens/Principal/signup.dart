import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrincipalRegistrationPage extends StatefulWidget {
  const PrincipalRegistrationPage({super.key});

  @override
  State<PrincipalRegistrationPage> createState() =>
      _PrincipalRegistrationPageState();
}

class _PrincipalRegistrationPageState extends State<PrincipalRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all the fields from your design
  final _nicController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _principalNameController = TextEditingController();
  final _principalMobileController = TextEditingController();
  final _petNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State for the School Type dropdown
  String? _selectedSchoolType;
  final List<String> _schoolTypes = ['Provincial', 'Government'];

  // State for UI
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Re-using the theme colors from your example
  static const Color _primaryColor = Color(0xFF53BDFF);
  static final Color _fillColor = Colors.grey[200]!;

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _nicController.dispose();
    _schoolNameController.dispose();
    _schoolEmailController.dispose();
    _schoolPhoneController.dispose();
    _principalNameController.dispose();
    _principalMobileController.dispose();
    _petNameController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Registers the Principal in Firestore
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Add a new document to the 'users' collection
        await FirebaseFirestore.instance.collection('users').add({
          // Mapping fields from your form to the Firebase structure
          'userType': 'Principal', // Hardcoded for this page
          'nic': _nicController.text.trim(),
          'schoolName': _schoolNameController.text.trim(), // Using a clear field name
          'schoolType': _selectedSchoolType,
          'email': _schoolEmailController.text.trim(), // Corresponds to School Email
          'officePhone': _schoolPhoneController.text.trim(), // Corresponds to School Phone
          'name': _principalNameController.text.trim(), // Corresponds to Principal Name
          'mobilePhone': _principalMobileController.text.trim(), // Corresponds to Principal Mobile
          'securityQuestionPet': _petNameController.text.trim(),
          'securityQuestionNickname': _nicknameController.text.trim(),
          'password': _passwordController.text.trim(), // Storing password
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful! Please login.')),
        );
        // Go back to the very first screen (usually login)
        Navigator.of(context).popUntil((route) => route.isFirst);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register Principal'),
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
              // --- FORM FIELDS AS PER YOUR DESIGN ---
              _buildReadOnlyDropdown('User Type', 'Principal'),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _nicController,
                labelText: 'NIC Number',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  // Standard Sri Lankan NIC validation
                  final nicRegex = RegExp(r'(^(\d{12})|(\d{9}[vVxX])$)');
                  if (!nicRegex.hasMatch(value.trim())) {
                    return 'Enter a valid SL NIC (e.g., 123456789V)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _schoolNameController,
                labelText: 'School Name',
                icon: Icons.school_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the school name' : null,
              ),
              const SizedBox(height: 20),
              _buildSchoolTypeDropdown(),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _schoolEmailController,
                labelText: 'School Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _schoolPhoneController,
                labelText: 'School Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  final phoneRegex = RegExp(r'^\d{10}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _principalNameController,
                labelText: 'Principal Name',
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the principal\'s name' : null,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _principalMobileController,
                labelText: 'Principal\'s Mobile Number',
                icon: Icons.phone_iphone,
                keyboardType: TextInputType.phone,
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                   // Allows 10 digits (e.g., 0712345678)
                  final phoneRegex = RegExp(r'^\d{10}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text("Security Questions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _petNameController,
                labelText: 'First Pet Name',
                icon: Icons.pets_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'This field cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _nicknameController,
                labelText: 'Childhood nickname',
                icon: Icons.child_care_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'This field cannot be empty' : null,
              ),
              const SizedBox(height: 24),
              _buildPasswordFormField(),
              const SizedBox(height: 20),
              _buildConfirmPasswordFormField(),
              const SizedBox(height: 30),

              // --- SIGN UP BUTTON ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already Registered?"),
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
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

  // --- HELPER WIDGETS (ADAPTED FROM YOUR EXAMPLE) ---

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _fillColor,
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildPasswordFormField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Principal\'s Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        filled: true,
        fillColor: _fillColor,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a password';
        if (value.length <= 6) return 'Password must be more than 6 characters';
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildConfirmPasswordFormField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Enter Password Again',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        filled: true,
        fillColor: _fillColor,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please confirm your password';
        if (value != _passwordController.text) return 'Passwords do not match';
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildSchoolTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSchoolType,
      hint: const Text('Select a school type'),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.category_outlined, color: Colors.grey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        filled: true,
        fillColor: _fillColor,
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSchoolType = newValue;
        });
      },
      items: _schoolTypes.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      validator: (value) => value == null ? 'Please select a school type' : null,
    );
  }

  Widget _buildReadOnlyDropdown(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.work_outline, color: Colors.grey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[300],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
        child: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ),
    );
  }
}