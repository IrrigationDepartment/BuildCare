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
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
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
                    return const Center(
                        child: Text('School details not found.'));
                  }

                  final schoolData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final infrastructure =
                      schoolData['infrastructure'] as Map<String, dynamic>? ??
                          {};

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              'School Name', schoolData['schoolName']),
                          _buildDetailRow(
                              'School Address', schoolData['schoolAddress']),
                          _buildDetailRow(
                              'School E-mail', schoolData['schoolEmail']),
                          _buildDetailRow(
                              'School Phone Number', schoolData['schoolPhone']),
                          _buildDetailRow(
                              'School Type', schoolData['schoolType']),
                          _buildDetailRow('School Educational Zone',
                              schoolData['educationalZone']),
                          _buildDetailRow('Number of Students',
                              schoolData['numStudents']?.toString()),
                          _buildDetailRow('Number of Teachers',
                              schoolData['numTeachers']?.toString()),
                          _buildDetailRow('Number of Non-Academic Staff',
                              schoolData['numNonAcademic']?.toString()),
                          const SizedBox(height: 16),
                          _buildInfrastructureDetails(infrastructure),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to Master Plan View
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ViewMasterPlanScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map, color: Colors.white),
                              label: const Text('Master Plan',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'View School Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kTextColor), // 'x' icon
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // Fixed width for labels
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 15,
                color: kSubTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureDetails(Map<String, dynamic> infrastructure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Infrastructure Components:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfrastructureItem(
            'Electricity', infrastructure['electricity'] ?? false),
        _buildInfrastructureItem(
            'Water Supply', infrastructure['waterSupply'] ?? false),
        _buildInfrastructureItem(
            'Sanitation', infrastructure['sanitation'] ?? false),
        _buildInfrastructureItem('Communication Facilities',
            infrastructure['communication'] ?? false),
      ],
    );
  }

  Widget _buildInfrastructureItem(String label, bool hasComponent) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
      child: Row(
        children: [
          Icon(
            hasComponent ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: hasComponent ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: hasComponent ? kTextColor : kSubTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
