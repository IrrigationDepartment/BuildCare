import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_school_screen.dart'; 
import 'view_master_plan_screen.dart'; 

class SchoolDetailsPage extends StatefulWidget {
  final String schoolId; 

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
  static const Color kActiveColor = Color(0xFF4CAF50); // Green
  static const Color kInactiveColor = Color(0xFFBDBDBD); // Grey
  static const Color kAccentColor = Color(0xFFFFA726); // Orange for Stats/Edit

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

          // Extracting school data
          final schoolData = snapshot.data!.data() as Map<String, dynamic>;
          final String schoolName = schoolData['schoolName'] ?? 'Unnamed School';
          final infrastructure = schoolData['infrastructure'] as Map<String, dynamic>? ?? {};
          final String? addedByUserId = schoolData['addedBy'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Basic Info Card
                _buildInfoCard(schoolData),
                const SizedBox(height: 15),

                // 2. Added By Section (Dynamic)
                if (addedByUserId != null) _buildAddedBySection(addedByUserId),
                const SizedBox(height: 15),

                // 3. Personnel and Student Stats
                _buildStatsCard(schoolData),
                const SizedBox(height: 15),

                // 4. Infrastructure Status
                _buildInfrastructureCard(infrastructure),
                const SizedBox(height: 20),

                // 5. Action Buttons (Pass schoolName to Master Plan screen)
                _buildActionButtons(context, schoolData, schoolName),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('School Name', data['schoolName'], isHeader: true),
          const Divider(height: 20),
          _buildDetailRow('Address', data['schoolAddress']),
          _buildDetailRow('E-mail', data['schoolEmail']),
          _buildDetailRow('Phone', data['schoolPhone']),
        ],
      ),
    );
  }

  Widget _buildAddedBySection(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        String name = "System User";
        String position = "Officer";

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          name = userData['name'] ?? name;
          position = userData['userType'] ?? position;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: kPrimaryBlue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Registered By", style: TextStyle(fontSize: 12, color: kSubTextColor)),
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(position, style: const TextStyle(fontSize: 13, color: kPrimaryBlue)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Capacity Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildStatItem('Students', data['numStudents']?.toString(), Icons.group),
          _buildStatItem('Teachers', data['numTeachers']?.toString(), Icons.person_pin_circle),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value ?? '0', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
        ],
      ),
    );
  }

  Widget _buildInfrastructureCard(Map<String, dynamic> infra) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Infrastructure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildInfrastructureItem('Electricity', infra['electricity'] ?? false),
          _buildInfrastructureItem('Water Supply', infra['waterSupply'] ?? false),
        ],
      ),
    );
  }

  Widget _buildInfrastructureItem(String label, bool has) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(has ? Icons.check_circle : Icons.cancel, color: has ? kActiveColor : kInactiveColor),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data, String schoolName) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => EditSchoolScreen(schoolId: widget.schoolId, schoolData: data))
              );
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Edit School Details', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Master Plan screen එකට schoolName එක යැවීම
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ViewMasterPlanScreen(schoolName: schoolName))
              );
            },
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            label: const Text('View Master Plan', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kSubTextColor, fontSize: 12)),
          Text(value ?? 'N/A', style: TextStyle(fontSize: isHeader ? 22 : 16, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: kTextColor)),
        ],
      ),
    );
  }
}