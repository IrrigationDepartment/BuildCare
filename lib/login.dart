import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import all the dashboard and new utility screens
import 'screens/TO/dashboard.dart'; // THIS IMPORT WILL NOW BE USED
// THIS IS THE IMPORTANT IMPORT THAT WILL NOW BE USED
import 'screens/role_selection.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ... (all the existing state variables _nicController, _passwordController, etc. remain unchanged) ...
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  /// Shows a dialog message to the user.
  void _showMessage(String title, String message) {
    // ... (this function remains unchanged) ...
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
    // ... (this entire function remains unchanged, it's already correct) ...
    if (_nicController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Error', 'Please enter both NIC and Password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection
          .where('nic', isEqualTo: _nicController.text.trim())
          .where('password', isEqualTo: _passwordController.text.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final userType = userData['userType'] as String?;

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
            // THIS WILL NOW USE YOUR REAL DASHBOARD FILE
            destination = TODashboard(userData: userData);
            break;
          default:
            _showMessage('Login Error',
                'Could not determine user role. Please contact support.');
            setState(() {
              _isLoading = false;
            });
            return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => destination),
        );
      } else {
        _showMessage(
            'Login Failed', 'Invalid NIC or Password. Please try again.');
      }
    } catch (e) {
      _showMessage('Error', 'An error occurred during login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // ... (this function remains unchanged) ...
    _nicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (this entire build method remains unchanged) ...
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
                            color: Colors.blueAccent),
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
    // ... (this function remains unchanged) ...
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
    // ... (this function remains unchanged) ...
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
}

// --- Placeholder classes for missing imports ---
// I am leaving these here so your _login function does not break.

class ProvincialEngDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProvincialEngDashboard({super.key, required this.userData});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provincial Engineer Dashboard')),
      body: Center(child: Text('Welcome ${userData['name']}')),
    );
  }
}

class ChiefEngDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ChiefEngDashboard({super.key, required this.userData});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chief Engineer Dashboard')),
      body: Center(child: Text('Welcome ${userData['name']}')),
    );
  }
}

class DistrictEngDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const DistrictEngDashboard({super.key, required this.userData});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('District Engineer Dashboard')),
      body: Center(child: Text('Welcome ${userData['name']}')),
    );
  }
}

class PrincipalDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const PrincipalDashboard({super.key, required this.userData});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Principal Dashboard')),
      body: Center(child: Text('Welcome ${userData['name']}')),
    );
  }
}

// --- I HAVE REMOVED THE PLACEHOLDER TODashboard CLASS ---
// This ensures the import at the top of the file is used,
// which points to your real dashboard.dart file.
