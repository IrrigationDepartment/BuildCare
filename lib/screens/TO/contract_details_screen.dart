import 'package:flutter/material.dart';

class ContractDetailsScreen extends StatelessWidget {
  const ContractDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Details'),
        backgroundColor: const Color(0xFF333333),
      ),
      body: const Center(
        child: Text(
          'Contract Details Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}