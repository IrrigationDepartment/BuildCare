import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- 1. 'add_contractor_screen.dart' IMPORT ---
import 'add_contractor_screen.dart';

class ViewContractorScreen extends StatelessWidget {
  final String contractorId;

  const ViewContractorScreen({super.key, required this.contractorId});

  // --- Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);

  // --- Widget for a single detail item ---
  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: kPrimaryBlue, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                '$label:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'N/A' : value, // Handle empty strings
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const Divider(height: 10, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  // --- Delete Contractor Logic ---
  Future<void> _deleteContractor(BuildContext context) async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to permanently delete this contractor?'),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('contractor_details')
            .doc(contractorId)
            .delete();
        // Pop back to the list screen
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete contractor: $e')),
        );
      }
    }
  }

  // --- Widget for the main content card ---
  Widget _buildDetailsCard(BuildContext context, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Contractor Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF555555)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: kPrimaryBlue, thickness: 2, height: 20),

              // Contractor Details Fields
              _buildDetailRow(
                'Company Name',
                data['companyName']?.toString() ?? 'N/A',
                icon: Icons.business,
              ),
              _buildDetailRow(
                'CIDA Reg. Number',
                data['cidaRegistrationNumber']?.toString() ?? 'N/A',
                icon: Icons.badge,
              ),
              _buildDetailRow(
                'Contractor Name',
                data['contractorName']?.toString() ?? 'N/A',
                icon: Icons.person,
              ),
              _buildDetailRow(
                'NIC Number',
                data['nicNumber']?.toString() ?? 'N/A',
                icon: Icons.credit_card,
              ),
              _buildDetailRow(
                'Contact Number',
                data['contactNumber']?.toString() ?? 'N/A',
                icon: Icons.phone,
              ),

              const SizedBox(height: 20),
              // --- 2. EDIT BUTTON ACTION ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to the Add/Edit screen in 'Edit' mode
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddContractorScreen(
                          contractorId: contractorId, // Pass the Document ID
                          initialData: data,         // Pass the current data
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 20),
                  label:
                      const Text('Edit Details', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // --- 3. DELETE BUTTON ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteContractor(context),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Delete Contractor',
                      style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'View Contractor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('contractor_details')
            .doc(contractorId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading details: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Contractor details not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildDetailsCard(context, data),
              ),
            ),
          );
        },
      ),
    );
  }
}