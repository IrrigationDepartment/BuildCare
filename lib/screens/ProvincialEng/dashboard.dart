import 'package:flutter/material.dart';

class ProvincialEngDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProvincialEngDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Access user data like this: final userName = userData['name'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provincial Engineer Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.engineering, size: 80, color: Colors.blueAccent),
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
