import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_school_screen.dart'; // For "Edit" button
import 'view_master_plan_screen.dart'; // For "Master Plan" button

class SchoolDetailsPage extends StatefulWidget {
  final String schoolId; // The ID of the school to view

  const SchoolDetailsPage({super.key, required this.schoolId});

  @override
  State<SchoolDetailsPage> createState() => _SchoolDetailsPageState();
}

class _SchoolDetailsPageState extends State<SchoolDetailsPage> {
  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  // --- FIX: ADDED MISSING COLORS HERE ---
  static const Color kActiveColor = Color(0xFF4CAF50); // Green
  static const Color kInactiveColor = Color(0xFF757575); // Grey

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title:
            const Text('School Details', style: TextStyle(color: kTextColor)),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- School Info Card ---
                _buildInfoCard(schoolData),
                const SizedBox(height: 20),

                // --- Infrastructure Card ---
                _buildInfrastructureCard(infrastructure),
                const SizedBox(height: 20),

                // --- Action Buttons ---
                _buildActionButtons(context, schoolData),
              ],
            ),
          );
        },
      ),
    );
  }

  // Card for general school info
  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('School Name', data['schoolName']),
          _buildDetailRow('Address', data['schoolAddress']),
          _buildDetailRow('E-mail', data['schoolEmail']),
          _buildDetailRow('Phone', data['schoolPhone']),
          _buildDetailRow('Type', data['schoolType']),
          _buildDetailRow('Zone', data['educationalZone']),
          _buildDetailRow('Students', data['numStudents']?.toString()),
          _buildDetailRow('Teachers', data['numTeachers']?.toString()),
          _buildDetailRow('Staff', data['numNonAcademic']?.toString()),
        ],
      ),
    );
  }

  // Card for infrastructure details
  Widget _buildInfrastructureCard(Map<String, dynamic> infrastructure) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Infrastructure Components',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfrastructureItem(
              'Electricity', infrastructure['electricity'] ?? false),
          _buildInfrastructureItem(
              'Water Supply', infrastructure['waterSupply'] ?? false),
          _buildInfrastructureItem(
              'Sanitation', infrastructure['sanitation'] ?? false),
          _buildInfrastructureItem(
              'Communication', infrastructure['communication'] ?? false),
        ],
      ),
    );
  }

  // Row for "Edit" and "Master Plan" buttons
  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to Edit Screen, passing the school ID and data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditSchoolScreen(
                    schoolId: widget.schoolId, schoolData: data),
              ),
            );
          },
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text('Edit School Details',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700, // Edit color
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to Master Plan View
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ViewMasterPlanScreen(),
              ),
            );
          },
          icon: const Icon(Icons.map_outlined, color: Colors.white),
          label: const Text('View Master Plan',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue, // Blue color
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // Helper widget to build a styled info row
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: kSubTextColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
                fontSize: 16, color: kTextColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper widget for infrastructure checkboxes
  Widget _buildInfrastructureItem(String label, bool hasComponent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            hasComponent ? Icons.check_box : Icons.check_box_outline_blank,
            // This line (217) will now work
            color: hasComponent ? kActiveColor : kInactiveColor,
            size: 20,
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