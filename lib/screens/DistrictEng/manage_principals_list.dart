import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for current user
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Import HTTP package

class ManagePrincipalsListPage extends StatefulWidget {
  final String? officeFilter;
  
  const ManagePrincipalsListPage({super.key, this.officeFilter});

  @override
  State<ManagePrincipalsListPage> createState() =>
      _ManagePrincipalsListPageState();
}

class _ManagePrincipalsListPageState extends State<ManagePrincipalsListPage> {
  // --- Colors ---
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _textDark = Color(0xFF1F2937);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _currentUserOffice;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _getCurrentUserOffice();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Active Principals Directory',
              style: TextStyle(
                  color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
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
                  .where('office', isEqualTo: _currentUserOffice) // Filter by office
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(_currentUserOffice);
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No active principals found."),
                        if (_currentUserOffice != null && _currentUserOffice!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'District: ${_currentUserOffice!}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
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
    final String office = data['office'] ?? 'N/A';

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
                      const SizedBox(height: 4),
                      Text(
                        'District: $office',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            
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

  Widget _buildEmptyState(String? district) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No Active Principals",
              style: TextStyle(color: Colors.grey.shade500)),
          if (district != null && district.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'District: $district',
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
// PAGE: PRINCIPAL PROFILE VIEW
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
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    userData = widget.data;
  }

  void _refreshData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.docId)
        .get();
    setState(() {
      userData = doc.data() as Map<String, dynamic>;
    });
  }

  // --- UPLOAD IMAGE TO SERVER ---
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Read image as Bytes
      final bytes = await image.readAsBytes();

      // 2. Create Multipart Request
      // Ensure your server address is correct
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://98.94.30.13/index.php'), 
      );

      // 3. Add File 
      // Field name 'profile_image' triggers logic in PHP
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_image', 
          bytes,
          filename: 'upload.jpg', // PHP ignores this and generates a unique name
        ),
      );

      // 4. Send Request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Try to parse JSON
        Map<String, dynamic> jsonResponse;
        try {
             jsonResponse = jsonDecode(response.body);
        } catch (e) {
             throw Exception("Invalid JSON from server: ${response.body}");
        }

        if (jsonResponse['status'] == 'success') {
          // Get the new URL returned by PHP
          String newImageUrl = jsonResponse['profileImageUrl'];

          // 5. Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.docId)
              .update({'profile_image': newImageUrl});

          _refreshData(); 

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile Photo Updated!")),
            );
          }
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception("Server error: ${response.statusCode}.");
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
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = userData['name'] ?? 'N/A';
    final String email = userData['email'] ?? 'N/A';
    final String mobile = userData['mobilePhone'] ?? 'N/A';
    final String nic = userData['nic'] ?? 'N/A';
    final String schoolName = userData['schoolName'] ?? 'N/A';
    final String region = userData['region'] ?? 'N/A';
    final String office = userData['office'] ?? 'N/A';
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
            // Profile Image & Name
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.blue.shade100, width: 2),
                        ),
                        child: _isUploading
                            ? const CircularProgressIndicator()
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                  image:
                                      (imageUrl != null && imageUrl.isNotEmpty)
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
                      // Camera Icon
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E88E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      )
                    ],
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
                  if (office.isNotEmpty)
                    Text(
                      'District: $office',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

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

            _buildSectionHeader("SCHOOL INFORMATION"),
            const SizedBox(height: 8),
            _buildInfoContainer(
              children: [
                _buildInfoRow(Icons.badge_outlined, "NIC Number", nic),
                const Divider(height: 1),
                _buildInfoRow(Icons.school_outlined, "School Name", schoolName),
                const Divider(height: 1),
                _buildInfoRow(Icons.map_outlined, "Region/Zone", region),
                const Divider(height: 1),
                _buildInfoRow(Icons.location_city_outlined, "District", office),
              ],
            ),
            
            const SizedBox(height: 30),
            
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
        color: const Color(0xFFF8F9FA), 
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
              const SizedBox(height: 10),
              
              // NIC LOCKED
              TextField(
                  controller: nicCtrl,
                  enabled: false, // LOCKED
                  style: TextStyle(color: Colors.grey.shade600),
                  decoration: InputDecoration(
                      labelText: "NIC (Cannot Edit)",
                      filled: true,
                      fillColor: Colors.grey.shade100)),
              const SizedBox(height: 10),

              // REGION LOCKED
              TextField(
                  controller: regionCtrl,
                  enabled: false, // LOCKED
                  style: TextStyle(color: Colors.grey.shade600), 
                  decoration: InputDecoration(
                      labelText: "Region/Zone (Cannot Edit)",
                      filled: true,
                      fillColor: Colors.grey.shade100)),
              const SizedBox(height: 10),

              TextField(
                  controller: schoolCtrl,
                  decoration: const InputDecoration(labelText: "School Name")),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: "Mobile Phone"),
                  keyboardType: TextInputType.phone),
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
                  'schoolName': schoolCtrl.text.trim(),
                  'mobilePhone': phoneCtrl.text.trim(),
                  // NIC and Region are NOT updated
                });
                if (mounted) {
                  Navigator.pop(context);
                  _refreshData(); 
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