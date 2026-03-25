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

  // Controllers
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  final TextEditingController _schoolPhoneController = TextEditingController();
  final TextEditingController _principalNameController = TextEditingController();
  final TextEditingController _principalMobileController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _nicFocusNode = FocusNode();
  final FocusNode _schoolNameFocusNode = FocusNode();

  // Dropdown states
  String? _selectedSchoolType;
  final List<String> _schoolTypes = ['Provincial', 'Government'];

  String? _selectedDistrict;
  final List<String> _districts = ['Galle', 'Matara', 'Hambantota'];

  // School suggestions
  List<String> _allSchoolNames = [];
  bool _isLoadingSchools = true;

  // UI states
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // NIC validation states
  bool _isCheckingNic = false;
  bool _isNicDuplicate = false;

  // Defaults
  final bool _initialIsActiveStatus = false;
  final String _defaultProfileImageUrl =
      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_Ldbm8TwlbnL43PId23vLdI3MgqhaNYf5.jpg';

  @override
  void initState() {
    super.initState();
    _nicFocusNode.addListener(_onNicFocusChange);
    _loadSchoolNames();
  }

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

    _nicFocusNode.removeListener(_onNicFocusChange);
    _nicFocusNode.dispose();
    _schoolNameFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadSchoolNames() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .orderBy('schoolName')
          .get();

      final names = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return (data['schoolName'] ?? '').toString().trim();
          })
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (mounted) {
        setState(() {
          _allSchoolNames = names;
          _isLoadingSchools = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading school names: $e');
      if (mounted) {
        setState(() {
          _isLoadingSchools = false;
        });
      }
    }
  }

  void _onNicFocusChange() {
    if (!_nicFocusNode.hasFocus) {
      _checkNicDuplication();
    }
  }

  Future<void> _checkNicDuplication() async {
    final nic = _nicController.text.trim().toUpperCase();

    if (nic.isEmpty) return;

    final nicRegex = RegExp(r'(^(\d{12})|(\d{9}[vVxX])$)');
    if (!nicRegex.hasMatch(nic)) return;

    setState(() {
      _isCheckingNic = true;
      _isNicDuplicate = false;
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
      debugPrint('Error checking NIC: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingNic = false;
        });
      }
    }
  }

  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _checkNicDuplication();
    if (_isNicDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('This NIC is already registered. Please check again.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _schoolEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user?.uid;

      if (uid != null) {
        final userData = {
          'uid': uid,
          'userType': 'Principal',
          'nic': _nicController.text.trim().toUpperCase(),
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

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                'Registration successful! Your account is currently pending approval.',
              ),
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
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
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(message),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Registration failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    IconData? icon,
    Widget? suffixIcon,
    String? errorText,
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent.shade200) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
      ),
    );
  }

  Widget _buildReadOnlyDropdown(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            readOnly: true,
            style: const TextStyle(color: Colors.black54),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.work_outline, color: Colors.blueAccent.shade200),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18.0,
                horizontal: 20.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDecoration(
              icon: icon,
              suffixIcon: suffixIcon,
              errorText: errorText,
            ),
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'School Type',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSchoolType,
            hint: const Text('Select School Type'),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: _inputDecoration(icon: Icons.category_outlined),
            onChanged: (String? newValue) {
              setState(() => _selectedSchoolType = newValue);
            },
            items: _schoolTypes.map((value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            validator: (value) =>
                value == null ? 'Please select a school type' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'School District',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedDistrict,
            hint: const Text('Select School District'),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: _inputDecoration(icon: Icons.location_city_outlined),
            onChanged: (String? newValue) {
              setState(() => _selectedDistrict = newValue);
            },
            items: _districts.map((value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            validator: (value) =>
                value == null ? 'Please select a district' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolAutocompleteField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'School Name',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _schoolNameController.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();

              if (query.isEmpty) {
                return const Iterable<String>.empty();
              }

              return _allSchoolNames.where((school) {
                return school.toLowerCase().contains(query);
              }).take(10);
            },
            displayStringForOption: (option) => option,
            onSelected: (String selection) {
              _schoolNameController.text = selection;
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              textEditingController.value = _schoolNameController.value;

              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                onChanged: (value) {
                  _schoolNameController.value = textEditingController.value;
                },
                style: const TextStyle(color: Colors.black87),
                decoration: _inputDecoration(
                  icon: Icons.account_balance_outlined,
                  hintText: _isLoadingSchools
                      ? 'Loading schools...'
                      : 'Start typing school name',
                  suffixIcon: _isLoadingSchools
                      ? const Padding(
                          padding: EdgeInsets.all(14.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_schoolNameController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                textEditingController.clear();
                                _schoolNameController.clear();
                                setState(() {});
                              },
                            )
                          : const Icon(Icons.search)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the school name';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              );
            },
            optionsViewBuilder: (
              BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> options,
            ) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: MediaQuery.of(context).size.width > 600
                        ? 550
                        : MediaQuery.of(context).size.width - 48,
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);

                        return ListTile(
                          leading: const Icon(
                            Icons.school_outlined,
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFormField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Principal\'s Password (Min 6 characters)',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDecoration(
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordFormField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Password',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDecoration(
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() => _isConfirmPasswordVisible =
                      !_isConfirmPasswordVisible);
                },
              ),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: const EdgeInsets.all(40.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.school,
                        size: 56,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Principal Registration',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register your school and administrative account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildReadOnlyDropdown('User Type', 'Principal'),
                      _buildSchoolTypeDropdown(),
                      _buildDistrictDropdown(),
                      _buildSchoolAutocompleteField(),

                      _buildTextFormField(
                        controller: _nicController,
                        labelText: 'Principal NIC Number',
                        icon: Icons.badge_outlined,
                        focusNode: _nicFocusNode,
                        errorText: _isNicDuplicate
                            ? 'This NIC is already registered'
                            : null,
                        suffixIcon: _isCheckingNic
                            ? const Padding(
                                padding: EdgeInsets.all(14.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field cannot be empty';
                          }
                          final nicRegex =
                              RegExp(r'(^(\d{12})|(\d{9}[vVxX])$)');
                          if (!nicRegex.hasMatch(value.trim())) {
                            return 'Enter a valid SL NIC (e.g., 123456789V)';
                          }
                          return null;
                        },
                      ),

                      _buildTextFormField(
                        controller: _principalNameController,
                        labelText: 'Principal Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the principal\'s name';
                          }
                          return null;
                        },
                      ),

                      _buildTextFormField(
                        controller: _principalMobileController,
                        labelText: 'Principal\'s Mobile Number',
                        icon: Icons.phone_iphone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field cannot be empty';
                          }
                          final phoneRegex = RegExp(r'^\d{10}$');
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return 'Enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),

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

                      _buildTextFormField(
                        controller: _schoolEmailController,
                        labelText: 'Email Address (Login ID)',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field cannot be empty';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const Divider(height: 40),
                      Text(
                        'Password & Security',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildPasswordFormField(),
                      _buildConfirmPasswordFormField(),

                      const SizedBox(height: 32),

                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                elevation: 2,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Complete Registration',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already Registered?",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}