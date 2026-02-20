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
<<<<<<< HEAD
  // --- Constants ---
=======
  // --- Style Constants ---
>>>>>>> main
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
<<<<<<< HEAD
      // --- 1. Modern AppBar (No change) ---
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextColor),
        title: const Text(
          'School Details',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // --- MODIFICATION IS HERE ---
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .get(),
=======
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
>>>>>>> main
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
<<<<<<< HEAD
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text('School details not found.'));
          }

          final schoolData =
              snapshot.data!.data() as Map<String, dynamic>;

          // This is the new part: Center + ConstrainedBox
          // This ensures your content is centered and has a max width
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: 700), // Max width for content
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMainInfoCard(schoolData),
                    const SizedBox(height: 16),
                    _buildStatsCard(schoolData),
                    const SizedBox(height: 16),
                    _buildInfrastructureCard(schoolData),
                    const SizedBox(height: 24),
                    _buildMasterPlanButton(context),
                  ],
                ),
              ),
=======

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
>>>>>>> main
            ),
          );
        },
      ),
<<<<<<< HEAD
      // --- END OF MODIFICATION ---
    );
  }

  /// Card for primary school contact info
  Widget _buildMainInfoCard(Map<String, dynamic> data) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            _buildInfoTile(
              icon: Icons.school,
              title: data['schoolName'] ?? 'N/A',
              subtitle: 'School Name',
            ),
            _buildInfoTile(
              icon: Icons.location_on_outlined,
              title: data['schoolAddress'] ?? 'N/A',
              subtitle: 'Address',
            ),
            _buildInfoTile(
              icon: Icons.email_outlined,
              title: data['schoolEmail'] ?? 'N/A',
              subtitle: 'Email',
            ),
            _buildInfoTile(
              icon: Icons.phone_outlined,
              title: data['schoolPhone'] ?? 'N/A',
              subtitle: 'Phone',
            ),
            _buildInfoTile(
              icon: Icons.business_outlined,
              title: data['schoolType'] ?? 'N/A',
              subtitle: 'School Type',
            ),
            _buildInfoTile(
              icon: Icons.map_outlined,
              title: data['educationalZone'] ?? 'N/A',
              subtitle: 'Educational Zone',
              isLast: true,
            ),
=======
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
>>>>>>> main
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  /// Card for key statistics
=======
  /// 2. Statistics Card
>>>>>>> main
  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
<<<<<<< HEAD
      color: kCardColor,
=======
>>>>>>> main
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
<<<<<<< HEAD
              icon: Icons.people_outline,
=======
              icon: Icons.people,
>>>>>>> main
              label: 'Students',
              value: data['numStudents']?.toString() ?? '0',
            ),
            _buildStatItem(
<<<<<<< HEAD
              icon: Icons.person_search_outlined,
              label: 'Teachers',
              value: data['numTeachers']?.toString() ?? '0',
            ),
            _buildStatItem(
              icon: Icons.work_outline,
              label: 'Staff',
              value: data['numNonAcademic']?.toString() ?? '0',
            ),
=======
              icon: Icons.person_pin_circle,
              label: 'Teachers',
              value: data['numTeachers']?.toString() ?? '0',
            ),
>>>>>>> main
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  /// Card for infrastructure details
  Widget _buildInfrastructureCard(Map<String, dynamic> data) {
    final infrastructure =
        data['infrastructure'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      color: kCardColor,
=======
  /// 3. Infrastructure Card
  Widget _buildInfrastructureCard(Map<String, dynamic> infra) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
>>>>>>> main
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
<<<<<<< HEAD
              'Infrastructure Components',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfrastructureItem(
                'Electricity', infrastructure['electricity'] ?? false),
            _buildInfrastructureItem(
                'Water Supply', infrastructure['waterSupply'] ?? false),
            _buildInfrastructureItem(
                'Sanitation', infrastructure['sanitation'] ?? false),
            _buildInfrastructureItem('Communication Facilities',
                infrastructure['communication'] ?? false),
=======
              'Infrastructure Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildInfrastructureItem('Electricity', infra['electricity'] ?? false),
            _buildInfrastructureItem('Water Supply', infra['waterSupply'] ?? false),
>>>>>>> main
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  /// Full-width button for the Master Plan
  Widget _buildMasterPlanButton(BuildContext context) {
=======
  /// 4. Master Plan Navigation Button
  Widget _buildMasterPlanButton(BuildContext context, String schoolName) {
>>>>>>> main
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
<<<<<<< HEAD
          // Navigate to Master Plan View
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ViewMasterPlanScreen(),
            ),
          );
        },
        icon: const Icon(Icons.map, color: Colors.white),
        label: const Text(
          'View Master Plan',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryBlue,
          shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
          padding: const EdgeInsets.symmetric(vertical: 14),
=======
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
>>>>>>> main
        ),
      ),
    );
  }

<<<<<<< HEAD
  // --- Helper Widgets (No change) ---

  /// A modern ListTile for displaying info
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: kBackgroundColor, width: 1.5),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: kPrimaryBlue),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: kTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: kSubTextColor,
          ),
        ),
      ),
    );
  }

  /// A single item for the stats card
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: kPrimaryBlue, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: kSubTextColor,
          ),
        ),
      ],
    );
  }

  /// A single check/cross item for the infrastructure list
  Widget _buildInfrastructureItem(String label, bool hasComponent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(
            hasComponent ? Icons.check_circle : Icons.cancel_outlined,
            color: hasComponent ? Colors.green : Colors.red,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: kTextColor,
              ),
=======
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
>>>>>>> main
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

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
>>>>>>> main
}