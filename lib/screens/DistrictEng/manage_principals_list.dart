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
          'Active Principals Directory',
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
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('userType', isEqualTo: 'Principal')
                  .where('isActive', isEqualTo: true)
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
                  return const Center(
                      child: Text("No active principals found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _buildPrincipalCard(context, docs[index]);
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
    final String? imageUrl = data['profile_image'];
    final bool isActive = data['isActive'] ?? true;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textDark)),
                      Text(schoolName,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            
            // --- Action Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // View Profile Button
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrincipalProfileView(
                          docId: doc.id,
                          data: data,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined,
                      size: 18, color: _primaryBlue),
                  label: const Text("View Profile",
                      style: TextStyle(color: _primaryBlue)),
                ),

                // Deactivate Switch
                Row(
                  children: [
                    const Text("Deactivate",
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (val) => _confirmStatusChange(doc.id, val),
                      ),
                    ),
                  ],
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
          Text("No Active Principals",
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Future<void> _confirmStatusChange(String docId, bool newStatus) async {
    final action = newStatus ? "Activate" : "Deactivate";
    final color = newStatus ? Colors.green : Colors.red;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$action Principal?"),
        content: Text("Are you sure you want to $action this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .update({'isActive': newStatus});
            },
            child: Text("Yes, $action"),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// NEW PAGE: PRINCIPAL PROFILE VIEW
// ---------------------------------------------------------
class PrincipalProfileView extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const PrincipalProfileView(
      {super.key, required this.docId, required this.data});

  @override
  State<PrincipalProfileView> createState() => _PrincipalProfileViewState();
}

class _PrincipalProfileViewState extends State<PrincipalProfileView> {
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    userData = widget.data;
  }

  // Refresh data after edit
  void _refreshData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.docId)
        .get();
    setState(() {
      userData = doc.data() as Map<String, dynamic>;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String name = userData['name'] ?? 'N/A';
    final String email = userData['email'] ?? 'N/A';
    final String mobile = userData['mobilePhone'] ?? 'N/A';
    final String nic = userData['nic'] ?? 'N/A';
    final String schoolName = userData['schoolName'] ?? 'N/A';
    final String region = userData['region'] ?? 'N/A';
    final String? imageUrl = userData['profile_image'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Principal Profile",
            style: TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
            onPressed: () => _showEditDialog(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Profile Image & Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100, width: 2),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                        image: (imageUrl != null && imageUrl.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? Icon(Icons.person,
                              size: 60, color: Colors.grey.shade300)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  const Text("Principal",
                      style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E88E5),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 2. Contact Info Section
            _buildSectionHeader("CONTACT INFORMATION"),
            const SizedBox(height: 8),
            _buildInfoContainer(
              children: [
                _buildInfoRow(Icons.email_outlined, "Email", email),
                const Divider(height: 1),
                _buildInfoRow(Icons.phone_android, "Mobile", mobile),
              ],
            ),

            const SizedBox(height: 24),

            // 3. School Info Section
            _buildSectionHeader("SCHOOL INFORMATION"),
            const SizedBox(height: 8),
            _buildInfoContainer(
              children: [
                _buildInfoRow(Icons.badge_outlined, "NIC Number", nic),
                const Divider(height: 1),
                _buildInfoRow(Icons.school_outlined, "School Name", schoolName),
                const Divider(height: 1),
                _buildInfoRow(Icons.map_outlined, "Region/Zone", region),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Bottom Activate/Deactivate Button (Optional, for quick access)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF1E88E5),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => _showEditDialog(context),
                child: const Text("Edit Profile Details", style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), // Very light grey like the screenshot
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- EDIT DIALOG ---
  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: userData['name']);
    final schoolCtrl = TextEditingController(text: userData['schoolName']);
    final phoneCtrl = TextEditingController(text: userData['mobilePhone']);
    final nicCtrl = TextEditingController(text: userData['nic']);
    // region is not always editable but we can add it if needed
    final regionCtrl = TextEditingController(text: userData['region']);

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
                  decoration: const InputDecoration(labelText: "Full Name")),
              TextField(
                  controller: nicCtrl,
                  decoration: const InputDecoration(labelText: "NIC")),
              TextField(
                  controller: schoolCtrl,
                  decoration: const InputDecoration(labelText: "School Name")),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: "Mobile Phone"),
                  keyboardType: TextInputType.phone),
              TextField(
                  controller: regionCtrl,
                  decoration: const InputDecoration(labelText: "Region/Zone")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5)),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.docId)
                    .update({
                  'name': nameCtrl.text.trim(),
                  'nic': nicCtrl.text.trim(),
                  'schoolName': schoolCtrl.text.trim(),
                  'mobilePhone': phoneCtrl.text.trim(),
                  'region': regionCtrl.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  _refreshData(); // Refresh the profile view
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile Updated")));
                }
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