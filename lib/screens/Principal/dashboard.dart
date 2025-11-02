import 'package:flutter/material.dart';

class PrincipalDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const PrincipalDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Principal Dashboard'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${userData['name'] ?? 'User'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'User Type: ${userData['userType'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
