// Import for Firebase Auth
import 'package:firebase_auth/firebase_auth.dart';
// Import for Firebase Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


<<<<<<< HEAD
=======
import 'package:flutter/material.dart';

// Import the new screen
import 'screens/forgot_password_flow.dart';

// Corrected imports to match your folder structure
>>>>>>> main
import 'screens/ProvincialEng/dashboard.dart';
import 'screens/ChiefEng/dashboard.dart';
import 'screens/DistrictEng/dashboard.dart';
import 'screens/Principal/dashboard.dart';
import 'screens/TO/dashboard.dart';
import 'screens/role_selection.dart';
import 'screens/forgot_password_flow.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isPasswordVisible = false;
  bool _isLoading = false;

<<<<<<< HEAD
=======
  /// Shows a dialog message to the user.
  void _showMessage(String title, String message) {
    // Check if the widget is still in the tree (mounted)
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  /// Handles the login logic when the button is pressed.
  Future<void> _login() async {
    // Basic validation
    if (_nicController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Error', 'Please enter both NIC and Password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --- 1. FIND USER BY NIC TO GET EMAIL ---
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection
          .where('nic', isEqualTo: _nicController.text.trim().toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // NIC not found, show a generic error
        _showMessage(
            'Login Failed', 'Invalid NIC or Password. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      // --- 2. GET THE EMAIL AND USER DATA ---
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final String? email = userData['email'] as String?;
      final String uid = userDoc.id; // This is the user's Auth UID
      final String? uid = userDoc.id; // This is the user's Auth UID

      if (email == null || email.isEmpty) {
        _showMessage('Login Error',
            'Your account has no email. Please contact support.');
        setState(() => _isLoading = false);
        return;
      }

      // --- 3. SIGN IN WITH FIREBASE AUTH ---
      UserCredential userCredential;
      try {
        userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException {
        // This catches wrong password, user-not-found (which shouldn't happen here), etc.
        _showMessage(
            'Login Failed', 'Invalid NIC or Password. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      // --- 4. AUTH SUCCEEDED, NOW CHECK FIRESTORE FOR 'isActive' ---
      
      // We can re-use the userData we fetched earlier
      final bool isActive = userData['isActive'] as bool? ?? false;
      final userType = userData['userType'] as String?;

      // We can re-use the userData we fetched earlier
      final bool isActive = userData['isActive'] as bool? ?? false;
      final userType = userData['userType'] as String?;

      if (isActive) {
        // --- User is active, proceed with login ---
        final String loggedInNic = _nicController.text.trim();
        final Map<String, dynamic> combinedUserData = {
          ...userData,
          'nic': loggedInNic, // Ensure NIC is passed
          'uid': uid, // Pass the user's ID
        };

      if (isActive) {
        // --- User is active, proceed with login ---
        final String loggedInNic = _nicController.text.trim();
        final Map<String, dynamic> combinedUserData = {
          ...userData,
          'nic': loggedInNic, // Ensure NIC is passed
          'uid': uid, // Pass the user's ID
        };
        
        Widget destination;
        switch (userType) {
          case 'Provincial Director':
          case 'Provincial Engineer':
            destination = ProvincialEngDashboard(userData: combinedUserData);
            break;
          case 'Chief Engineer':
            destination = ChiefEngDashboard(userData: combinedUserData);
            break;
          case 'District Engineer':
            destination = DistrictEngDashboard(userData: combinedUserData);
            break;
          case 'Principal':
            destination = PrincipalDashboard(userData: combinedUserData);
            break;
          case 'Technical Officer':
            destination = TODashboard(userData: combinedUserData);
            break;
          default:
            _showMessage('Login Error',
                'Could not determine user role. Please contact support.');
            setState(() {
              _isLoading = false;
            });
            // Sign out to be safe
            await FirebaseAuth.instance.signOut();
            return;
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => destination),
          );
        }
      } else {
        // --- User is not active, show error ---
        _showMessage(
            'Login Failed',
        _showMessage('Login Failed',
            'Your account is not active. Please contact an administrator.');
        // Sign the user out again, as they are not allowed in
        await FirebaseAuth.instance.signOut();
      }

    } catch (e) {
      _showMessage('Error', 'An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

>>>>>>> main
  @override
  void dispose() {
    _nicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  
  Future<void> _login() async {
    print('🔵 Login started');
    
    
    if (_nicController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      _showMessage('Error', 'Please enter both NIC and Password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📝 NIC entered: ${_nicController.text.trim()}');
      
     
      print('🔍 Searching for user in Firestore...');
      final querySnapshot = await _firestore
          .collection('users')
          .where('nic', isEqualTo: _nicController.text.trim().toUpperCase())
          .limit(1)
          .get();

      print(' Query result: ${querySnapshot.docs.length} documents found');

      if (querySnapshot.docs.isEmpty) {
        print(' No user found with this NIC');
        _showMessage('Login Failed', 'Invalid NIC or Password. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final email = userData['email'] as String;
      final isActive = userData['isActive'] as bool? ?? false;
      final userType = userData['userType'] as String?;

      print(' User found!');
      print(' Email: $email');
      print(' isActive: $isActive');
      print(' userType: $userType');

      
      if (!isActive) {
        print(' User account is not active');
        _showMessage(
          'Account Not Active',
          'Your account is not active. Please contact an administrator for activation.',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Step 4: Authenticate with Firebase Auth using email and password
      print(' Attempting Firebase Auth login...');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      print(' Login successful!');

      
      if (!mounted) return;

      Widget destination;
      switch (userType) {
        case 'Provincial Engineer':
          destination = ProvincialEngDashboard(userData: userData);
          break;
        case 'Chief Engineer':
          destination = ChiefEngDashboard(userData: userData);
          break;
        case 'District Engineer':
          destination = DistrictEngDashboard(userData: userData);
          break;
        case 'Principal':
          destination = PrincipalDashboard(userData: userData);
          break;
        case 'Technical Officer':
          destination = TODashboard(userData: userData);
          break;
        default:
          print(' Unknown user type: $userType');
          _showMessage(
            'Login Error',
            'Could not determine user role. Please contact support.',
          );
          setState(() => _isLoading = false);
          return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => destination),
      );

    } on FirebaseAuthException catch (e) {
      print(' FirebaseAuthException: ${e.code}');
      print(' Message: ${e.message}');

      String errorMessage = 'Login Failed';
      String errorDetails = '';

      switch (e.code) {
        case 'wrong-password':
          errorDetails = 'Invalid NIC or Password. Please try again.';
          break;
        case 'user-not-found':
          errorDetails = 'Invalid NIC or Password. Please try again.';
          break;
        case 'user-disabled':
          errorDetails = 'This account has been disabled. Contact support.';
          break;
        case 'invalid-email':
          errorDetails = 'Invalid account credentials. Please try again.';
          break;
        case 'network-request-failed':
          errorDetails = 'Network error. Please check your internet connection.';
          break;
        case 'too-many-requests':
          errorDetails = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorDetails = e.message ?? 'An error occurred. Please try again.';
      }

      _showMessage(errorMessage, errorDetails);
      
    } catch (e) {
      print(' General error: $e');
      _showMessage('Error', 'An unexpected error occurred: $e');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Image.network(
                  'https://i.imgur.com/3TXeXfV.png',
                  height: 200,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.map, size: 150, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Login In Now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'please login to continue using the app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _nicController,
                  labelText: 'Enter Your NIC',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 12),
<<<<<<< HEAD
=======

                // [----- Forgot Password Button -----]
>>>>>>> main
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ForgotPasswordFlow(),
                      ));
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
<<<<<<< HEAD
=======
                // [-----------------------------]

>>>>>>> main
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const RoleSelectionPage(),
                        ));
                      },
                      child: const Text(
                        'Sign Up',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Enter Your Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
}
}
}
>>>>>>> main
