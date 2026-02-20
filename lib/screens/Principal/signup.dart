import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. IMPORT FIREBASE AUTH

class PrincipalRegistrationPage extends StatefulWidget {
  const PrincipalRegistrationPage({super.key});

  @override
  State<PrincipalRegistrationPage> createState() =>
      _PrincipalRegistrationPageState();
}

class _PrincipalRegistrationPageState extends State<PrincipalRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for fields
  final _nicController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _principalNameController = TextEditingController();
  final _principalMobileController = TextEditingController();
  // REMOVED: final _petNameController = TextEditingController();
  // REMOVED: final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Dropdown States
  String? _selectedSchoolType;
  final List<String> _schoolTypes = ['Provincial', 'Government'];

  // NEW: School District field mapped to Firestore 'office'
  String? _selectedDistrict;
  final List<String> _districts = ['Galle', 'Matara', 'Hambantota', 'Colombo']; // Example districts

  // State for UI
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Default values for consistency
  final bool _initialIsActiveStatus = false; // User starts as deactivated
  final String _defaultProfileImageUrl =
      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_Ldbm8TwlbnL43PId23vLdI3MgqhaNYf5.jpg';

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
    // REMOVED: _petNameController.dispose();
    // REMOVED: _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Registers the Principal in Firebase Auth and Firestore
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is invalid
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // --- 2. CREATE USER IN FIREBASE AUTH ---
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _schoolEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- 3. GET THE NEW USER'S UID ---
      String? uid = userCredential.user?.uid;

      if (uid != null) {
        
        // --- 4. CREATE THE DATA MAP ---
        final userData = {
          'userType': 'Principal', // Hardcoded for this page
          'nic': _nicController.text.trim().toUpperCase(),
          'schoolName': _schoolNameController.text.trim(),
          'schoolType': _selectedSchoolType,
          'office': _selectedDistrict, // NEW: Mapped School District to 'office'
          'email': _schoolEmailController.text.trim(),
          'officePhone': _schoolPhoneController.text.trim(),
          'name': _principalNameController.text.trim(),
          'mobilePhone': _principalMobileController.text.trim(),
          // REMOVED: 'securityQuestionPet' and 'securityQuestionNickname'
          'createdAt': Timestamp.now(),
          'isActive': _initialIsActiveStatus, // Automatically set to false (Pending Approval)
          'profile_image': _defaultProfileImageUrl,
        };

        // --- 5. SAVE USER DATA TO FIRESTORE USING THE AUTH UID ---
        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                    'Registration successful! Your account is currently deactivated and pending approval.')),
          );
          // Go back to the very first screen (usually login)
          Navigator.of(context).popUntil((route) => route.isFirst);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(message)));
      }
    } catch (e) {
      // Handle general errors (e.g., Firestore write failed)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Registration failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
              // --- FORM FIELDS ---
              _buildReadOnlyDropdown('User Type', 'Principal'),
              const SizedBox(height: 20),
              
              _buildSchoolTypeDropdown(), // School Type Dropdown
              const SizedBox(height: 20),

              _buildDistrictDropdown(), // NEW: School District Dropdown
              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _schoolNameController,
                labelText: 'School Name',
                icon: Icons.school_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the school name' : null,
              ),
              const SizedBox(height: 20),
              
              _buildTextFormField(
                controller: _nicController,
                labelText: 'Principal NIC Number',
                icon: Icons.badge_outlined,
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
                controller: _schoolEmailController,
                labelText: 'School Email Address (Login ID)',
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
              const SizedBox(height: 24),

              // REMOVED SECURITY QUESTIONS SECTION

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

  // --- HELPER WIDGETS ---

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
        labelText: 'Principal\'s Password (Min 6 characters)',
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
        if (value.length < 6) return 'Password must be at least 6 characters';
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
      hint: const Text('Select School Type'),
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

  // NEW: School District Dropdown (maps to 'office' field)
  Widget _buildDistrictDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDistrict,
      hint: const Text('Select School District'),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.location_city_outlined, color: Colors.grey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        filled: true,
        fillColor: _fillColor,
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedDistrict = newValue;
        });
      },
      items: _districts.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      validator: (value) => value == null ? 'Please select a district' : null,
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