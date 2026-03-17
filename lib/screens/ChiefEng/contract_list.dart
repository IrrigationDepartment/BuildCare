import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import 'add_contract.dart';
import 'view_details.dart'; 

class ContractListPage extends StatefulWidget {
  const ContractListPage({super.key});

  @override
  State<ContractListPage> createState() => _ContractListPageState();
}

class _ContractListPageState extends State<ContractListPage> {
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(dynamic value) {
    if (value is num) {
      return NumberFormat.currency(locale: 'en_US', symbol: 'LKR ').format(value);
    }
    return 'LKR 0.00';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'TBD';
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
    return 'TBD';
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contract?'),
        content: const Text('Are you sure you want to delete this contract? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('contracts').doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contract deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting contract: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Active Contracts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddContractScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Contract', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by CIDA No. or Name...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: kPrimaryBlue),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('contracts')
                        .orderBy('updatedAt', descending: true) // FIXED: Changed 'timestamp' to 'updatedAt'
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('No Contracts Found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      final allDocs = snapshot.data!.docs;
                      final filteredDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nameLower = (data['contractorName'] ?? '').toString().toLowerCase();
                        final cidaLower = (data['cidaNo'] ?? '').toString().toLowerCase(); // FIXED: Changed key
                        
                        return nameLower.contains(_searchQuery) || cidaLower.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Text(
                            'No results found for "$_searchQuery"',
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var doc = filteredDocs[index];
                          var data = doc.data() as Map<String, dynamic>;
                          var docId = doc.id;

                          // FIXED: Updated all keys to match your screenshot
                          String contractorName = data['contractorName'] ?? 'Unknown Contractor';
                          String contractType = data['projectType'] ?? 'Unspecified'; // Was 'typeOfContract'
                          String value = _formatCurrency(data['value']); // Was 'contractValue'
                          String endDate = _formatDate(data['endDate']);
                          String cida = data['cidaNo'] ?? 'N/A'; // Was 'cidaRegisterNumber'

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Dismissible(
                              key: Key(docId),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                await _confirmDelete(context, docId);
                                return false; 
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewContractDetailsScreen(contractId: docId),
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
                                          Text(
                                            'CIDA: $cida',
                                            style: TextStyle(
                                                color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              contractType.toUpperCase(),
                                              style: TextStyle(
                                                  color: Colors.indigo.shade700,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        contractorName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Ends: $endDate",
                                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            value,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.teal),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}