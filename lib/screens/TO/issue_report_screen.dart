import 'package:flutter/material.dart';

class IssueReportScreen extends StatelessWidget {
  const IssueReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues Report'),
        backgroundColor: const Color(0xFF333333),
      ),
      body: const Center(
        child: Text(
          'Issues Report Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}