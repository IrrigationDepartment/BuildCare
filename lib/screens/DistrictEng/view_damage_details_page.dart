// view_damage_details_page.dart
import 'package:flutter/material.dart';
import 'damage_details_dialog.dart'; // 1. Import the new dialog file

class ViewDamageDetailsPage extends StatelessWidget {
  const ViewDamageDetailsPage({super.key});

  // Define consistent colors
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _secondaryYellow = Color(0xFFFFC107); // Used for Edit button
  static const Color _backgroundColor = Color(0xFFF0F2F5);

  // Sample data for the Damage Details list
  final List<Map<String, String>> damageReports = const [
    {
      'school': "G/Rippon Girls' Collage",
      'details': 'Roof leakage in science lab.',
      'date': '2025/10/20',
      'status': 'Pending TO review',
    },
    {
      'school': 'Ambalangoda Central College',
      'details': 'Damaged boundary wall section.',
      'date': '2025/10/15',
      'status': 'Work in progress',
    },
    {
      'school': 'Galle Vidyalaya',
      'details': 'Electrical short circuit in library.',
      'date': '2025/10/01',
      'status': 'Completed',
    },
    {
      'school': 'Baddegama National School',
      'details': 'Floor damage in main hall.',
      'date': '2025/09/28',
      'status': 'Pending TO review',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Damage Reports', style: TextStyle(color: Color.fromARGB(255, 5, 5, 5))),
        backgroundColor: const Color.fromARGB(255, 248, 248, 248),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 13, 13, 13)),
      ),
      backgroundColor: _backgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: damageReports.length,
        itemBuilder: (context, index) {
          return _buildReportCard(context, damageReports[index]);
        },
      ),
    );
  }

  // Refactored to use the imported DamageDetailsDialog
  void _showDamageDetailsDialog(BuildContext context, Map<String, String> report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DamageDetailsDialog(report: report); // Use the imported widget
      },
    );
  }

  // Widget to build a single report card
  Widget _buildReportCard(BuildContext context, Map<String, String> report) {
    final String school = report['school'] ?? 'N/A';
    final String details = report['details'] ?? 'No details';
    final String date = report['date'] ?? 'N/A';
    final String status = report['status'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. School Name (Title)
            Text(
              school,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 8),

            // 2. Details & Date (Subtitle/Body)
            Text('Details: $details', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Date: $date', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 4),

            // 3. Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. VIEW Button (Blue) - Calls the external dialog
                _buildActionButton(
                  context,
                  'View',
                  Icons.visibility,
                  _primaryBlue,
                  () {
                    _showDamageDetailsDialog(context, report); // Call external dialog
                  },
                ),
                const SizedBox(width: 8),

                // 2. EDIT Button (Yellow)
                _buildActionButton(
                  context,
                  'Edit',
                  Icons.edit,
                  _secondaryYellow,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Editing Report for: $school')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a consistent action button style
  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color.fromARGB(255, 255, 255, 255)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to determine status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'work in progress':
        return _primaryBlue; // Or a specific 'in progress' color
      case 'pending to review':
      default:
        return Colors.red;
    }
  }
}