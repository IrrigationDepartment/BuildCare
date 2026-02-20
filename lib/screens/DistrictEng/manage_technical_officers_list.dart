import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for current user
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'package:http/http.dart' as http; // Import HTTP

class ManageTechnicalOfficersListPage extends StatefulWidget {
  final String? officeFilter;
  
  const ManageTechnicalOfficersListPage({
    super.key,
    required this.officeFilter,
  });

  @override
  State<ManageTechnicalOfficersListPage> createState() =>
      _ManageTechnicalOfficersListPageState();
}

class _ManageTechnicalOfficersListPageState
    extends State<ManageTechnicalOfficersListPage>
    with SingleTickerProviderStateMixin {
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _successGreen = Color(0xFF10B981);

  late TabController _tabController;
  String _searchQuery = "";
  String? _currentUserOffice;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUserOffice();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get current user's office from Firestore
  Future<void> _getCurrentUserOffice() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _currentUserOffice = widget.officeFilter;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final office = data['office'] as String?;
        
        setState(() {
          _currentUserOffice = office ?? widget.officeFilter;
        });
      } else {
        setState(() {
          _currentUserOffice = widget.officeFilter;
        });
      }
    } catch (e) {
      debugPrint('Error fetching current user office: $e');
      setState(() {
        _currentUserOffice = widget.officeFilter;
      });
    }
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
        title: Column(
          children: [
            const Text(
              'Technical Officers Directory',
              style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
            ),
            if (_currentUserOffice != null && _currentUserOffice!.isNotEmpty)
              Text(
                '(${_currentUserOffice!} District)',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
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
                _buildUserList(isActive: true),
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
          .where('office', isEqualTo: _currentUserOffice) // Filter by office
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _primaryBlue));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            isActive ? "No active officers found." : "No inactive officers.",
            _currentUserOffice,
          );
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(
            "No results found for '$_searchQuery'",
            _currentUserOffice,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            return _UserCard(
              doc: filteredDocs[index],
              isActive: isActive,
              onStatusChange: () =>
                  _toggleUserStatus(filteredDocs[index].id, !isActive),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, String? office) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
          if (office != null && office.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'District: $office',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(String docId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'isActive': newStatus});
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

  const _UserCard({
    required this.doc,
    required this.isActive,
    required this.onStatusChange,
  });

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
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
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
                ? DecorationImage(
                    image: NetworkImage(imageUrl), fit: BoxFit.cover)
                : null,
          ),
          child: (imageUrl == null || imageUrl.isEmpty)
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("$office Office",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                            MaterialPageRoute(
                                builder: (context) => EditUserPage(doc: doc)),
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
                        icon: Icon(isActive ? Icons.block : Icons.check_circle,
                            size: 18),
                        label: Text(isActive ? "Deactivate" : "Activate"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
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

// --- REDESIGNED EDIT USER PAGE ---
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
  late TextEditingController _emailCtrl;
  late TextEditingController _officeCtrl;
  late TextEditingController _officePhoneCtrl;
  
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _nameCtrl = TextEditingController(text: data['name'] ?? '');
    _mobileCtrl = TextEditingController(text: data['mobilePhone'] ?? '');
    _emailCtrl = TextEditingController(text: data['email'] ?? '');
    _officeCtrl = TextEditingController(text: data['office'] ?? '');
    _officePhoneCtrl = TextEditingController(text: data['officePhone'] ?? '');
    _currentImageUrl = data['profile_image'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _officeCtrl.dispose();
    _officePhoneCtrl.dispose();
    super.dispose();
  }

  // --- UPLOAD IMAGE TO buildcare.atigalle.x10.mx/profile/TO ---
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final bytes = await image.readAsBytes();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://buildcare.atigalle.x10.mx/index.php'), 
      );

      // **IMPORTANT**: Using 'to_profile_image' triggers Logic 4 in PHP
      request.files.add(
        http.MultipartFile.fromBytes(
          'to_profile_image', 
          bytes,
          filename: 'to_upload.jpg', 
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          String newImageUrl = jsonResponse['toProfileImageUrl'];

          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.doc.id)
              .update({'profile_image': newImageUrl});

          setState(() {
            _currentImageUrl = newImageUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile Photo Updated!")),
            );
          }
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doc.id)
          .update({
        'name': _nameCtrl.text.trim(),
        'mobilePhone': _mobileCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'office': _officeCtrl.text.trim(),
        'officePhone': _officePhoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("User Updated!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
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
        title: const Text("Technical Officer Profile",
            style: TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              
              // --- 1. PROFILE IMAGE & HEADER ---
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.shade100, width: 3),
                          ),
                          child: _isUploadingImage
                              ? const CircularProgressIndicator()
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                    image: (_currentImageUrl != null &&
                                            _currentImageUrl!.isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(_currentImageUrl!),
                                            fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: (_currentImageUrl == null ||
                                          _currentImageUrl!.isEmpty)
                                      ? Icon(Icons.person,
                                          size: 60, color: Colors.grey.shade300)
                                      : null,
                                ),
                        ),
                        // Camera Icon Badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_nameCtrl.text.isEmpty ? "Officer Name" : _nameCtrl.text,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Technical Officer",
                      style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- 2. CONTACT INFORMATION SECTION ---
              _buildSectionHeader("CONTACT INFORMATION"),
              const SizedBox(height: 10),
              _buildInfoBlock(
                icon: Icons.email_outlined,
                label: "Email",
                child: TextFormField(
                   controller: _emailCtrl,
                   style: const TextStyle(fontWeight: FontWeight.w500),
                   decoration: const InputDecoration(
                     border: InputBorder.none,
                     isDense: true,
                     contentPadding: EdgeInsets.zero,
                   ),
                ),
              ),
              const SizedBox(height: 12),
               _buildInfoBlock(
                icon: Icons.phone_android,
                label: "Mobile",
                child: TextFormField(
                   controller: _mobileCtrl,
                   style: const TextStyle(fontWeight: FontWeight.w500),
                   decoration: const InputDecoration(
                     border: InputBorder.none,
                     isDense: true,
                     contentPadding: EdgeInsets.zero,
                   ),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoBlock(
                icon: Icons.person_outline,
                label: "Full Name",
                child: TextFormField(
                   controller: _nameCtrl,
                   style: const TextStyle(fontWeight: FontWeight.w500),
                   decoration: const InputDecoration(
                     border: InputBorder.none,
                     isDense: true,
                     contentPadding: EdgeInsets.zero,
                   ),
                ),
              ),

              const SizedBox(height: 24),

              // --- 3. OFFICE INFORMATION SECTION ---
              _buildSectionHeader("OFFICE INFORMATION"),
              const SizedBox(height: 10),
               _buildInfoBlock(
                icon: Icons.location_city_outlined,
                label: "Office Location",
                child: TextFormField(
                   controller: _officeCtrl,
                   style: const TextStyle(fontWeight: FontWeight.w500),
                   decoration: const InputDecoration(
                     border: InputBorder.none,
                     isDense: true,
                     contentPadding: EdgeInsets.zero,
                   ),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoBlock(
                icon: Icons.phone_outlined,
                label: "Office Phone",
                child: TextFormField(
                   controller: _officePhoneCtrl,
                   style: const TextStyle(fontWeight: FontWeight.w500),
                   decoration: const InputDecoration(
                     border: InputBorder.none,
                     isDense: true,
                     contentPadding: EdgeInsets.zero,
                   ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // --- 4. SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Changes",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for the Section Headers (uppercase grey text)
  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 0.5
      )),
    );
  }

  // Helper for the Rounded Data Blocks
  Widget _buildInfoBlock({required IconData icon, required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), // Very light grey background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                child, // This is the editable TextFormField
              ],
            ),
          )
        ],
      ),
    );
  }
}