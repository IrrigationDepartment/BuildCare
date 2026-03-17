import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- IMPORTS (Ensure these files exist in your project) ---
import 'add_contractor_screen.dart';
import 'view_contractor_screen.dart';

// --- DATA MODEL ---
class Contractor {
  final String id;
  final String companyName;
  final String contractorName;
  final String cidaNo; // Matches "cidaNo" in Firestore
  final String contact;
  final String nic;
  final DateTime? updatedAt;

  Contractor({
    required this.id,
    required this.companyName,
    required this.contractorName,
    required this.cidaNo,
    required this.contact,
    required this.nic,
    this.updatedAt,
  });

  factory Contractor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle the Timestamp from Firestore safely
    DateTime? updatedDate;
    if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
      updatedDate = (data['updatedAt'] as Timestamp).toDate();
    }

    return Contractor(
      id: doc.id,
      companyName: data['companyName'] ?? 'N/A',
      contractorName: data['contractorName'] ?? 'Unknown',
      cidaNo: data['cidaNo'] ?? 'N/A',
      contact: data['contact'] ?? 'N/A',
      nic: data['nic'] ?? 'N/A',
      updatedAt: updatedDate,
    );
  }
}

class ContractorListScreen extends StatefulWidget {
  const ContractorListScreen({super.key});

  @override
  State<ContractorListScreen> createState() => _ContractorListScreenState();
}

class _ContractorListScreenState extends State<ContractorListScreen> {
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Contractors', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Name, Company or CIDA No...',
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
          ),

          // --- CONTRACTOR LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // CORRECTED: Collection name and ordering field
              stream: FirebaseFirestore.instance
                  .collection('contractor_details') 
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No contractors found in database.'));
                }

                // Map docs to our model
                final List<Contractor> allContractors = snapshot.data!.docs
                    .map((doc) => Contractor.fromFirestore(doc))
                    .toList();

                // Client-side filtering
                final List<Contractor> filtered = allContractors.where((c) {
                  return c.contractorName.toLowerCase().contains(_searchQuery) ||
                         c.companyName.toLowerCase().contains(_searchQuery) ||
                         c.cidaNo.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text('No results for "$_searchQuery"'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final contractor = filtered[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade50,
                          child: const Icon(Icons.business, color: Colors.indigo),
                        ),
                        title: Text(
                          contractor.companyName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Contractor: ${contractor.contractorName}'),
                            Text('CIDA No: ${contractor.cidaNo}', 
                                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewContractorScreen(contractorId: contractor.id),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddContractorScreen()),
          );
        },
        label: const Text('Add Contractor'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}