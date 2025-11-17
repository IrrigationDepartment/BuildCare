import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_contractor_screen.dart';
import 'view_contractor_screen.dart';

// --- Data Model (No changes needed here) ---
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

// --- UPDATED: Changed to StatefulWidget to handle Search State ---
class ContractorListScreen extends StatefulWidget {
  const ContractorListScreen({super.key});

  @override
  State<ContractorListScreen> createState() => _ContractorListScreenState();
}

class _ContractorListScreenState extends State<ContractorListScreen> {
  // Controller to handle the text input
  final TextEditingController _searchController = TextEditingController();
  // String to store what the user is typing
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 1,
        // --- SEARCH BAR UI IN APP BAR ---
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Name or CIDA No...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              // Add a clear button when text exists
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = "";
                        });
                      },
                    )
                  : null,
            ),
            // Update the state whenever the user types
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contractor_details')
            .orderBy('companyName')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No contractors found.'));
          }

          // 1. Convert all Firestore documents to Contractor objects
          final List<Contractor> allContractors = snapshot.data!.docs
              .map((doc) => Contractor.fromFirestore(doc))
              .toList();

          // 2. --- FILTERING LOGIC ---
          // If search query is empty, show all. Otherwise, filter the list.
          final List<Contractor> filteredContractors = allContractors.where((contractor) {
            final nameLower = contractor.contractorName.toLowerCase();
            final cidaLower = contractor.cidaRegistrationNumber.toLowerCase();
            final companyLower = contractor.companyName.toLowerCase();
            
            // Check if the query matches Name OR CIDA OR Company
            return nameLower.contains(_searchQuery) || 
                   cidaLower.contains(_searchQuery) ||
                   companyLower.contains(_searchQuery);
          }).toList();

          // 3. Check if search result is empty
          if (filteredContractors.isEmpty) {
             return Center(
               child: Text('No results found for "$_searchQuery"'),
             );
          }

          return ListView.builder(
            itemCount: filteredContractors.length,
            itemBuilder: (context, index) {
              final contractor = filteredContractors[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.business,
                    color: Color(0xFF42A5F5),
                    size: 30,
                  ),
                  title: Text(
                    contractor.companyName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // Displaying both Name and CIDA so user sees what they searched for
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${contractor.contractorName}'),
                      Text('CIDA: ${contractor.cidaRegistrationNumber}', 
                           style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddContractorScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Contractor'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}