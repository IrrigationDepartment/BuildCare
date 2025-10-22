import 'package:flutter/material.dart';

class TODashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const TODashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Officer Dashboard'),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle, size: 80, color: Colors.brown),
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
