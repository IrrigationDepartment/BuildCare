
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePrincipalsListPage extends StatefulWidget {
  const ManagePrincipalsListPage({super.key});

  @override
  State<ManagePrincipalsListPage> createState() =>
      _ManagePrincipalsListPageState();
}

class _ManagePrincipalsListPageState extends State<ManagePrincipalsListPage> {
  // --- Colors ---
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textLight = Color(0xFF6B7280);

  // Search Controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
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
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Principal Directory',
          style: TextStyle(
              color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, School, or NIC...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: _bgLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Query all Principals (Active and Inactive)
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('userType', isEqualTo: 'Principal')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Client-side filtering for Search
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final school =
                      (data['schoolName'] ?? '').toString().toLowerCase();
                  final nic = (data['nic'] ?? '').toString().toLowerCase();

                  return name.contains(_searchQuery) ||
                      school.contains(_searchQuery) ||
                      nic.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No principals found matching search."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return _buildPrincipalCard(context, doc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipalCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'Unknown';
    final String schoolName = data['schoolName'] ?? 'Unassigned School';
    final String email = data['email'] ?? 'No Email';
    final String mobile = data['mobilePhone'] ?? 'N/A';
    final String? imageUrl = data['profile_image'];
    final bool isActive = data['isActive'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade50,
                    image: (imageUrl != null && imageUrl.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? const Icon(Icons.person, color: _primaryBlue)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schoolName,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 12, color: _textLight),
                      ),
                    ],
                  ),
                ),

                // Status Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? "Active" : "Inactive",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green : Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            
            // --- Action Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Edit Button
                TextButton.icon(
                  onPressed: () => _showEditDialog(context, doc, data),
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: _primaryBlue),
                  label: const Text("Edit",
                      style: TextStyle(color: _primaryBlue)),
                ),
                
                // Toggle Status Switch
                Row(
                  children: [
                    Text(isActive ? "Deactivate" : "Activate",
                        style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.red : Colors.green)),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (val) => _toggleStatus(doc.id, val),
                      ),
                    ),
                  ],
                ),

                // Delete Button
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: Colors.grey.shade400),
                  onPressed: () => _confirmDelete(context, doc.id, name),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No Principals Found",
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // --- LOGIC: Toggle Status ---
  Future<void> _toggleStatus(String docId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'isActive': currentStatus});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- LOGIC: Delete User ---
  Future<void> _confirmDelete(
      BuildContext context, String docId, String name) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Principal?"),
        content: Text(
            "Are you sure you want to delete $name? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User deleted")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: Edit Dialog ---
  void _showEditDialog(BuildContext context, QueryDocumentSnapshot doc,
      Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name']);
    final schoolCtrl = TextEditingController(text: data['schoolName']);
    final phoneCtrl = TextEditingController(text: data['mobilePhone']);
    final nicCtrl = TextEditingController(text: data['nic']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Details"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: nicCtrl,
                decoration: const InputDecoration(labelText: "NIC"),
              ),
              TextField(
                controller: schoolCtrl,
                decoration: const InputDecoration(labelText: "School Name"),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Mobile Phone"),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            onPressed: () async {
              // Update Firestore
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(doc.id)
                    .update({
                  'name': nameCtrl.text.trim(),
                  'nic': nicCtrl.text.trim(),
                  'schoolName': schoolCtrl.text.trim(),
                  'mobilePhone': phoneCtrl.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                debugPrint("Error updating: $e");
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}