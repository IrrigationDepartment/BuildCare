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

  // Controllers for fields
  final _nicController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _principalNameController = TextEditingController();
  final _principalMobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Dropdown States
  String? _selectedSchoolType;
  final List<String> _schoolTypes = ['Provincial', 'Government'];

  String? _selectedDistrict;
  final List<String> _districts = ['Galle', 'Matara', 'Hambantota'];

  // State for UI
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  final bool _initialIsActiveStatus = false;
  final String _defaultProfileImageUrl =
      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_Ldbm8TwlbnL43PId23vLdI3MgqhaNYf5.jpg';

  static const Color _primaryColor = Color(0xFF53BDFF);
  static final Color _fillColor = Colors.grey[200]!;

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
    super.dispose();
  }

  /// Registers the Principal in Firebase Auth and Firestore with Duplicate NIC Check
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final String nic = _nicController.text.trim().toUpperCase();

      // --- NEW: CHECK IF NIC ALREADY EXISTS IN FIRESTORE ---
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: nic)
          .get();

      final List<DocumentSnapshot> documents = result.docs;

      if (documents.isNotEmpty) {
        // If NIC already exists, show error and stop process
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.orange,
                content: Text('This NIC number is already registered.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // --- 2. CREATE USER IN FIREBASE AUTH ---
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _schoolEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String? uid = userCredential.user?.uid;

      if (uid != null) {
        // --- 4. CREATE THE DATA MAP ---
        final userData = {
          'userType': 'Principal', 
          'nic': nic,
          'schoolName': _schoolNameController.text.trim(),
          'schoolType': _selectedSchoolType,
          'office': _selectedDistrict, 
          'email': _schoolEmailController.text.trim(),
          'officePhone': _schoolPhoneController.text.trim(),
          'name': _principalNameController.text.trim(),
          'mobilePhone': _principalMobileController.text.trim(),
          'createdAt': Timestamp.now(),
          'isActive': _initialIsActiveStatus, 
          'profile_image': _defaultProfileImageUrl,
        };

        // --- 5. SAVE USER DATA TO FIRESTORE ---
        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Registration successful! Your account is pending approval.')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The email address is already in use.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
              _buildReadOnlyDropdown('User Type', 'Principal'),
              const SizedBox(height: 20),
              _buildSchoolTypeDropdown(), 
              const SizedBox(height: 20),
              _buildDistrictDropdown(), 
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
                    return 'Enter a valid SL NIC';
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
                  if (value == null || value.isEmpty) return 'Cannot be empty';
                  if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter 10 digits';
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
                  if (value == null || value.isEmpty) return 'Cannot be empty';
                  if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter 10 digits';
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
                  if (value == null || value.isEmpty) return 'Cannot be empty';
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildPasswordFormField(), 
              const SizedBox(height: 20),
              _buildConfirmPasswordFormField(),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                    child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
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
        labelText: 'Password (8+ chars, Uppercase, Lowercase, Number)',
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
        if (value.length < 8) return 'Password must be at least 8 characters long';
        if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])').hasMatch(value)) {
          return 'Include uppercase, lowercase, and a number';
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
      onChanged: (String? newValue) => setState(() => _selectedSchoolType = newValue),
      items: _schoolTypes.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      validator: (value) => value == null ? 'Please select a school type' : null,
    );
  }

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
      onChanged: (String? newValue) => setState(() => _selectedDistrict = newValue),
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