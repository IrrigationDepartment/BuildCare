import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for input formatters
import 'package:cloud_firestore/cloud_firestore.dart';

// 💡 NEW IMPORT: Import the Dashboard for successful login navigation
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
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _officePhoneController.dispose();
    _mobileController.dispose();
    _petNameController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _debounce?.cancel();
    super.dispose();
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
    if (_formKey.currentState!.validate() && _nicErrorText == null) {
      setState(() {
        _isLoading = true;
      });
      try {
        String plainPassword = _passwordController.text.trim();

        await FirebaseFirestore.instance.collection('users').add({
          'name': _nameController.text.trim(),
          'nic': _nicController.text.trim().toUpperCase(),
          'email': _emailController.text.trim(),
          'office': _selectedOffice,
          'officePhone': _officePhoneController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'securityQuestionPet': _petNameController.text.trim(),
          'securityQuestionNickname': _nicknameController.text.trim(),
          'password': plainPassword, // Storing plain text password
          'userType': 'Provincial Engineer',
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful! Please login.')),
        );
        // Navigate to the new Login Page after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProvincialEngLoginPage(), 
          ),
        );
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
              _buildTextFormField(
                controller: _emailController,
                labelText: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownFormField(),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _officePhoneController,
                labelText: 'Office Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildMobileNumberFormField(),
              const SizedBox(height: 24),
              const Text(
                'Security Questions (For Password Recovery)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF53BDFF),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _petNameController,
                labelText: 'What is your childhood pet\'s name?',
                icon: Icons.pets_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _nicknameController,
                labelText: 'What was your childhood nickname?',
                icon: Icons.emoji_people_outlined,
              ),
              const SizedBox(height: 24),
              _buildPasswordFormField(),
              const SizedBox(height: 8),
              PasswordStrengthIndicator(password: _passwordController.text),
              const SizedBox(height: 16),
              _buildConfirmPasswordFormField(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53BDFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Register',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              // 🚀 NEW: Navigation link to Login Page
              const SizedBox(height: 16), 
              TextButton(
                onPressed: () {
                  // Navigate to the Login Page and replace the current route
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProvincialEngLoginPage(),
                    ),
                  );
                },
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    color: Color(0xFF53BDFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // --- Helper Widgets (Unchanged) ---
  // ----------------------------------------------------------------------

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: Icon(icon, color: const Color(0xFF53BDFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'This field cannot be empty';
            }
            return null;
          },
    );
  }
  
  // ... (Other helper widgets like _buildNicFormField, _buildMobileNumberFormField, _buildPasswordFormField, _buildConfirmPasswordFormField, _buildDropdownFormField, _buildReadOnlyDropdown, PasswordStrengthIndicator) remain the same. 
  // For brevity, I'll include only the full class content below, but assume these helper functions are in the main file.
  // Full implementation of helper widgets is necessary for a working application.
  
  // Re-including the helper widgets for completeness:

  Widget _buildNicFormField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nicController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: InputDecoration(
            labelText: 'National ID Number (NIC)',
            suffixIcon: _isCheckingNic
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : const Icon(Icons.credit_card_outlined,
                    color: Color(0xFF53BDFF)),
            helperText: 'Enter 9 digits + V/X or a 12-digit number',
            errorText: _nicErrorText, 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (nic) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              if (nic.length == 10 || nic.length == 12) {
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
        ),
      ],
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
        if (!mobileRegex.hasMatch(value.trim())) {
          return 'Enter a valid 10-digit mobile number starting with 07';
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
        labelText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF53BDFF),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        final hasMinLength = value.length >= 8;
        final hasLowercase = value.contains(RegExp(r'[a-z]'));
        final hasUppercase = value.contains(RegExp(r'[A-Z]'));
        final hasNumber = value.contains(RegExp(r'\d'));
        final hasSpecialChar =
            value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

        if (!hasMinLength ||
            !hasLowercase ||
            !hasUppercase ||
            !hasNumber ||
            !hasSpecialChar) {
          return 'Password does not meet all criteria below';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordFormField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF53BDFF),
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
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
      initialValue: _selectedOffice,
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
      validator: (value) {
        if (value == null) {
          return 'Please select your office';
        }
        return null;
      },
    );
  }

  Widget _buildReadOnlyDropdown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
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


// -----------------------------------------------------------------------------
// --- 2. Provincial Engineer LOGIN (Sign In) Page (NEW) ---
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
      setState(() {
        _isLoading = true;
      });

      final String loginId = _loginIdController.text.trim();
      final String password = _passwordController.text.trim();
      
      // Determine if the login ID is likely an email or NIC
      final bool isEmail = loginId.contains('@');
      final String fieldToQuery = isEmail ? 'email' : 'nic';

      try {
        // Query Firestore for a user with matching ID and password
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(fieldToQuery, isEqualTo: isEmail ? loginId : loginId.toUpperCase())
            .where('password', isEqualTo: password) // Matching against plain text password
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Success: User found and credentials match
          final userData = querySnapshot.docs.first.data();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, ${userData['name']}!')),
          );
          
          // Navigate to the Dashboard and remove all login/signup routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ProvincialEngineerDashboard(userData: userData),
            ),
            (Route<dynamic> route) => false,
          );

        } else {
          // Failure: Credentials do not match
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed: Invalid NIC/Email or Password.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred during login: $e')),
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
              const Icon(
                Icons.person_pin_circle_outlined,
                size: 100,
                color: Color(0xFF53BDFF),
              ),
              const SizedBox(height: 32),
              
              // NIC / Email Field
              TextFormField(
                controller: _loginIdController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'NIC or Email Address',
                  suffixIcon: const Icon(Icons.person_outline, color: Color(0xFF53BDFF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your NIC or Email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF53BDFF),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53BDFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              
              // Navigation link to Sign Up Page
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate back to the Registration Page and replace the current route
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProvincialEngRegistrationPage(),
                    ),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(
                    color: Color(0xFF53BDFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- END OF FILE ---
// -----------------------------------------------------------------------------