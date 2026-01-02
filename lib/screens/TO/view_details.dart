import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// --- 1. 'add_contract.dart' IMPORT ---
import 'add_contract.dart'; 

class ViewContractDetailsScreen extends StatelessWidget {
  final String contractId;

  const ViewContractDetailsScreen({super.key, required this.contractId});

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
            value,
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

  // --- Widget for the main content card ---
  Widget _buildDetailsCard(BuildContext context, Map<String, dynamic> data) {
    // Helper function to format dates
    String formatDate(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
      } else if (timestamp is DateTime) {
        return DateFormat('yyyy-MM-dd').format(timestamp);
      }
      return 'N/A';
    }

    // Helper function to format currency
    String formatCurrency(dynamic value) {
      if (value is num) {
        return NumberFormat.currency(locale: 'en_US', symbol: 'LKR').format(value);
      }
      return 'N/A';
    }

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
                    'Contract Details',
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
              
              // Contract Details Fields
              _buildDetailRow(
                'CIDA Reg. Number', 
                data['cidaRegisterNumber']?.toString() ?? 'N/A',
                icon: Icons.badge,
              ),
              _buildDetailRow(
                'Contractor Name', 
                data['contractorName']?.toString() ?? 'N/A',
                icon: Icons.person,
              ),
              _buildDetailRow(
                'Type of Contract', 
                data['typeOfContract']?.toString() ?? 'N/A',
                icon: Icons.category,
              ),
              _buildDetailRow(
                'Contract Value', 
                formatCurrency(data['contractValue']),
                icon: Icons.attach_money,
              ),
              _buildDetailRow(
                'Start Date', 
                formatDate(data['startDate']),
                icon: Icons.event,
              ),
              _buildDetailRow(
                'End Date', 
                formatDate(data['endDate']),
                icon: Icons.event_busy,
              ),
              
              const SizedBox(height: 20),
              // --- 2. EDIT BUTTON ACTION change---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 'Edit' screen navigate 
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddContractScreen(
                          contractId: contractId, // Document ID pass
                          initialData: data,      // current data  pass 
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Edit Details', style: TextStyle(fontSize: 16)),
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
          'View Contract',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('contracts').doc(contractId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading details: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Contract details not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                // context සහ data, _buildDetailsCard එකට pass කිරීම
                child: _buildDetailsCard(context, data),
              ),
            ),
          );
        },
      ),
    );
  }
}