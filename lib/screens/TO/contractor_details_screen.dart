import 'package:flutter/material.dart';

class ContractorDetailsScreen extends StatelessWidget {
  const ContractorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Details'),
        backgroundColor: const Color(0xFF333333),
      ),
      body: const Center(
        child: Text(
          'Contractor Details Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}