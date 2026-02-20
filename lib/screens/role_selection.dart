import 'package:flutter/material.dart';

// Import all the new registration pages

import 'ProvincialEng/signup.dart';
import 'Principal/signup.dart';
import 'DistrictEng/signup.dart';
import 'TO/signup.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Back to Login'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Your position to Registration',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role;
                    return _buildRoleButton(role, isSelected);
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_selectedRole != null) {
                    // --- NEW: Navigation logic to the correct registration page ---
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
                      case 'Provincial Engineer':
                        destination = const ProvincialEngRegistrationPage();
                        break;
                      default:
                        // This case should not be reachable
                        return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => destination),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a position first.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Get Start Now',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedRole = role;
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor:
              isSelected ? Colors.blue.shade50 : Colors.grey.shade200,
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          role,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blueAccent : Colors.black87,
          ),
        ),
      ),
    );
  }
}
