import 'package:flutter/material.dart';

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
        title: const Text('Damage Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
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

  // --- NEW FUNCTION: Show Damage Details Dialog ---
  void _showDamageDetailsDialog(BuildContext context, Map<String, String> report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Damage Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _primaryBlue, // Title color
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
      },
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
                // 1. VIEW Button (Blue) - ***UPDATED CALL HERE***
                _buildActionButton(
                  context,
                  'View',
                  Icons.visibility,
                  _primaryBlue,
                  () {
                    // Call the new function when 'View' is tapped
                    _showDamageDetailsDialog(context, report);
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
            Icon(icon, size: 16, color: Colors.white),
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