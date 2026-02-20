import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the Master Plan Screen
import 'view_master_plan_screen.dart';

class ViewSchoolDetailsScreen extends StatefulWidget {
  final String schoolId; // The ID of the school to view

  const ViewSchoolDetailsScreen({super.key, required this.schoolId});

  @override
  State<ViewSchoolDetailsScreen> createState() =>
      _ViewSchoolDetailsScreenState();
}

class _ViewSchoolDetailsScreenState extends State<ViewSchoolDetailsScreen> {
  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);
  static const Color kCardColor = Colors.white;
  static const double kCardElevation = 2.0;
  static final BorderRadius kBorderRadius = BorderRadius.circular(15);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        title: const Text(
          'School Information',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No details found for this school.'));
          }

          final schoolData = snapshot.data!.data() as Map<String, dynamic>;
          
          // Get schoolName to pass to Master Plan screen
          final String schoolName = schoolData['schoolName'] ?? 'Unnamed School';
          final infrastructure = schoolData['infrastructure'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Basic Info Card
                _buildInfoCard(schoolData),
                const SizedBox(height: 20),

                // 2. Statistics Card (Students/Teachers)
                _buildStatsCard(schoolData),
                const SizedBox(height: 20),

                // 3. Infrastructure Checklist
                _buildInfrastructureCard(infrastructure),
                const SizedBox(height: 30),

                // 4. View Master Plan Button
                _buildMasterPlanButton(context, schoolName),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 1. Basic Information Card
  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['schoolName'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
            const Divider(height: 30),
            _buildInfoRow(Icons.location_on, 'Address', data['schoolAddress']),
            _buildInfoRow(Icons.email, 'Email', data['schoolEmail']),
            _buildInfoRow(Icons.phone, 'Phone', data['schoolPhone']),
          ],
        ),
      ),
    );
  }

  /// 2. Statistics Card
  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.people,
              label: 'Students',
              value: data['numStudents']?.toString() ?? '0',
            ),
            _buildStatItem(
              icon: Icons.person_pin_circle,
              label: 'Teachers',
              value: data['numTeachers']?.toString() ?? '0',
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Infrastructure Card
  Widget _buildInfrastructureCard(Map<String, dynamic> infra) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Infrastructure Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildInfrastructureItem('Electricity', infra['electricity'] ?? false),
            _buildInfrastructureItem('Water Supply', infra['waterSupply'] ?? false),
          ],
        ),
      ),
    );
  }

  /// 4. Master Plan Navigation Button
  Widget _buildMasterPlanButton(BuildContext context, String schoolName) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to Master Plan screen and pass the school name
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewMasterPlanScreen(schoolName: schoolName),
            ),
          );
        },
        icon: const Icon(Icons.map_rounded, color: Colors.white),
        label: const Text(
          'View Master Plan',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kSubTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: kSubTextColor)),
                Text(value ?? 'N/A', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: kPrimaryBlue, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 13, color: kSubTextColor)),
      ],
    );
  }

  Widget _buildInfrastructureItem(String label, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}