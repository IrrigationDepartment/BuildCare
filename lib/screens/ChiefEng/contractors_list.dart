import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTS FOR ROUTING ---
import 'add_contractor_screen.dart';
import 'view_contractor_screen.dart';

class ContractorsListPage extends StatelessWidget {
  const ContractorsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color kBackgroundColor = Color(0xFFF5F7FA);
    const Color kPrimaryBlue = Color(0xFF42A5F5);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Contractors List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBackgroundColor,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddContractorScreen()),
          );
        },
        backgroundColor: kPrimaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<QuerySnapshot>(
              // --- FIX 1: Removed .orderBy() to ensure we get ALL documents, 
              // even those without an 'updatedAt' field.
              stream: FirebaseFirestore.instance
                  .collection('contractor_details')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading data: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.engineering_outlined,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('No Contractors Found',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // --- FIX 2: Sort the documents locally in Dart ---
                // This keeps newest at the top, but pushes older docs without a date to the bottom
                var docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  
                  Timestamp? timeA = dataA['updatedAt'] as Timestamp?;
                  Timestamp? timeB = dataB['updatedAt'] as Timestamp?;
                  
                  if (timeA == null && timeB == null) return 0;
                  if (timeA == null) return 1; // Put docs without dates at the end
                  if (timeB == null) return -1;
                  
                  // Descending order (newest first)
                  return timeB.compareTo(timeA); 
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length, // Use the locally sorted list length
                  itemBuilder: (context, index) {
                    var doc = docs[index]; // Use the locally sorted document
                    var data = doc.data() as Map<String, dynamic>;
                    var docId = doc.id;

                    // --- FIX 3: Matching exact field keys from your screenshot ---
                    String contractorName = data['contractorName'] ?? 'Unknown';
                    String companyName = data['companyName'] ?? 'No Company';
                    String cidaNum = data['cidaNo'] ?? 'N/A';

                    String initial = contractorName.isNotEmpty
                        ? contractorName[0].toUpperCase()
                        : 'C';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: kPrimaryBlue.withOpacity(0.1),
                          child: Text(
                            initial,
                            style: const TextStyle(
                                color: kPrimaryBlue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          contractorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Company: $companyName\nCIDA: $cidaNum",
                            style: const TextStyle(color: Color(0xFF757575)),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewContractorScreen(
                                contractorId: docId,
                              ),
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
        ),
      ),
    );
  }
}