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

          final schoolData = snapshot.data!.data() as Map<String, dynamic>;
          final infrastructure =
              schoolData['infrastructure'] as Map<String, dynamic>? ?? {};
          
          // පාසල ඇතුළත් කළ පරිශීලකයාගේ ID එක (මෙම field එක Firestore හි තිබිය යුතුය)
          final String? addedByUserId = schoolData['addedBy'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. General Info Card
                _buildInfoCard(schoolData),
                const SizedBox(height: 15),

                // 2. Added By Info Section (නව කොටස)
                if (addedByUserId != null) 
                  _buildAddedBySection(addedByUserId)
                else
                  _buildSimpleNote("Registered user info not available."),

                const SizedBox(height: 15),

                // 3. Stats Card (Students/Teachers/Staff)
                _buildStatsCard(schoolData),
                const SizedBox(height: 15),

                // 4. Infrastructure Card
                _buildInfrastructureCard(infrastructure),
                const SizedBox(height: 20),

                // 5. Action Buttons
                _buildActionButtons(context, schoolData),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- නව Widget: ඇතුළත් කළ පුද්ගලයාගේ නම සහ තනතුර පෙන්වීම ---
  Widget _buildAddedBySection(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }
        
        String name = "Unknown User";
        String position = "N/A";

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          name = userData['name'] ?? "Unknown User";
          position = userData['userType'] ?? "Officer"; // userType හෝ position ලෙස භාවිතා කරන්න
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
            ],
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
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                  Text(position, style: const TextStyle(fontSize: 13, color: kPrimaryBlue, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleNote(String note) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Text(note, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
    );
  }

  // --- පවතින අනෙකුත් Widgets (වෙනස් කර නැත) ---

  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('School Name', data['schoolName'], isHeader: true), 
          const Divider(height: 20, thickness: 1.5, color: kBackgroundColor),
          _buildDetailRow('Address', data['schoolAddress']),
          _buildDetailRow('E-mail', data['schoolEmail']),
          _buildDetailRow('Phone', data['schoolPhone']),
          _buildDetailRow('Type', data['schoolType']),
          _buildDetailRow('Zone', data['educationalZone']),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personnel and Student Count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)),
          const Divider(height: 20, thickness: 1, color: kBackgroundColor),
          _buildStatItem('Students', data['numStudents']?.toString(), Icons.group),
          _buildStatItem('Teachers', data['numTeachers']?.toString(), Icons.person_pin_circle),
          _buildStatItem('Staff', data['numNonAcademic']?.toString(), Icons.business_center),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 16, color: kTextColor, fontWeight: FontWeight.w500)),
                Text(value ?? 'N/A', style: const TextStyle(fontSize: 18, color: kPrimaryBlue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
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
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Infrastructure Components', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 12),
          _buildInfrastructureItem('Electricity', infrastructure['electricity'] ?? false),
          _buildInfrastructureItem('Water Supply', infrastructure['waterSupply'] ?? false),
          _buildInfrastructureItem('Sanitation', infrastructure['sanitation'] ?? false),
          _buildInfrastructureItem('Communication', infrastructure['communication'] ?? false),
        ],
      ),
    );
  }

  Widget _buildInfrastructureItem(String label, bool hasComponent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(hasComponent ? Icons.check_circle_outline : Icons.cancel_outlined, color: hasComponent ? kActiveColor : kInactiveColor, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16, color: kTextColor)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditSchoolScreen(schoolId: widget.schoolId, schoolData: data)));
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Edit School Details', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewMasterPlanScreen()));
            },
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            label: const Text('View Master Plan', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isHeader = false}) {
    final displayValue = value ?? 'N/A';
    final double fontSize = isHeader ? 22 : 16;
    final fontWeightValue = isHeader ? FontWeight.bold : FontWeight.w500; 

    return Padding(
      padding: EdgeInsets.only(bottom: isHeader ? 0 : 8.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: fontSize, color: kTextColor, decoration: TextDecoration.none),
          children: <TextSpan>[
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: displayValue, style: TextStyle(fontWeight: fontWeightValue)),
          ],
        ),
      ),
    );
  }
}