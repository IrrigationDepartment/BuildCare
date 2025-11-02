import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/login.dart'; // For navigating back to the login page

class ProvincialEngRegistrationPage extends StatefulWidget {
  const ProvincialEngRegistrationPage({super.key});

  @override
  State<ProvincialEngRegistrationPage> createState() =>
      _ProvincialEngRegistrationPageState();
}

class _ProvincialEngRegistrationPageState
    extends State<ProvincialEngRegistrationPage> {
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

  String? _selectedOffice;
  final List<String> _offices = ['Galle', 'Matara', 'Hambantota'];

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // --- NEW: Define the primary color ---
  static const Color _primaryColor = Color(0xFF53BDFF);
  // Define the fill color from login.dart
  static final Color _fillColor = Colors.grey[200]!;

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
    // This will now trigger all the new validation rules
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // --- SECURITY NOTE ---
        // Storing plain-text passwords is not secure.
        // Please use Firebase Authentication for a real app.
        // This code proceeds based on your current app structure.
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
          'userType': 'Provincial Engineer',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register Provincial Engineer'),
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
              // --- FORM FIELDS ---
              _buildReadOnlyDropdown('User Type', 'Provincial Engineer'),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Engineer\'s Name',
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? 'This field cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _nicController,
                labelText: 'NIC Number',
                icon: Icons.badge_outlined,
                // --- NEW: Added NIC validation ---
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  final nicRegex = RegExp(r'(^(\d{12})|(\d{9}[vVxX])$)');
                  if (!nicRegex.hasMatch(value.trim())) {
                    return 'Enter a valid SL NIC (e.g., 123456789V or 200012345678)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildDropdownFormField(),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _emailController,
                labelText: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                // --- NEW: Added Email validation ---
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _officePhoneController,
                labelText: 'Office Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                // --- NEW: Added 10-digit validation for office phone ---
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
                controller: _mobileController,
                labelText: 'Mobile Number',
                icon: Icons.phone_iphone,
                keyboardType: TextInputType.phone,
                // --- NEW: Added +94 mobile validation ---
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  final phoneRegex = RegExp(r'^\+94\d{9}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Enter a valid number (e.g., +94712345678)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text("Security Questions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

              // --- SIGN UP BUTTON (STYLED) ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        // --- UPDATED: Color and curve ---
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Sign Up',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already Registered?"),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: const Text(
                      'Sign in',
                      // --- UPDATED: Style to match login page ---
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

  // --- HELPER WIDGETS (STYLED LIKE LOGIN.DART) ---

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
        // --- UPDATED: Style ---
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
        labelText: 'Enter Your Password',
        // --- UPDATED: Style ---
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _fillColor,
      ),
      // --- NEW: Updated validation rules ---
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length <= 6) {
          return 'Password must be more than 6 characters';
        }
        if (!value.contains(RegExp(r'[A-Z]'))) {
          return 'Must contain at least one capital letter';
        }
        if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
          return 'Must contain at least one special character';
        }
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
        labelText: 'Re-Enter Your Password',
        // --- UPDATED: Style ---
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _fillColor,
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildDropdownFormField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedOffice,
      hint: const Text('Select Your Office'),
      decoration: InputDecoration(
        // --- UPDATED: Style ---
        prefixIcon: Icon(Icons.business_outlined, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _fillColor,
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

  Widget _buildReadOnlyDropdown(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        // --- UPDATED: Style ---
        prefixIcon: Icon(Icons.work_outline, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[300], // Make it look disabled
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
        child: Text(value,
            style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ),
    );
  }
}
