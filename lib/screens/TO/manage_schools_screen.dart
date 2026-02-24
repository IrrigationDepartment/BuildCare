import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_school_screen.dart'; 
import 'school_details_page.dart';

class ManageSchoolsScreen extends StatefulWidget {
  final String userNic;
  const ManageSchoolsScreen({super.key, required this.userNic});

  @override
  State<ManageSchoolsScreen> createState() => _ManageSchoolsScreenState();
}

class _ManageSchoolsScreenState extends State<ManageSchoolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // --- NEW EYE-CATCHING COLOR PALETTE ---
  static const Color kPrimaryIndigo = Color(0xFF3F51B5);
  static const Color kAccentTeal = Color(0xFF00BFA5);
  static const Color kBackgroundColor = Color(0xFFF0F2F5);
  static const Color kCardColor = Colors.white;
  static const Color kHeaderDeep = Color(0xFF1A237E);
  static const Color kTextMain = Color(0xFF2D3436);
  static const Color kTextSub = Color(0xFF636E72);

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

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsiveness
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Determine grid columns based on width
    int crossAxisCount = 1;
    if (screenWidth > 1200) crossAxisCount = 3;
    else if (screenWidth > 700) crossAxisCount = 2;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Manage Schools', 
          style: TextStyle(color: kHeaderDeep, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: kHeaderDeep),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddSchoolScreen(userNic: widget.userNic)),
        ),
        label: const Text('Add New School', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_business_rounded),
        backgroundColor: kAccentTeal,
      ),
      body: Center(
        child: Container(
          width: 1400, // Keeps UI from stretching too far on Ultra-wide screens
          child: Column(
            children: [
              _buildSearchBar(screenWidth),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('schools').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryIndigo));
                    }
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    
                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final schoolName = doc['schoolName']?.toLowerCase() ?? '';
                      final schoolAddress = doc['schoolAddress']?.toLowerCase() ?? '';
                      return schoolName.contains(_searchText) || schoolAddress.contains(_searchText);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(child: Text('No matching schools found.'));
                    }

                    // SWITCH TO GRIDVIEW FOR RESPONSIVENESS
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 110, // Keeps cards uniform height
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) => _buildSchoolCard(filteredDocs[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 700 ? 32 : 16, 
        vertical: 20
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for school name or district...',
          hintStyle: TextStyle(color: kTextSub.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryIndigo),
          filled: true,
          fillColor: kBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolCard(DocumentSnapshot schoolDoc) {
    final schoolData = schoolDoc.data() as Map<String, dynamic>;
    final String schoolId = schoolDoc.id;
    final String schoolName = schoolData['schoolName'] ?? 'Unnamed School';
    final String schoolAddress = schoolData['schoolAddress'] ?? 'No Address';

    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryIndigo.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: kPrimaryIndigo, size: 28),
          ),
          title: Text(
            schoolName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMain, fontSize: 16),
          ),
          subtitle: Text(
            schoolAddress,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kTextSub, fontSize: 13),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: kPrimaryIndigo),
            style: IconButton.styleFrom(
              backgroundColor: kPrimaryIndigo.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SchoolDetailsPage(schoolId: schoolId)),
            ),
          ),
        ),
      ),
    );
  }
}