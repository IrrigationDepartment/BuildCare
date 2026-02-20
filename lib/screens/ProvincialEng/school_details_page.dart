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
<<<<<<< HEAD
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
=======

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

>>>>>>> main
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('School details not found.'));
          }

<<<<<<< HEAD
          final schoolData = snapshot.data!.data() as Map<String, dynamic>;
          final infrastructure =
              schoolData['infrastructure'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Increased padding for better look
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. General Info Card
                _buildInfoCard(schoolData),
                const SizedBox(height: 15),

                // 2. Stats Card (Students/Teachers/Staff)
                _buildStatsCard(schoolData),
                const SizedBox(height: 15),

                // 3. Infrastructure Card
                _buildInfrastructureCard(infrastructure),
                const SizedBox(height: 20),

                // 4. Action Buttons
                _buildActionButtons(context, schoolData),
=======
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
>>>>>>> main
              ],
            ),
          );
        },
      ),
    );
  }

<<<<<<< HEAD
  // --- 1. General Information Card ---
  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity, 
=======
  // --- UI Components ---

  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
>>>>>>> main
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), 
          ),
        ],
=======
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
>>>>>>> main
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          // Header (School Name)
          _buildDetailRow('School Name', data['schoolName'], isHeader: true), 
          const Divider(height: 20, thickness: 1.5, color: kBackgroundColor),
          
          // Details
          _buildDetailRow('Address', data['schoolAddress']),
          _buildDetailRow('E-mail', data['schoolEmail']),
          _buildDetailRow('Phone', data['schoolPhone']),
          _buildDetailRow('Type', data['schoolType']),
          _buildDetailRow('Zone', data['educationalZone']),
=======
          _buildDetailRow('School Name', data['schoolName'], isHeader: true),
          const Divider(height: 20),
          _buildDetailRow('Address', data['schoolAddress']),
          _buildDetailRow('E-mail', data['schoolEmail']),
          _buildDetailRow('Phone', data['schoolPhone']),
>>>>>>> main
        ],
      ),
    );
  }

<<<<<<< HEAD
  // --- 2. Stats Card (New) ---
  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity, 
=======
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
>>>>>>> main
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), 
          ),
        ],
=======
>>>>>>> main
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          const Text(
            'Personnel and Student Count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
          ),
          const Divider(height: 20, thickness: 1, color: kBackgroundColor),
          _buildStatItem('Students', data['numStudents']?.toString(), Icons.group),
          _buildStatItem('Teachers', data['numTeachers']?.toString(), Icons.person_pin_circle),
          _buildStatItem('Staff', data['numNonAcademic']?.toString(), Icons.business_center),
=======
          const Text('Capacity Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildStatItem('Students', data['numStudents']?.toString(), Icons.group),
          _buildStatItem('Teachers', data['numTeachers']?.toString(), Icons.person_pin_circle),
>>>>>>> main
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String? value, IconData icon) {
    return Padding(
<<<<<<< HEAD
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: kTextColor, fontWeight: FontWeight.w500),
                ),
                Text(
                  value ?? 'N/A',
                  style: const TextStyle(fontSize: 18, color: kPrimaryBlue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
=======
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value ?? '0', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
>>>>>>> main
        ],
      ),
    );
  }
<<<<<<< HEAD
  
  // --- 3. Infrastructure Card ---
  Widget _buildInfrastructureCard(Map<String, dynamic> infrastructure) {
    return Container(
      width: double.infinity,
=======

  Widget _buildInfrastructureCard(Map<String, dynamic> infra) {
    return Container(
>>>>>>> main
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 5, offset: const Offset(0, 3)),
        ],
=======
>>>>>>> main
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          const Text(
            'Infrastructure Components',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
          ),
          const SizedBox(height: 12),
          _buildInfrastructureItem('Electricity', infrastructure['electricity'] ?? false),
          _buildInfrastructureItem('Water Supply', infrastructure['waterSupply'] ?? false),
          _buildInfrastructureItem('Sanitation', infrastructure['sanitation'] ?? false),
          _buildInfrastructureItem('Communication', infrastructure['communication'] ?? false),
=======
          const Text('Infrastructure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildInfrastructureItem('Electricity', infra['electricity'] ?? false),
          _buildInfrastructureItem('Water Supply', infra['waterSupply'] ?? false),
>>>>>>> main
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildInfrastructureItem(String label, bool hasComponent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            hasComponent ? Icons.check_circle_outline : Icons.cancel_outlined, // Cleaner outline icons
            color: hasComponent ? kActiveColor : kInactiveColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: kTextColor),
          ),
=======
  Widget _buildInfrastructureItem(String label, bool has) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(has ? Icons.check_circle : Icons.cancel, color: has ? kActiveColor : kInactiveColor),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
>>>>>>> main
        ],
      ),
    );
  }

<<<<<<< HEAD
  // --- 4. Action Buttons ---
  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data) {
=======
  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data, String schoolName) {
>>>>>>> main
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
<<<<<<< HEAD
                context,
                MaterialPageRoute(
                  builder: (context) => EditSchoolScreen(schoolId: widget.schoolId, schoolData: data),
                ),
=======
                context, 
                MaterialPageRoute(builder: (context) => EditSchoolScreen(schoolId: widget.schoolId, schoolData: data))
>>>>>>> main
              );
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Edit School Details', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
<<<<<<< HEAD
              backgroundColor: kAccentColor, // Changed to a different accent color
=======
              backgroundColor: kAccentColor,
>>>>>>> main
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
<<<<<<< HEAD
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewMasterPlanScreen()),
=======
              // Master Plan screen එකට schoolName එක යැවීම
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ViewMasterPlanScreen(schoolName: schoolName))
>>>>>>> main
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

<<<<<<< HEAD
  // --- MODIFIED HELPER: Uses RichText for inline "Attribute: Value" format with wrapping ---
  Widget _buildDetailRow(String label, String? value, {bool isHeader = false}) {
    final displayValue = value ?? 'N/A';
    // Use larger font for the school name header
    final double fontSize = isHeader ? 22 : 16;
    
    // School name value should also be bold, others should be normal weight
    final fontWeightValue = isHeader ? FontWeight.bold : FontWeight.w500; 

    return Padding(
      padding: EdgeInsets.only(bottom: isHeader ? 0 : 8.0), // Less padding for header
      child: RichText(
        text: TextSpan(
          // Default style for the RichText
          style: DefaultTextStyle.of(context).style.copyWith(
            fontSize: fontSize, 
            color: kTextColor,
            decoration: TextDecoration.none, // Removes the underline
          ),
          children: <TextSpan>[
            // Attribute/Label: Always bold and followed by a colon
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Value: Normal weight, except for the header value
            TextSpan(
              text: displayValue,
              style: TextStyle(fontWeight: fontWeightValue),
            ),
          ],
        ),
=======
  Widget _buildDetailRow(String label, String? value, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kSubTextColor, fontSize: 12)),
          Text(value ?? 'N/A', style: TextStyle(fontSize: isHeader ? 22 : 16, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: kTextColor)),
        ],
>>>>>>> main
      ),
    );
  }
}