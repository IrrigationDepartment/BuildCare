import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChiefEngRegistrationPage extends StatefulWidget {
  const ChiefEngRegistrationPage({super.key});

  @override
  State<ChiefEngRegistrationPage> createState() =>
      _ChiefEngRegistrationPageState();
}

class _ChiefEngRegistrationPageState extends State<ChiefEngRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _userTypeController = TextEditingController(text: 'Chief Engineer');
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _passwordFocusNode = FocusNode();

  String? _selectedOffice;
  final List<String> _offices = ['Galle', 'Matara', 'Hambantota'];

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordFocused = false;
  bool _has8Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _userTypeController.dispose();
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _officePhoneController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordController.removeListener(_validatePassword);
    _passwordFocusNode.dispose();
    super.dispose();
  }

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

  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('users').add({
          'name': _nameController.text.trim(),
          'nic': _nicController.text.trim().toUpperCase(),
          'email': _emailController.text.trim(),
          'office': _selectedOffice,
          'officePhone': _officePhoneController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'password': _passwordController.text.trim(),
          'userType': 'Chief Engineer',
          'isActive': false,
          'createdAt': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Registration successful!')),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text('Registration failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text('Register Chief Engineer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildLabeledTextField(
                    label: 'User Type',
                    isReadOnly: true,
                    controller: _userTypeController),
                _buildLabeledTextField(
                    label: 'Name',
                    hint: 'Enter Name',
                    controller: _nameController,
                    icon: Icons.person_outline),
                _buildLabeledTextField(
                    label: 'NIC',
                    hint: 'Enter NIC',
                    controller: _nicController,
                    icon: Icons.credit_card),
                _buildLabeledDropdown(
                    label: 'Select Office',
                    hint: 'Select an Office',
                    value: _selectedOffice,
                    items: _offices,
                    onChanged: (val) => setState(() => _selectedOffice = val)),
                _buildLabeledTextField(
                    label: 'Email',
                    hint: 'Enter Email',
                    controller: _emailController,
                    icon: Icons.email_outlined),
                _buildLabeledTextField(
                    label: 'Office Phone',
                    hint: 'Enter Phone',
                    controller: _officePhoneController,
                    icon: Icons.phone),
                _buildLabeledTextField(
                    label: 'Mobile',
                    hint: 'Enter Mobile',
                    controller: _mobileController,
                    icon: Icons.phone_iphone),
                // PET/NICKNAME REMOVED HERE
                _buildLabeledTextField(
                    label: 'Password',
                    controller: _passwordController,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    focusNode: _passwordFocusNode,
                    onVisibilityToggle: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible)),
                if (_isPasswordFocused) _buildPasswordValidationUI(),
                _buildLabeledTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onVisibilityToggle: () => setState(() =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF53BDFF),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Add Chief Engineer',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
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
  
  // ... (Include helper methods _buildLabeledTextField, _buildLabeledDropdown, etc. here similar to add_to.dart)
  
  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    IconData? icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    bool isReadOnly = false,
    VoidCallback? onVisibilityToggle,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        readOnly: isReadOnly,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: onVisibilityToggle)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (val) => val!.isEmpty ? 'Field required' : null,
      ),
    );
  }

  Widget _buildLabeledDropdown({
      required String label,
      required String hint,
      required String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
<<<<<<< HEAD
        value: value,
=======
        initialValue: value,
>>>>>>> main
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildPasswordValidationUI() {
    return Column(
      children: [
        Text("8 Chars: ${_has8Chars ? 'Yes' : 'No'}"),
        // Add other validations as simple text for brevity or use your helper widget
      ],
    );
  }
}