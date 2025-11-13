import 'package:flutter/material.dart';

class DamageDetailsDialog extends StatelessWidget {
  // The report data map is passed to the dialog
  final Map<String, String> report;

  const DamageDetailsDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Damage Details',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 30, 46, 66), // Title color
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. School Name
            _buildDetailRow('School', report['school']!),
            const Divider(),
            // 2. Damage Details
            _buildDetailRow('Damage Details', report['details']!),
            const Divider(),
            // 3. Date
            _buildDetailRow('Date', report['date']!),
            const Divider(),
            // 4. Status
            _buildDetailRow('Status', report['status']!),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text(
            'CLOSE',
            style: TextStyle(color: Colors.black),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }

  // Helper widget to build a consistent row for details in the dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black54, // Label color
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87, // Value color
            ),
          ),
        ],
      ),
    );
  }
}