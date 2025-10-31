// File: manage_schools_page.dart (Updated)

import 'package:flutter/material.dart';
// Assuming ManageSchoolsPage is in the same directory as this file
// If SchoolDetailsDialog is in a separate file, import it here:
// import 'SchoolDetailsDialog.dart'; 

// --- School Data Model (Included here for simplicity) ---
class School {
  final String name;
  final String address;
  final String phoneNumber;
  final String type;
  final String zone;
  final int students;
  final int teachers;
  final int nonAcademicStaff;
  final int infrastructureComponents;

  School({
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.type,
    required this.zone,
    required this.students,
    required this.teachers,
    required this.nonAcademicStaff,
    required this.infrastructureComponents,
  });

  static School anulaDevi = School(
    name: 'Anula Devi Balika Vidyalaya',
    address: 'Anula Devi Balika Vidyalaya, Magalle, Galle',
    phoneNumber: '0912256932',
    type: 'Government',
    zone: 'Akmeemana',
    students: 5000,
    teachers: 500,
    nonAcademicStaff: 150,
    infrastructureComponents: 5000,
  );
}

// --- School Details Dialog (Included here for simplicity) ---
class SchoolDetailsDialog extends StatelessWidget {
  final School school;
  const SchoolDetailsDialog({Key? key, required this.school}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'View School Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem('School Name', school.name),
                  _buildDetailItem('School Address', school.address),
                  _buildDetailItem('School Phone Number', school.phoneNumber),
                  _buildDetailItem('School Type', school.type),
                  _buildDetailItem('School Educational Zone', school.zone),
                  _buildDetailItem('Number of Students in School', school.students.toString()),
                  _buildDetailItem('Number of Teachers in School', school.teachers.toString()),
                  _buildDetailItem('Number of Non-Academic Staff', school.nonAcademicStaff.toString()),
                  _buildDetailItem('Infrastructure Components', school.infrastructureComponents.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '• $label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}
// --- End of School Details Dialog ---


class ManageSchoolsPage extends StatelessWidget {
  const ManageSchoolsPage({Key? key}) : super(key: key);

  // Function to show the school details dialog
  void _showSchoolDetails(BuildContext context, School school) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SchoolDetailsDialog(school: school);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            _buildSearchBar(),
            const SizedBox(height: 15),

            // Pass the sample data to the card, so it can be used for the 'View' button
            _buildSchoolCard(
              'Anula Devi Balika Vidyalaya',
              'Magalle, Galle.',
              'Mrs. Devika Haputhantry',
              School.anulaDevi, // Pass the sample school object
            ),
            _buildSchoolCard(
              'Anula Devi Balika Vidyalaya',
              'Magalle, Galle.',
              'Mrs. Devika Haputhantry',
              School.anulaDevi, // Pass the sample school object
            ),
            _buildSchoolCard(
              'Anula Devi Balika Vidyalaya',
              'Magalle, Galle.',
              'Mrs. Devika Haputhantry',
              School.anulaDevi, // Pass the sample school object
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    // ... (SearchBar code remains the same) ...
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search Schools..........',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 10.0),
        ),
      ),
    );
  }

  // UPDATED: SchoolCard now accepts the full School object
  Widget _buildSchoolCard(String schoolName, String location, String principal, School schoolData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              schoolName,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(location, style: const TextStyle(color: Colors.grey)),
            Text(principal),
            const SizedBox(height: 10),
            Builder(
              builder: (BuildContext cardContext) { // Use Builder to get a context for the buttons
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    // Activation/Deactivation Buttons
                    Row(
                      children: [
                        _buildStatusButton('Activate', Colors.green, Icons.check, () {}),
                        const SizedBox(width: 5),
                        _buildStatusButton('Deactivate', Colors.red, Icons.close, () {}),
                      ],
                    ),
                    // View and Edit Buttons
                    Row(
                      children: [
                        // 🔑 UPDATED: 'View' button calls _showSchoolDetails
                        _buildActionButton('View', Colors.blue, Icons.remove_red_eye, () {
                          _showSchoolDetails(cardContext, schoolData);
                        }),
                        const SizedBox(width: 5),
                        _buildActionButton('Edit', Colors.amber, Icons.edit, () {}),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Status button now includes an onTap callback
  Widget _buildStatusButton(String text, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Action button now includes an onTap callback
  Widget _buildActionButton(String text, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}