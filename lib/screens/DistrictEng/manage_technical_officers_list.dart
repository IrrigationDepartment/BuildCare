import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTechnicalOfficersListPage extends StatefulWidget {
  const ManageTechnicalOfficersListPage({super.key});

  @override
  State<ManageTechnicalOfficersListPage> createState() => _ManageTechnicalOfficersListPageState();
}

class _ManageTechnicalOfficersListPageState extends State<ManageTechnicalOfficersListPage> with SingleTickerProviderStateMixin {
  // --- Modern Professional Color Palette ---
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _successGreen = Color(0xFF10B981);

  late TabController _tabController;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Technical Officers Directory',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryBlue,
          tabs: const [
            Tab(text: "Active Officers"),
            Tab(text: "Inactive / Pending"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by name...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Tab View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Active Users
                _buildUserList(isActive: true),
                // Tab 2: Inactive Users
                _buildUserList(isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList({required bool isActive}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'Technical Officer')
          .where('isActive', isEqualTo: isActive)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primaryBlue));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(isActive ? "No active officers found." : "No inactive officers.");
        }

        // Filter locally for search query
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState("No results found for '$_searchQuery'");
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            return _UserCard(
              doc: filteredDocs[index], 
              isActive: isActive,
              onStatusChange: () => _toggleUserStatus(filteredDocs[index].id, !isActive),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(String docId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isActive': newStatus
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? "User Activated" : "User Deactivated"),
            backgroundColor: newStatus ? _successGreen : _dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }
}

class _UserCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isActive;
  final VoidCallback onStatusChange;

  const _UserCard({required this.doc, required this.isActive, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'No Email';
    final mobile = data['mobilePhone'] ?? 'N/A';
    final office = data['office'] ?? 'N/A';
    final imageUrl = data['profile_image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
            image: (imageUrl != null && imageUrl.isNotEmpty)
                ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                : null,
          ),
          child: (imageUrl == null || imageUrl.isEmpty)
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("$office Office", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _infoRow(Icons.email_outlined, email),
                const SizedBox(height: 8),
                _infoRow(Icons.phone_android, mobile),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditUserPage(doc: doc)),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Edit Details"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Deactivate/Activate Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onStatusChange,
                        icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                        label: Text(isActive ? "Deactivate" : "Activate"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}

// --- EDIT USER DETAILS PAGE ---
class EditUserPage extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const EditUserPage({super.key, required this.doc});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _officeCtrl;
  late TextEditingController _officePhoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _nameCtrl = TextEditingController(text: data['name']);
    _mobileCtrl = TextEditingController(text: data['mobilePhone']);
    _officeCtrl = TextEditingController(text: data['office']);
    _officePhoneCtrl = TextEditingController(text: data['officePhone']);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _officeCtrl.dispose();
    _officePhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.doc.id).update({
        'name': _nameCtrl.text.trim(),
        'mobilePhone': _mobileCtrl.text.trim(),
        'office': _officeCtrl.text.trim(),
        'officePhone': _officePhoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Updated!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Technical Officer", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Full Name", _nameCtrl, Icons.person),
              const SizedBox(height: 16),
              _buildTextField("Mobile Phone", _mobileCtrl, Icons.phone_android),
              const SizedBox(height: 16),
              _buildTextField("Office Location", _officeCtrl, Icons.location_city),
              const SizedBox(height: 16),
              _buildTextField("Office Phone", _officePhoneCtrl, Icons.phone),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Changes", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
      validator: (value) => value == null || value.isEmpty ? "Field required" : null,
    );
  }
}