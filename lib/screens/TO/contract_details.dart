import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_contract.dart';
import 'view_details.dart';

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

class ContractDetailsScreen extends StatefulWidget {
  const ContractDetailsScreen({super.key});

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // --- STYLE CONSTANTS ---
  static const Color kPrimaryIndigo = Color(0xFF1E293B); // Deep Slate
  static const Color kAccentAzure = Color(0xFF0284C7);   // Professional Blue
  static const Color kBgSlate = Color(0xFFF1F5F9);      // Light Grey/Blue
  static const Color kCardColor = Colors.white;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    // --- RESPONSIVE BREAKPOINTS ---
    int crossAxisCount = 1;
    double aspectRatio = 4.0; // Wide for mobile list

    if (width > 1100) {
      crossAxisCount = 3;
      aspectRatio = 2.5;
    } else if (width > 650) {
      crossAxisCount = 2;
      aspectRatio = 2.8;
    }

    return Scaffold(
      backgroundColor: kBgSlate,
      appBar: AppBar(
        title: const Text('Contract Database', 
          style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryIndigo)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildSearchBar(width),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('contracts').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kAccentAzure));
                    }
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No contracts found.'));
                    }

                    final List<Contract> filteredContracts = snapshot.data!.docs
                        .map((doc) => Contract.fromFirestore(doc))
                        .where((c) => 
                            c.contractorName.toLowerCase().contains(_searchQuery) || 
                            c.cidaRegisterNumber.toLowerCase().contains(_searchQuery))
                        .toList();

                    if (filteredContracts.isEmpty) {
                      return Center(child: Text('No results found for "$_searchQuery"'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredContracts.length,
                      itemBuilder: (context, index) => _buildContractCard(filteredContracts[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddContractScreen())),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Contract'),
        backgroundColor: kAccentAzure,
      ),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Contractor Name or CIDA Number...',
          prefixIcon: const Icon(Icons.search_rounded, color: kAccentAzure),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(icon: const Icon(Icons.cancel), onPressed: () { 
                  _searchController.clear();
                  setState(() => _searchQuery = "");
                }) 
              : null,
          filled: true,
          fillColor: kBgSlate,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildContractCard(Contract contract) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: kPrimaryIndigo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ViewContractDetailsScreen(contractId: contract.id))),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kAccentAzure.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.engineering_rounded, color: kAccentAzure, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contract.contractorName, 
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kPrimaryIndigo)),
                      const SizedBox(height: 4),
                      Text('CIDA: ${contract.cidaRegisterNumber}', 
                        style: TextStyle(color: kPrimaryIndigo.withOpacity(0.6), fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}