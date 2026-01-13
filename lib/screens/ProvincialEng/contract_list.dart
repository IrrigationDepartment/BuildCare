import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_contract.dart'; // Import the Add/Edit screen

class ContractListPage extends StatelessWidget {
  const ContractListPage({super.key});

  // Helper to format currency
  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2).format(amount);
  }

  // Helper to format dates
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'All Active Contracts',
          style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContractScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF42A5F5),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- NOTE: orderBy was removed to display all documents regardless of timestamp ---
        stream: FirebaseFirestore.instance
            .collection('contracts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No Contracts Found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              // Extract data safely
              String contractorName = data['contractorName'] ?? 'Unknown Contractor';
              String typeOfContract = data['typeOfContract'] ?? 'Unknown Type';
              String cidaNumber = data['cidaRegisterNumber'] ?? 'N/A';
              
              // Handle contractValue conversion if it's stored as String or Number
              double contractValue = 0.0;
              if (data['contractValue'] is num) {
                 contractValue = (data['contractValue'] as num).toDouble();
              } else if (data['contractValue'] is String) {
                 contractValue = double.tryParse(data['contractValue']) ?? 0.0;
              }
              
              Timestamp? startDate = data['startDate'] as Timestamp?;
              Timestamp? endDate = data['endDate'] as Timestamp?;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Navigate to Edit Screen with existing data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddContractScreen(
                          contractId: doc.id,
                          initialData: data,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                contractorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                typeOfContract,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CIDA: $cidaNumber',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Value: ${_formatCurrency(contractValue)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              "${_formatDate(startDate)}  to  ${_formatDate(endDate)}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}