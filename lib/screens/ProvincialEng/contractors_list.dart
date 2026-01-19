import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_contractor_screen.dart'; // Import to enable viewing details

class ContractorsListPage extends StatelessWidget {
  const ContractorsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Contractors'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add new contractor
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContractorScreen(),
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // CHANGED: Corrected collection name to 'contractor_details' to match AddContractorScreen
        stream: FirebaseFirestore.instance
            .collection('contractor_details')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      (data['contractorName'] ?? 'C')[0].toUpperCase(),
                      style: TextStyle(color: Colors.teal.shade800),
                    ),
                  ),
                  // Displaying Contractor Name
                  title: Text(data['contractorName'] ?? 'Unknown Contractor',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  // Displaying Company Name as subtitle
                  subtitle: Text(data['companyName'] ?? 'No Company Name'),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                  onTap: () {
                    // Navigate to AddContractorScreen in View/Edit mode
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddContractorScreen(
                          contractorId: doc.id,
                          initialData: data,
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
    );
  }
}