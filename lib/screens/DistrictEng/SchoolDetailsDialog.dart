import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolDetailsPage extends StatefulWidget {
  final String schoolId; 

  const SchoolDetailsPage({super.key, required this.schoolId});

  @override
  State<SchoolDetailsPage> createState() => _SchoolDetailsPageState();
}

class _SchoolDetailsPageState extends State<SchoolDetailsPage> {
  // --- Style Constants ---
  //static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);
  static const Color kActiveColor = Color(0xFF4CAF50); // Green
  static const Color kInactiveColor = Color(0xFFBDBDBD); // Grey

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('School Details', style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('School details not found.'));
          }

          final schoolData = snapshot.data!.data() as Map<String, dynamic>;
          final infrastructure =
              schoolData['infrastructure'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- School Info Card (Name... to Staff) ---
                _buildInfoCard(schoolData),
                const SizedBox(height: 15),

                // --- Infrastructure Card ---
                _buildInfrastructureCard(infrastructure),
                // Removed the SizedBox(height: 20) and _buildActionButtons call
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Info Card: Now wider and cleaner ---
  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity, // Ensures it takes full available width
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Slightly softer corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2), // Shadow position
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('School Name', data['schoolName'], isBold: true),
          const Divider(), // Adds a line to separate the header
          _buildDetailRow('Address', data['schoolAddress']),
          _buildDetailRow('E-mail', data['schoolEmail']),
          _buildDetailRow('Phone', data['schoolPhone']),
          _buildDetailRow('Type', data['schoolType']),
          _buildDetailRow('Zone', data['educationalZone']),
          const SizedBox(height: 10), // Small gap before stats
          _buildDetailRow('Students', data['numStudents']?.toString()),
          _buildDetailRow('Teachers', data['numTeachers']?.toString()),
          _buildDetailRow('Staff', data['numNonAcademic']?.toString()),
        ],
      ),
    );
  }

  Widget _buildInfrastructureCard(Map<String, dynamic> infrastructure) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Infrastructure Components',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
          ),
          const SizedBox(height: 12),
          _buildInfrastructureItem('Electricity', infrastructure['electricity'] ?? false),
          _buildInfrastructureItem('Water Supply', infrastructure['waterSupply'] ?? false),
          _buildInfrastructureItem('Sanitation', infrastructure['sanitation'] ?? false),
          _buildInfrastructureItem('Communication', infrastructure['communication'] ?? false),
        ],
      ),
    );
  }

  // The entire _buildActionButtons function has been removed.

  // Helper for rows with optional Bold text for the School Name
  Widget _buildDetailRow(String label, String? value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: kSubTextColor),
          ),
          const SizedBox(height: 2),
          Text(
            value ?? 'N/A',
            style: TextStyle(
              fontSize: isBold ? 20 : 16, // Larger font for School Name
              color: kTextColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureItem(String label, bool hasComponent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            hasComponent ? Icons.check_circle : Icons.cancel, // Modern icons
            color: hasComponent ? kActiveColor : kInactiveColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: kTextColor),
          ),
        ],
      ),
    );
  }
}