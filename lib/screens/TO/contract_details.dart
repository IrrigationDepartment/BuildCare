// In screens/TO/contract_details.dart
import 'package:flutter/material.dart';

class ContractDetailsScreen extends StatelessWidget {
  // You might want to pass data to this screen later, 
  // but for now, we'll keep it simple.
  const ContractDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Details'),
        backgroundColor: const Color(0xFF42A5F5), // Use your kPrimaryBlue
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 80, color: Color(0xFF42A5F5)),
            SizedBox(height: 20),
            Text(
              'Welcome to the Contract Details Page!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Content related to contract weights, etc. will go here.'),
          ],
        ),
      ),
    );
  }
}