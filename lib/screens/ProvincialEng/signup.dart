import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for input formatters
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ProvincialEngRegistrationPage extends StatefulWidget {
  const ProvincialEngRegistrationPage({super.key});

  @override
  State<ProvincialEngRegistrationPage> createState() =>
      _ProvincialEngRegistrationPageState();
}

class _ProvincialEngRegistrationPageState
    extends State<ProvincialEngRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all fields
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

  // State variables for real-time NIC validation
  Timer? _debounce;
  bool _isCheckingNic = false;
  String? _nicErrorText;
  
  @override
  void initState() {
    super.initState();
    // Listener to update the password strength indicator in real-time
    _passwordController.addListener(() {
      setState(() {});
    });
  }

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
    _debounce?.cancel(); // Cancel the timer on dispose
    super.dispose();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes); 
    return digest.toString();
  }
  
  // Function to check if NIC already exists in Firestore
  Future<void> _checkNicAvailability(String nic) async {
    if (nic.isEmpty) {
        if (mounted) {
            setState(() {
                _nicErrorText = null;
                _isCheckingNic = false;
            });
        }
        return;
    }

    if (mounted) {
        setState(() {
            _isCheckingNic = true;
            _nicErrorText = null;
        });
    }

    try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('nic', isEqualTo: nic)
            .limit(1)
            .get();

        if (mounted) {
            setState(() {
                if (querySnapshot.docs.isNotEmpty) {
                    _nicErrorText = 'This NIC is already registered.';
                } else {
                    _nicErrorText = null;
                }
                _isCheckingNic = false;
            });
        }
    } catch (e) {
        if (mounted) {
            setState(() {
                _nicErrorText = 'Error checking NIC.';
                _isCheckingNic = false;
            });
        }
    }
  }

  Future<void> _registerUser() async {
    // Added a check for the real-time NIC error
    if (_formKey.currentState!.validate() && _nicErrorText == null) {
      setState(() {
        _isLoading = true;
      });
      try {
        String plainPassword = _passwordController.text.trim();
        String hashedPassword = _hashPassword(plainPassword);

        await FirebaseFirestore.instance.collection('users').add({
          'name': _nameController.text.trim(),
          'nic': _nicController.text.trim().toUpperCase(), // Store NIC in uppercase
          'email': _emailController.text.trim(),
          'office': _selectedOffice,
          'officePhone': _officePhoneController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'securityQuestionPet': _petNameController.text.trim(),
          'securityQuestionNickname': _nicknameController.text.trim(),
          'password': hashedPassword,
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
    } else if (_nicErrorText != null){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_nicErrorText!)),
        );
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
              _buildReadOnlyDropdown('User Type', 'Provincial Engineer'),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _nameController,
                  labelText: 'Engineer\'s Name',
                  icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildNicFormField(),
              const SizedBox(height: 16),
              _buildDropdownFormField(),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _emailController,
                  labelText: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _officePhoneController,
                  labelText: 'Office Phone Number',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildMobileNumberFormField(),
              const SizedBox(height: 24),
              const Text("Security Questions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _petNameController,
                  labelText: 'First Pet Name'),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _nicknameController,
                  labelText: 'Childhood nickname'),
              const SizedBox(height: 24),
              _buildPasswordFormField(),
              const SizedBox(height: 8),
              PasswordStrengthIndicator(password: _passwordController.text),
              const SizedBox(height: 16),
              _buildConfirmPasswordFormField(),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
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
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Sign in'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildNicFormField() {
    return TextFormField(
      controller: _nicController,
      decoration: InputDecoration(
        labelText: 'NIC Number',
        helperText: 'e.g., 123456789V (old) or 199012345678 (new)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[100],
        suffixIcon: _isCheckingNic
            ? const Padding(
                padding: EdgeInsets.all(10.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        errorText: _nicErrorText,
      ),
      onChanged: (value) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 800), () {
          final nic = value.trim();
          if (RegExp(r'(^\d{9}[vVxX]$)|(^\d{12}$)').hasMatch(nic)) {
            _checkNicAvailability(nic.toUpperCase());
          } else {
            if (mounted) setState(() => _nicErrorText = null);
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field cannot be empty';
        }
        final nicRegex = RegExp(r'(^\d{9}[vVxX]$)|(^\d{12}$)');
        if (!nicRegex.hasMatch(value.trim())) {
          return 'Enter a valid Sri Lankan NIC';
        }
        return null;
      },
    );
  }

  Widget _buildMobileNumberFormField() {
    return TextFormField(
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        LengthLimitingTextInputFormatter(10),
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        suffixIcon: const Icon(Icons.phone_iphone, color: Color(0xFF53BDFF)),
        helperText: 'Must be a 10-digit SL number (e.g., 0712345678)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field cannot be empty';
        }
        final mobileRegex = RegExp(r'^07[0-9]{8}$');
        if (!mobileRegex.hasMatch(value)) {
          return 'Enter a valid 10-digit SL mobile number';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordFormField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Enter Your Password',
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters long';
        }
        if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
          return 'Password must contain a lowercase letter';
        }
        if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
          return 'Password must contain an uppercase letter';
        }
        if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
          return 'Password must contain a number';
        }
        if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
          return 'Password must contain a special character';
        }
        return null;
      },
    );
  }
  
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: icon != null ? Icon(icon, color:const Color(0xFF53BDFF)) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) =>
          value!.isEmpty ? 'This field cannot be empty' : null,
    );
  }

  Widget _buildConfirmPasswordFormField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Re-Enter Your Password',
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[100],
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

  Widget _buildDropdownFormField() {
    return DropdownButtonFormField<String>(
      value: _selectedOffice,
      hint: const Text('Select Your Office'),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[100],
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      child: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const PasswordStrengthIndicator({super.key, required this.password});

  Widget _buildValidationRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.remove_circle_outline,
            color: isValid ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: isValid ? Colors.green : Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'\d'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildValidationRow("At least 8 characters", hasMinLength),
        _buildValidationRow("Contains a lowercase letter", hasLowercase),
        _buildValidationRow("Contains an uppercase letter", hasUppercase),
        _buildValidationRow("Contains a number", hasNumber),
        _buildValidationRow("Contains a special character", hasSpecialChar),
      ],
    );
  }
}