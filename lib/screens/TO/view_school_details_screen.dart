import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_master_plan_screen.dart';

class ViewSchoolDetailsScreen extends StatefulWidget {
  final String schoolId;

  const ViewSchoolDetailsScreen({super.key, required this.schoolId});

  @override
  State<ViewSchoolDetailsScreen> createState() => _ViewSchoolDetailsScreenState();
}

class _ViewSchoolDetailsScreenState extends State<ViewSchoolDetailsScreen> {
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
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextColor),
        title: const Text('School Details', style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).get(),
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
          final schoolName = schoolData['schoolName'] ?? '';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
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
                    _buildMasterPlanButton(context, schoolName), 
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainInfoCard(Map<String, dynamic> data) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            _buildInfoTile(icon: Icons.school, title: data['schoolName'] ?? 'N/A', subtitle: 'School Name'),
            _buildInfoTile(icon: Icons.location_on_outlined, title: data['schoolAddress'] ?? 'N/A', subtitle: 'Address'),
            _buildInfoTile(icon: Icons.email_outlined, title: data['schoolEmail'] ?? 'N/A', subtitle: 'Email'),
            _buildInfoTile(icon: Icons.phone_outlined, title: data['schoolPhone'] ?? 'N/A', subtitle: 'Phone'),
            _buildInfoTile(icon: Icons.business_outlined, title: data['schoolType'] ?? 'N/A', subtitle: 'School Type'),
            _buildInfoTile(icon: Icons.map_outlined, title: data['educationalZone'] ?? 'N/A', subtitle: 'Educational Zone', isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(icon: Icons.people_outline, label: 'Students', value: data['numStudents']?.toString() ?? '0'),
            _buildStatItem(icon: Icons.person_search_outlined, label: 'Teachers', value: data['numTeachers']?.toString() ?? '0'),
            _buildStatItem(icon: Icons.work_outline, label: 'Staff', value: data['numNonAcademic']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfrastructureCard(Map<String, dynamic> data) {
    final infrastructure = data['infrastructure'] as Map<String, dynamic>? ?? {};
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Infrastructure Components', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kTextColor)),
            const SizedBox(height: 16),
            _buildInfrastructureItem('Electricity', infrastructure['electricity'] ?? false),
            _buildInfrastructureItem('Water Supply', infrastructure['waterSupply'] ?? false),
            _buildInfrastructureItem('Sanitation', infrastructure['sanitation'] ?? false),
            _buildInfrastructureItem('Communication Facilities', infrastructure['communication'] ?? false),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterPlanButton(BuildContext context, String schoolName) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (schoolName.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('School name is missing!')));
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) => ViewMasterPlanScreen(schoolName: schoolName)));
        },
        icon: const Icon(Icons.map, color: Colors.white),
        label: const Text('View Master Plan', style: TextStyle(color: Colors.white, fontSize: 16)),
        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, shape: RoundedRectangleBorder(borderRadius: kBorderRadius), padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(border: Border(bottom: isLast ? BorderSide.none : BorderSide(color: kBackgroundColor, width: 1.5))),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: kPrimaryBlue),
        title: Text(title, style: const TextStyle(fontSize: 16, color: kTextColor, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: kSubTextColor)),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: kPrimaryBlue, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: kSubTextColor)),
      ],
    );
  }

  Widget _buildInfrastructureItem(String label, bool hasComponent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(hasComponent ? Icons.check_circle : Icons.cancel_outlined, color: hasComponent ? Colors.green : Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: kTextColor))),
        ],
      ),
    );
  }
}