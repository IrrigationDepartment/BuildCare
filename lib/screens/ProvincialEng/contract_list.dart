import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
=======
import 'package:intl/intl.dart';
import 'add_contract.dart'; // Import the Add/Edit screen
>>>>>>> main

class ContractListPage extends StatelessWidget {
  const ContractListPage({super.key});

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Active Contracts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add logic to create new contract
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ASSUMPTION: You have a collection named 'contracts'
        stream: FirebaseFirestore.instance.collection('contracts').snapshots(),
=======
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
>>>>>>> main
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
<<<<<<< HEAD
                  Icon(Icons.description_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No Contracts Found',
                      style: TextStyle(color: Colors.grey)),
=======
                  Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No Contracts Found', style: TextStyle(color: Colors.grey)),
>>>>>>> main
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
<<<<<<< HEAD
              var data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['contractId'] ?? 'ID: #00$index',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data['status'] ?? 'Active',
                              style: TextStyle(
                                  color: Colors.indigo.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['projectName'] ?? 'Renovation Project',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Deadline: ${data['deadline'] ?? 'TBD'}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      )
                    ],
=======
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
>>>>>>> main
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> main
