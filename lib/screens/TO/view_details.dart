import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Make sure this import matches your exact file name
import 'add_contract.dart'; 

class ViewContractDetailsScreen extends StatelessWidget {
  final String contractId;

  const ViewContractDetailsScreen({super.key, required this.contractId});

  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500

  // Helper function to format dates safely
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('yyyy-MM-dd').format(timestamp);
    }
    return 'N/A';
  }

  // Helper function to format currency safely
  String _formatCurrency(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      return NumberFormat.currency(locale: 'en_US', symbol: 'LKR ').format(value);
    }
    // Fallback if it was saved as a string somehow
    return 'LKR $value'; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Contract Details',
          style: TextStyle(fontWeight: FontWeight.w800, color: kTextColor, fontSize: 20),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('contracts').doc(contractId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading details: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Contract details not found.', style: TextStyle(color: kSubTextColor)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              // RESPONSIVE WRAPPER: Centers the profile on large screens
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Project Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextColor, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 24),
                        
                        // FIXED: Replaced 'cidaRegisterNumber' with 'cidaNo'
                        _buildProfileRow(
                          label: 'CIDA Reg. Number',
                          value: data['cidaNo']?.toString() ?? 'N/A', 
                          icon: Icons.assignment_ind_rounded,
                        ),
                        const Divider(height: 30, color: Colors.black12),
                        
                        _buildProfileRow(
                          label: 'Contractor Name',
                          value: data['contractorName']?.toString() ?? 'N/A',
                          icon: Icons.person_rounded,
                        ),
                        const Divider(height: 30, color: Colors.black12),
                        
                        // FIXED: Replaced 'typeOfContract' with 'projectType'
                        _buildProfileRow(
                          label: 'Type of Contract',
                          value: data['projectType']?.toString() ?? 'N/A',
                          icon: Icons.category_rounded,
                        ),
                        const Divider(height: 30, color: Colors.black12),
                        
                        // FIXED: Replaced 'contractValue' with 'value'
                        _buildProfileRow(
                          label: 'Contract Value',
                          value: _formatCurrency(data['value']), 
                          icon: Icons.attach_money_rounded,
                        ),
                        const Divider(height: 30, color: Colors.black12),
                        
                        _buildProfileRow(
                          label: 'Start Date',
                          value: _formatDate(data['startDate']),
                          icon: Icons.calendar_today_rounded,
                        ),
                        const Divider(height: 30, color: Colors.black12),
                        
                        _buildProfileRow(
                          label: 'End Date',
                          value: _formatDate(data['endDate']),
                          icon: Icons.event_available_rounded,
                        ),

                        const SizedBox(height: 40),

                        // --- EDIT BUTTON ---
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ]
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddContractScreen(
                                    contractId: contractId,
                                    initialData: data,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                            label: const Text(
                              'Edit Details', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- REUSABLE PREMIUM ROW WIDGET ---
  Widget _buildProfileRow({required String label, required String value, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: kSubTextColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: kTextColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}