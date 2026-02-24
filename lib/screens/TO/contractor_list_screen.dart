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

class ContractorListScreen extends StatefulWidget {
  const ContractorListScreen({super.key});

  @override
  State<ContractorListScreen> createState() => _ContractorListScreenState();
}

class _ContractorListScreenState extends State<ContractorListScreen> {
  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kPrimaryDark = Color(0xFF312E81); // Indigo 900
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500

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
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Contractors Directory',
          style: TextStyle(
              color: kTextColor, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      
      // --- RESPONSIVE MAIN BODY ---
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // --- PREMIUM FLOATING SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: kTextColor),
                    decoration: InputDecoration(
                      hintText: 'Search Name, Company, or CIDA No...',
                      hintStyle: const TextStyle(color: kSubTextColor, fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: kCardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: kSubTextColor),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),

              // --- LIST CONTENT ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('contractor_details')
                      .orderBy('companyName')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState('No contractors found.', Icons.business_center_rounded);
                    }

                    // 1. Convert all Firestore documents to Contractor objects
                    final List<Contractor> allContractors = snapshot.data!.docs
                        .map((doc) => Contractor.fromFirestore(doc))
                        .toList();

                    // 2. --- FILTERING LOGIC ---
                    final List<Contractor> filteredContractors = allContractors.where((contractor) {
                      final nameLower = contractor.contractorName.toLowerCase();
                      final cidaLower = contractor.cidaRegistrationNumber.toLowerCase();
                      final companyLower = contractor.companyName.toLowerCase();
                      
                      return nameLower.contains(_searchQuery) || 
                             cidaLower.contains(_searchQuery) ||
                             companyLower.contains(_searchQuery);
                    }).toList();

                    // 3. Check if search result is empty
                    if (filteredContractors.isEmpty) {
                       return _buildEmptyState('No results found for "$_searchQuery"', Icons.search_off_rounded);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100), // Bottom padding for FAB
                      itemCount: filteredContractors.length,
                      itemBuilder: (context, index) {
                        final contractor = filteredContractors[index];
                        return _buildContractorCard(context, contractor);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // --- STYLED FLOATING ACTION BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddContractorScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Add Contractor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- PREMIUM CONTRACTOR LIST TILE ---
  Widget _buildContractorCard(BuildContext context, Contractor contractor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          highlightColor: kPrimaryColor.withOpacity(0.05),
          splashColor: kPrimaryColor.withOpacity(0.1),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ViewContractorScreen(
                    contractorId: contractor.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.business_center_rounded, color: kPrimaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contractor.companyName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contractor.contractorName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kSubTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.assignment_ind_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'CIDA: ${contractor.cidaRegistrationNumber}', 
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: kPrimaryColor, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- EMPTY STATE WIDGET ---
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Icon(icon, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('Directory Empty', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 8),
          Text(message, 
            style: const TextStyle(fontSize: 15, color: kSubTextColor)),
        ],
      ),
    );
  }
}