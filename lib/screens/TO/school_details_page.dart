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
  static const Color kPrimaryColor = Color(0xFF4F46E5);
  static const Color kPrimaryDark = Color(0xFF312E81);
  static const Color kBackgroundColor = Color(0xFFF8FAFC);
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B);
  static const Color kSubTextColor = Color(0xFF64748B);
  static const Color kActiveColor = Color(0xFF10B981);
  static const Color kInactiveColor = Color(0xFF94A3B8);
  static const Color kAccentColor = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('School Details',
            style: TextStyle(color: kTextColor, fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState();
          }

          final schoolData = snapshot.data!.data() as Map<String, dynamic>;
          final infrastructure = schoolData['infrastructure'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(schoolData),
                    const SizedBox(height: 24),
                    _buildStatsCard(schoolData),
                    const SizedBox(height: 24),
                    _buildInfrastructureCard(infrastructure),
                    const SizedBox(height: 32),
                    _buildActionButtons(context, schoolData),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            spreadRadius: 1, blurRadius: 20, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['schoolName'] ?? 'Unknown School',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          _buildHeroDetailRow(Icons.location_on_rounded, data['schoolAddress']),
          _buildHeroDetailRow(Icons.email_rounded, data['schoolEmail']),
          _buildHeroDetailRow(Icons.phone_rounded, data['schoolPhone']),
          _buildHeroDetailRow(Icons.category_rounded, data['schoolType']),
          _buildHeroDetailRow(Icons.map_rounded, data['educationalZone'] != null ? '${data['educationalZone']} Zone' : null),
        ],
      ),
    );
  }

  Widget _buildHeroDetailRow(IconData icon, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personnel & Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextColor, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              _buildStatItem('Students', data['numStudents']?.toString(), Icons.group_rounded),
              _buildStatItem('Teachers', data['numTeachers']?.toString(), Icons.school_rounded),
              _buildStatItem('Staff', data['numNonAcademic']?.toString(), Icons.business_center_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String? value, IconData icon) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimaryColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value ?? 'N/A', style: const TextStyle(fontSize: 22, color: kTextColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: kSubTextColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfrastructureCard(Map<String, dynamic> infrastructure) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Infrastructure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextColor, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24, runSpacing: 16,
            children: [
              _buildInfrastructureItem('Electricity', infrastructure['electricity'] ?? false, Icons.bolt_rounded),
              _buildInfrastructureItem('Water Supply', infrastructure['waterSupply'] ?? false, Icons.water_drop_rounded),
              _buildInfrastructureItem('Sanitation', infrastructure['sanitation'] ?? false, Icons.cleaning_services_rounded),
              _buildInfrastructureItem('Communication', infrastructure['communication'] ?? false, Icons.wifi_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureItem(String label, bool hasComponent, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasComponent ? kActiveColor.withOpacity(0.1) : kInactiveColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: hasComponent ? kActiveColor : kInactiveColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 15, color: hasComponent ? kTextColor : kSubTextColor, 
            fontWeight: hasComponent ? FontWeight.w600 : FontWeight.w500,
            decoration: hasComponent ? null : TextDecoration.lineThrough
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data) {
    final bool isLargeScreen = MediaQuery.of(context).size.width >= 600;
    if (isLargeScreen) {
      return Row(
        children: [
          Expanded(child: _buildEditButton(context, data)),
          const SizedBox(width: 16),
          Expanded(child: _buildMapButton(context, data)),
        ],
      );
    }
    return Column(
      children: [
        _buildEditButton(context, data),
        const SizedBox(height: 16),
        _buildMapButton(context, data),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, Map<String, dynamic> data) {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: kAccentColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditSchoolScreen(schoolId: widget.schoolId, schoolData: data))),
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        label: const Text('Edit Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _buildMapButton(BuildContext context, Map<String, dynamic> data) {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          final String schoolName = data['schoolName'] ?? '';
          if (schoolName.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: School name is missing.')));
            return;
          }
          // Fix: Navigating directly to ViewMasterPlanScreen using the schoolName
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewMasterPlanScreen(schoolName: schoolName),
            ),
          );
        },
        icon: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
        label: const Text('View Master Plan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
            child: Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('School Not Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 8),
          const Text('The details for this school could not be loaded.', style: TextStyle(fontSize: 15, color: kSubTextColor)),
        ],
      ),
    );
  }
}