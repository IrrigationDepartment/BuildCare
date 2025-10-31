// File: SchoolDetailsDialog.dart

import 'package:flutter/material.dart';
// Assuming the School model is accessible, either imported or defined locally
// import 'school_model.dart'; 

class SchoolDetailsDialog extends StatelessWidget {
  final  school;

  const SchoolDetailsDialog({Key? key, required this.school}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We use AlertDialog for the base structure, then customize its content
    return AlertDialog(
      // Set content padding to zero to allow custom spacing in the header
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section: Title and Close Button (matching screenshot) ---
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
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            // --- Details List ---
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

  // Helper widget to display a single detail line
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