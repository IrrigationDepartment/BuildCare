import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the new Add/Edit screen
import 'add_contractor_screen.dart';
// Import the new View Details screen
import 'view_contractor_screen.dart';

// --- Data Model for a Contractor ---
class Contractor {
  final String id;
  final String companyName;
  final String contractorName;
  final String cidaRegistrationNumber;

  Contractor({
    required this.id,
    required this.companyName,
    required this.contractorName,
    required this.cidaRegistrationNumber,
  });

  // Factory constructor to create a Contractor from a Firestore Document
  factory Contractor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Contractor(
      id: doc.id,
      companyName: data['companyName'] ?? 'N/A',
      contractorName: data['contractorName'] ?? 'Unknown Contractor',
      cidaRegistrationNumber: data['cidaRegistrationNumber'] ?? 'N/A',
    );
  }
}

// --- Manage Contractors List Screen Widget ---
class ContractorListScreen extends StatelessWidget {
  const ContractorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Contractors'),
        backgroundColor:
            const Color(0xFFF5F7FA), // Use the light background color
        elevation: 1,
      ),
      // The StreamBuilder listens to the 'contractor_details' collection
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contractor_details')
            .orderBy('companyName') // Sort by company name
            .snapshots(),
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
                  'No contractors found. Tap "Add Contractor" to begin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // --- Data Loaded Successfully: Build the List ---
          final List<Contractor> contractors = snapshot.data!.docs
              .map((doc) => Contractor.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: contractors.length,
            itemBuilder: (context, index) {
              final contractor = contractors[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.business, // Icon for 'company'
                    color: Color(0xFF42A5F5),
                    size: 30,
                  ),
                  title: Text(
                    contractor.companyName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Contractor: ${contractor.contractorName}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // --- NAVIGATION TO VIEW DETAILS ---
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ViewContractorScreen(
                            contractorId: contractor.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // Floating Action Button for "Add Contractor"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // *** NAVIGATION TO ADD CONTRACTOR SCREEN ***
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddContractorScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Contractor'),
        backgroundColor: const Color(0xFF42A5F5), // Primary Blue
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}