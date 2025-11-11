import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the new contract details form screen
import 'add_contract.dart';
// --- 1. IMPORT THE VIEW DETAILS SCREEN ---
import 'view_details.dart';

// --- Data Model for Contract Details ---
class Contract {
  final String id;
  final String cidaRegisterNumber;
  final String contractorName;

  Contract({
    required this.id,
    required this.cidaRegisterNumber,
    required this.contractorName,
  });

  // Factory constructor to create a Contract from a Firestore Document
  factory Contract.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Contract(
      id: doc.id,
      // Field name must match what is stored in Firestore
      cidaRegisterNumber: data['cidaRegisterNumber'] ?? 'N/A',
      contractorName: data['contractorName'] ?? 'Unknown Contractor',
    );
  }
}

// --- Manage Contracts List Screen Widget ---
class ContractDetailsScreen extends StatelessWidget {
  const ContractDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Contracts'),
        backgroundColor:
            const Color(0xFFF5F7FA), // Use the light background color
        elevation: 1,
      ),
      // The StreamBuilder listens to the 'contracts' collection in Firestore
      body: StreamBuilder<QuerySnapshot>(
        // Ensure this collection name matches the one used in the form (add_contract.dart)
        stream: FirebaseFirestore.instance.collection('contracts').snapshots(),
        builder: (context, snapshot) {
          // Display a loading indicator while data is being fetched
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Display an error if the connection fails
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Display a message if no data is found
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No contracts found. Tap "Add Contract" to begin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // --- Data Loaded Successfully: Build the List ---
          final List<Contract> contracts = snapshot.data!.docs
              .map((doc) => Contract.fromFirestore(doc))
              .toList();

          return Column(
            children: [
              // Search Bar (Mimicking the structure of the school list)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by CIDA No. or Contractor Name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) {
                    // TODO: Implement search/filtering logic here
                  },
                ),
              ),

              // Contract List
              Expanded(
                child: ListView.builder(
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    final contract = contracts[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 10.0),
                      child: ListTile(
                        leading: const Icon(
                          Icons
                              .engineering, // A more specific icon for contractors/projects
                          color: Color(0xFF42A5F5),
                          size: 30,
                        ),
                        title: Text(
                          contract.contractorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          'CIDA Reg No: ${contract.cidaRegisterNumber}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: TextButton.icon(
                          onPressed: () {
                            // --- 2. NAVIGATION TO VIEW DETAILS ---
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ViewContractDetailsScreen(
                                    contractId: contract.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline,
                              size: 18, color: Colors.blue),
                          label: const Text('Details',
                              style: TextStyle(color: Colors.blue)),
                        ),
                        onTap: () {
                          // --- 2. NAVIGATION TO VIEW DETAILS (also on tap) ---
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ViewContractDetailsScreen(
                                  contractId: contract.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // Floating Action Button for "Add Contract"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // *** NAVIGATION TO ADD CONTRACT SCREEN ***
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddContractScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Contract'),
        backgroundColor: const Color(0xFF42A5F5), // Primary Blue
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
