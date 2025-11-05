import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_school_screen.dart'; // For the "Add School" button
import 'school_details_page.dart'; // The new "hub" page we are creating

class ManageSchoolsScreen extends StatefulWidget {
  final String userNic; // User's NIC from login
  const ManageSchoolsScreen({super.key, required this.userNic});

  @override
  State<ManageSchoolsScreen> createState() => _ManageSchoolsScreenState();
}

class _ManageSchoolsScreenState extends State<ManageSchoolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // --- Style Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);
  static const Color kActiveColor = Color(0xFF4CAF50); // Green
  static const Color kInactiveColor = Color(0xFF757575); // Grey

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Function to update school status directly ---
  Future<void> _updateSchoolStatus(String schoolId, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .update({
        'isActive': isActive,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('School status updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Schools', style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      // --- Floating Action Button to Add School ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSchoolScreen(userNic: widget.userNic),
            ),
          );
        },
        label: const Text('Add School'),
        icon: const Icon(Icons.add),
        backgroundColor: kPrimaryBlue,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('schools').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No schools found.'));
                }

                // Filter schools based on search text
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final schoolName = doc['schoolName']?.toLowerCase() ?? '';
                  final schoolAddress = doc['schoolAddress']?.toLowerCase() ?? '';
                  return schoolName.contains(_searchText) ||
                      schoolAddress.contains(_searchText);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching schools found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final schoolDoc = filteredDocs[index];
                    return _buildSchoolCard(schoolDoc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by school name or address...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          filled: true,
          fillColor: kCardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // --- This is the new, cleaner school card ---
  Widget _buildSchoolCard(DocumentSnapshot schoolDoc) {
    final schoolData = schoolDoc.data() as Map<String, dynamic>;
    final String schoolId = schoolDoc.id;
    final bool isActive = schoolData['isActive'] ?? false;
    final String schoolName = schoolData['schoolName'] ?? 'Unnamed School';
    final String schoolAddress = schoolData['schoolAddress'] ?? 'No Address';

    return Card(
      elevation: 2,
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: const Icon(Icons.school, color: kPrimaryBlue, size: 40),
        title: Text(
          schoolName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        subtitle: Text(
          schoolAddress,
          style: const TextStyle(color: kSubTextColor),
        ),
        // --- Trailing section with Status and Toggle ---
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isActive ? 'Active' : 'Deactivated',
              style: TextStyle(
                color: isActive ? kActiveColor : kInactiveColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(
              height: 20, // Constrain height of the switch
              child: Switch(
                value: isActive,
                onChanged: (newStatus) {
                  _updateSchoolStatus(schoolId, newStatus);
                },
                activeColor: kActiveColor,
              ),
            ),
          ],
        ),
        // --- Tapping the card opens the details page ---
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SchoolDetailsPage(schoolId: schoolId),
            ),
          );
        },
      ),
    );
  }
}