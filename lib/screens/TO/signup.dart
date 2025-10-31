import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TORegistrationPage extends StatefulWidget {
  const TORegistrationPage({super.key});

  @override
  State<TORegistrationPage> createState() => _TORegistrationPageState();
}

class _TORegistrationPageState extends State<TORegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _petNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedUserType;
  String? _selectedOffice;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Office options - make sure this is properly initialized
  final List<String> _officeOptions = ['Galle', 'Matara', 'Hambanthota'];

  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Create a map with only non-null values
        final Map<String, dynamic> userData = {
          'name': _nameController.text.trim(),
          'nic': _nicController.text.trim(),
          'email': _emailController.text.trim(),
          'officePhone': _officePhoneController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'petName': _petNameController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'password': _passwordController.text.trim(),
          'createdAt': Timestamp.now(),
        };

        // Add optional fields only if they are not null
        if (_selectedUserType != null) {
          userData['userType'] = _selectedUserType;
        }
        
        if (_selectedOffice != null) {
          userData['office'] = _selectedOffice;
        }

        await FirebaseFirestore.instance.collection('users').add(userData);

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
  void dispose() {
    // Clean up all controllers
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Technical Officer'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Type Dropdown
              _buildLabel('User Type'),
              const SizedBox(height: 8),
              _buildDropdownFormField(
                value: _selectedUserType,
                hintText: 'Select Your Roll',
                items: const [
                  DropdownMenuItem(value: 'Technical Officer', child: Text('Technical Officer')),
                  //DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  //DropdownMenuItem(value: 'User', child: Text('User')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value;
                  });
                },
                validator: (value) => value == null ? 'Please select user type' : null,
              ),
              const SizedBox(height: 20),

              // Technical Officer Name
              _buildLabel('Technical Officer Name'),
              const SizedBox(height: 8),
              _buildTextFormField(
                controller: _nameController,
                hintText: 'Enter Your Name',
                icon: Icons.person,
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),

              // NIC Number
              _buildLabel('NIC Number'),
              const SizedBox(height: 8),
              _buildTextFormField(
                controller: _nicController,
                hintText: 'Enter Your NIC',
                icon: Icons.badge,
                validator: (value) => value!.isEmpty ? 'Please enter your NIC' : null,
              ),
              const SizedBox(height: 20),

              // Select Your Office Dropdown
              _buildLabel('Select Your Office'),
              const SizedBox(height: 8),
              _buildDropdownFormField(
                value: _selectedOffice,
                hintText: 'select your office',
                items: _officeOptions.map((office) {
                  return DropdownMenuItem(
                    value: office,
                    child: Text(office),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOffice = value;
                  });
                },
                validator: (value) => value == null ? 'Please select your office' : null,
              ),
              const SizedBox(height: 20),

              // Email
              _buildLabel('Email'),
              const SizedBox(height: 8),
              _buildTextFormField(
                controller: _emailController,
                hintText: 'Enter Your Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 20),

              // Office Phone Number
              _buildLabel('Office Phone Number'),
              const SizedBox(height: 8),
              _buildTextFormField(
                controller: _officePhoneController,
                hintText: 'Enter Your Office Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter office phone number' : null,
              ),
              const SizedBox(height: 20),

              // Mobile Number
              _buildLabel('Mobile Number'),
              const SizedBox(height: 8),
              _buildTextFormField(
                controller: _mobileController,
                hintText: 'Enter Your Mobile Number',
                icon: Icons.phone_iphone,
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your mobile number' : null,
              ),
              const SizedBox(height: 20),

              // First Pet Name
              _buildLabel('First Pet Name'),
              const SizedBox(height: 8),
              _buildTextFormField(
                controller: _petNameController,
                hintText: 'Enter Your First Pet Name',
                icon: Icons.pets,
                validator: (value) => value!.isEmpty ? 'Please enter your first pet name' : null,
              ),
              const SizedBox(height: 20),

              // Childhood nickname
              _buildLabel('Childhood nickname'),
              const SizedBox(height: 8),
              _buildTextFormField(
                controller: _nicknameController,
                hintText: 'Enter Your Childhood nickname',
                icon: Icons.face,
                validator: (value) => value!.isEmpty ? 'Please enter your childhood nickname' : null,
              ),
              const SizedBox(height: 20),

              // Enter Your Password
              _buildLabel('Enter Your Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Enter Your Password',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) => value!.isEmpty ? 'Please enter password' : null,
              ),
              const SizedBox(height: 20),

              // Enter Password Again
              _buildLabel('Enter Password Again'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  hintText: 'Re-Enter Your Password',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please re-enter password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Divider
              const Divider(thickness: 1),
              const SizedBox(height: 20),

              // Sign Up Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // Already Registered Link
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Already Registered ? Sign in',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for labels
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Helper method for text form fields
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        suffixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  // Helper method for dropdown form fields
  Widget _buildDropdownFormField({
    required String? value,
    required String hintText,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          hintText: hintText,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}