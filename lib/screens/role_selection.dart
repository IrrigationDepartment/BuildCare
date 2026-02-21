import 'package:flutter/material.dart';

// Import all the new registration pages
import 'ProvincialEng/signup.dart';
import 'Principal/signup.dart';
import 'DistrictEng/signup.dart';
import 'TO/signup.dart';
import 'ChiefEng/signup.dart'; // Linked successfully

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? _selectedRole;
  final List<String> _roles = [
    'Principal',
    'TO',
    'District Engineer',
    'Chief Engineer', 
    'Provincial Director' 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Back to Login'),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.work_outline, size: 56, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Your Position',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your role to continue registration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    ..._roles.map((role) {
                      final isSelected = _selectedRole == role;
                      return _buildRoleButton(role, isSelected);
                    }),
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedRole != null) {
                          Widget destination;
                          switch (_selectedRole) {
                            case 'Principal':
                              destination = const PrincipalRegistrationPage();
                              break;
                            case 'TO':
                              destination = const TORegistrationPage();
                              break;
                            case 'District Engineer':
                              destination = const DistrictEngRegistrationPage();
                              break;
                            // --- LINKED CHIEF ENGINEER HERE ---
                            case 'Chief Engineer':
                              destination = const ChiefEngRegistrationPage();
                              break;
                            case 'Provincial Engineer': 
                            case 'Provincial Director':
                              destination = const ProvincialEngRegistrationPage();
                              break;
                            default:
                              return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => destination),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a position first.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Get Started Now',
                        style: TextStyle(
                          fontSize: 18, 
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedRole = role;
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          backgroundColor: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft, 
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Text(
              role,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.blueAccent : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}