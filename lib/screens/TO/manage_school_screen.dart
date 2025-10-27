import 'package:flutter/material.dart';

class ManageSchoolScreen extends StatelessWidget {
  const ManageSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage School'),
        backgroundColor: const Color(0xFF333333),
      ),
      body: const Center(
        child: Text(
          'Manage School Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}