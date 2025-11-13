import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_contract.dart';
import 'view_details.dart';

// --- Data Model ---
class Contract {
  final String id;
  final String cidaRegisterNumber;
  final String contractorName;

  Contract({
    required this.id,
    required this.cidaRegisterNumber,
    required this.contractorName,
  });

  factory Contract.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Contract(
      id: doc.id,
      cidaRegisterNumber: data['cidaRegisterNumber'] ?? 'N/A',
      contractorName: data['contractorName'] ?? 'Unknown Contractor',
    );
  }
}

// --- UPDATED: Changed to StatefulWidget ---
class ContractDetailsScreen extends StatefulWidget {
  const ContractDetailsScreen({super.key});

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  // 1. Variables to hold search text
  final TextEditingController _searchController = TextEditingController();
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
        title: const Text('Manage Contracts'),
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- 2. Search Bar (Placed outside StreamBuilder for better performance) ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by CIDA No. or Name...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                // Clear button
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Color(0xFF42A5F5)),
                ),
              ),
              onChanged: (value) {
                // 3. Update state when user types
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // --- 3. The List (Wrapped in Expanded) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contracts') // Ensure collection name is correct
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No contracts found.'),
                  );
                }

                // Convert all docs to Contract objects
                final List<Contract> allContracts = snapshot.data!.docs
                    .map((doc) => Contract.fromFirestore(doc))
                    .toList();

                // --- 4. Filtering Logic ---
                final List<Contract> filteredContracts = allContracts.where((contract) {
                  final nameLower = contract.contractorName.toLowerCase();
                  final cidaLower = contract.cidaRegisterNumber.toLowerCase();
                  
                  return nameLower.contains(_searchQuery) || 
                         cidaLower.contains(_searchQuery);
                }).toList();

                if (filteredContracts.isEmpty) {
                  return Center(
                    child: Text('No results found for "$_searchQuery"'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredContracts.length,
                  itemBuilder: (context, index) {
                    final contract = filteredContracts[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 10.0),
                      child: ListTile(
                        leading: const Icon(
                          Icons.engineering,
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
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddContractScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Contract'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}