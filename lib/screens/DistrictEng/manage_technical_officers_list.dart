import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// --- THEME CONSTANTS ---
const Color _primaryColor = Color(0xFF1E3A8A); // Deep Indigo
const Color _secondaryColor = Color(0xFF0D9488); // Teal
const Color _bgLight = Color(0xFFF4F7FC);
const Color _textDark = Color(0xFF111827);
const Color _dangerRed = Color(0xFFE11D48); // Rose Red
const Color _successGreen = Color(0xFF10B981); // Emerald

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

  Future<void> _getCurrentUserOffice() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _currentUserOffice = widget.officeFilter);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() => _currentUserOffice = data['office'] as String? ?? widget.officeFilter);
      } else {
        setState(() => _currentUserOffice = widget.officeFilter);
      }
    } catch (e) {
      debugPrint('Error fetching current user office: $e');
      setState(() => _currentUserOffice = widget.officeFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Technical Officers',
              style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_currentUserOffice != null && _currentUserOffice!.isNotEmpty)
              Text(
                '${_currentUserOffice!} District',
                style: TextStyle(color: _secondaryColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: _primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Active Officers"),
            Tab(text: "Inactive / Pending"),
          ],
        ),
      ),
      body: Center(
        // ConstrainedBox ensures the UI doesn't stretch too wide on web/desktop
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search by name...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, color: _primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    // Shadow effect via wrapping or decoration
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
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
        ),
      ),
    );
  }

  Widget _buildUserList({required bool isActive}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'Technical Officer')
          .where('isActive', isEqualTo: isActive)
          .where('office', isEqualTo: _currentUserOffice)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: _dangerRed)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(isActive ? "No active officers found." : "No inactive officers.", _currentUserOffice);
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState("No results found for '$_searchQuery'", _currentUserOffice);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  Widget _buildEmptyState(String message, String? office) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
          if (office != null && office.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('District: $office', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(String docId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({'isActive': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? "User Activated Successfully" : "User Deactivated"),
            backgroundColor: newStatus ? _successGreen : _dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Removes ExpansionTile lines
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_primaryColor, _secondaryColor]),
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                image: (imageUrl != null && imageUrl.isNotEmpty)
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? const Icon(Icons.person_rounded, color: _primaryColor, size: 28)
                  : null,
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text("$office District", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          children: [
            const Divider(height: 24, color: Color(0xFFF3F4F6)),
            _infoRow(Icons.email_rounded, email),
            const SizedBox(height: 12),
            _infoRow(Icons.phone_android_rounded, mobile),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditUserPage(doc: doc))),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text("Edit Details", style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: const BorderSide(color: _primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStatusChange,
                    icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 18),
                    label: Text(isActive ? "Deactivate" : "Activate", style: const TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? _dangerRed : _successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500))),
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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final bytes = await image.readAsBytes();
      var request = http.MultipartRequest('POST', Uri.parse('http://98.94.30.13/index.php'));
      request.files.add(http.MultipartFile.fromBytes('to_profile_image', bytes, filename: 'to_upload.jpg'));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          String newImageUrl = jsonResponse['toProfileImageUrl'];
          await FirebaseFirestore.instance.collection('users').doc(widget.doc.id).update({'profile_image': newImageUrl});

          setState(() => _currentImageUrl = newImageUrl);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Photo Updated!"), backgroundColor: _successGreen));
          }
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: _dangerRed));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.doc.id).update({
        'name': _nameCtrl.text.trim(),
        'mobilePhone': _mobileCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'office': _officeCtrl.text.trim(),
        'officePhone': _officePhoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Updated Successfully!"), backgroundColor: _successGreen, behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: _dangerRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Perfect constraints for tablets/web
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Image
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [_primaryColor, _secondaryColor]),
                              ),
                              child: Container(
                                width: 110, height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  image: (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                      ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _isUploadingImage
                                    ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                                    : (_currentImageUrl == null || _currentImageUrl!.isEmpty)
                                        ? const Icon(Icons.person_rounded, size: 60, color: _primaryColor)
                                        : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: InkWell(
                                onTap: _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _secondaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_nameCtrl.text.isEmpty ? "Officer Name" : _nameCtrl.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text("Technical Officer", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Contact Info Section
                  _buildSectionHeader("PERSONAL INFORMATION"),
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)]),
                    child: Column(
                      children: [
                        _buildInputField(icon: Icons.person_outline_rounded, label: "Full Name", controller: _nameCtrl),
                        const Divider(height: 30, color: Color(0xFFF3F4F6)),
                        _buildInputField(icon: Icons.email_outlined, label: "Email Address", controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                        const Divider(height: 30, color: Color(0xFFF3F4F6)),
                        _buildInputField(icon: Icons.phone_android_rounded, label: "Mobile Number", controller: _mobileCtrl, keyboardType: TextInputType.phone),
                      ],
                    ),
                  ),

                  // Office Info Section
                  _buildSectionHeader("OFFICE INFORMATION"),
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)]),
                    child: Column(
                      children: [
                        _buildInputField(icon: Icons.business_rounded, label: "Assigned Office / District", controller: _officeCtrl),
                        const Divider(height: 30, color: Color(0xFFF3F4F6)),
                        _buildInputField(icon: Icons.phone_rounded, label: "Office Phone", controller: _officePhoneCtrl, keyboardType: TextInputType.phone),
                      ],
                    ),
                  ),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
    );
  }

  Widget _buildInputField({required IconData icon, required String label, required TextEditingController controller, TextInputType? keyboardType}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _primaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark, fontSize: 15),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.normal),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}