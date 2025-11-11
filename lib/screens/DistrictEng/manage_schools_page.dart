// main_manage_schools_page.dart 

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
//import 'package:intl/intl.dart';

// --- Import the new file for editing ---
import 'edit_school_page.dart';
import '../../models/school.dart';

// School model moved to lib/models/school.dart

// --- Updated School Details Dialog ---
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
                  _buildDetailItem(
                      'Number of Students', school.students.toString()),
                  _buildDetailItem(
                      'Number of Teachers', school.teachers.toString()),
                  _buildDetailItem('Number of Non-Academic Staff',
                      school.nonAcademicStaff.toString()),
                  _buildDetailItem('Infrastructure Components',
                      school.infrastructureComponents.toString()),

                  // --- New "Valuable Details" Section ---
                  const Padding(
                    padding: EdgeInsets.only(top: 15.0, bottom: 5.0),
                    child: Text(
                      'Admin Details',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    ),
                  ),
                  const Divider(),
                  _buildDetailItem(
                      'Status', school.isActive ? 'Active' : 'Deactivated',
                      valueColor: school.isActive ? Colors.green : Colors.red),
                  _buildDetailItem(
                      'Added By (NIC)', school.addedByNic ?? 'N/A'),
                  _buildDetailItem('Added On', school.formattedAddedAt),
                  // NEW: Display last edit info
                  _buildDetailItem(
                      'Last Edited By (NIC)', school.lastEditedByNic ?? 'N/A'),
                  _buildDetailItem(
                      'Last Edited On', school.formattedLastEditedAt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
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
              style: TextStyle(
                fontSize: 14.5,
                color: valueColor ??
                    Colors.black87, // Use custom color if provided
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// --- End of School Details Dialog ---

// --- Main Page (Converted to StatefulWidget) ---
class ManageSchoolsPage extends StatefulWidget {
  const ManageSchoolsPage({Key? key}) : super(key: key);

  @override
  State<ManageSchoolsPage> createState() => _ManageSchoolsPageState();
}

class _ManageSchoolsPageState extends State<ManageSchoolsPage> {
  // Function to show the school details dialog
  void _showSchoolDetails(BuildContext context, School school) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SchoolDetailsDialog(school: school);
      },
    );
  }

  // NEW: Function to navigate to the Edit page
  // The EditSchoolPage is now imported from a separate file
  void _navigateToEditPage(BuildContext context, School school) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSchoolPage(school: school),
      ),
    );
  }

  // Function to update the school's activation status in Firestore
  Future<void> _updateSchoolStatus(School school, bool newStatus) async {
    try {
      // NEW: Also update the edit record when activating/deactivating
      // TODO: Replace 'admin_nic_001' with the actual logged-in user's NIC
      final String currentUserNic = "admin_nic_001";

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .update({
        'isActive': newStatus,
        'lastEditedAt': Timestamp.now(),
        'lastEditedByNic': currentUserNic,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${school.name} has been ${newStatus ? "activated" : "deactivated"}.'),
          backgroundColor: newStatus ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schools'), // Updated title
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 3),

          // --- StreamBuilder to display live data from Firestore ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('schools').snapshots(),
              builder: (context, snapshot) {
                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Handle error state
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Handle no data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No schools found.'));
                }

                // If we have data, display it in a list
                final schoolDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: schoolDocs.length,
                  itemBuilder: (context, index) {
                    // Convert Firestore doc to our School object
                    final school = School.fromFirestore(schoolDocs[index]);
                    // Build the card for each school
                    return _buildSchoolCard(school);
                  },
                );
              },
            ),
          ),
        ],
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

  // UPDATED: SchoolCard now takes a single School object
  Widget _buildSchoolCard(School school) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- School Info ---
            Text(
              school.name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(school.address, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),

            // --- New "Valuable Details" Displayed on Card ---
            _buildCardDetailRow(Icons.person_outline,
                'Added by: ${school.addedByNic ?? 'N/A'}'),
            _buildCardDetailRow(
                Icons.access_time, 'Added on: ${school.formattedAddedAt}'),
            _buildCardDetailRow(
              school.isActive ? Icons.check_circle : Icons.cancel,
              'Status: ${school.isActive ? 'Active' : 'Deactivated'}',
              color:
                  school.isActive ? Colors.green.shade700 : Colors.red.shade700,
            ),
            // NEW: Show last edit on card if it exists
            if (school.lastEditedAt != null)
              _buildCardDetailRow(Icons.edit_note,
                  'Last Edit: ${school.formattedLastEditedAt} by ${school.lastEditedByNic ?? 'N/A'}'),

            const Divider(height: 20),

            // --- Action Buttons ---
            Builder(
              builder: (BuildContext cardContext) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    // --- Activation/Deactivation Buttons ---
                    // Show only the relevant button
                    if (school.isActive)
                      _buildStatusButton(
                        'Deactivate',
                        Colors.red,
                        Icons.close,
                        () => _updateSchoolStatus(
                            school, false), // Call update fn
                      )
                    else
                      _buildStatusButton(
                        'Activate',
                        Colors.green,
                        Icons.check,
                        () =>
                            _updateSchoolStatus(school, true), // Call update fn
                      ),

                    // --- View and Edit Buttons ---
                    Row(
                      children: [
                        _buildActionButton(
                            'View', Colors.blue, Icons.remove_red_eye, () {
                          _showSchoolDetails(cardContext, school);
                        }),
                        const SizedBox(width: 5),
                        // NEW: Hook up Edit button
                        _buildActionButton('Edit', Colors.amber, Icons.edit,
                            () {
                          _navigateToEditPage(cardContext, school);
                        }),
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

  // Helper widget for detail rows on the card
  Widget _buildCardDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                fontSize: 12,
                color: color ?? Colors.black54,
                fontWeight:
                    color != null ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  // Status button
  Widget _buildStatusButton(
      String text, Color color, IconData icon, VoidCallback onTap) {
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
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Action button
  Widget _buildActionButton(
      String text, Color color, IconData icon, VoidCallback onTap) {
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
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
