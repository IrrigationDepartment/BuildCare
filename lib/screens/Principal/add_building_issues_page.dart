import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AddBuildingIssuesPage extends StatefulWidget {
  final String userNic;
  final String? issueId;

  const AddBuildingIssuesPage({
    super.key,
    required this.userNic,
    this.issueId,
  });

  @override
  State<AddBuildingIssuesPage> createState() => _AddBuildingIssuesPageState();
}

class _AddBuildingIssuesPageState extends State<AddBuildingIssuesPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedBuilding;
  String? _selectedDamageType;
  DateTime? _selectedDate;
  
  // Firebase users collection එකේ 'office' field එක තමයි location store කරන්නේ
  String? _userOffice; // උදා: "Galle"

  bool get _isEditMode => widget.issueId != null;
  bool _isLoading = false;
  bool _isPageLoading = false;

  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardBg = Colors.white;

  final List<String> _buildingTypes = [
    'Academic Classroom', 'Office', 'Science Lab', 'Technology Lab', 'Library',
    'Hostel', 'Computer Lab', 'Dahampasala Lab', 'Store Room', 'Auditorium',
    'Main Hall', 'Changing Room', 'Security Room', 'Wash Room', 'Boundary Wall'
  ];

  final List<String> _damageTypes = [
    'Foundation & Wall Damage', 'Roofing Damage', 'Utility Damage (Electricity/Water)',
    'Floor Damage', 'Plumbing/Draining Structural Issue', 'Windows/Doors Frame Damage',
    'Staircase & Corridor Damage'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isPageLoading = true);
    if (_isEditMode) {
      await _loadIssueData();
    } else {
      await _fetchSchoolFromUserNic();
    }
    if (mounted) setState(() => _isPageLoading = false);
  }

  Future<void> _fetchSchoolFromUserNic() async {
    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: widget.userNic)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        var userData = userQuery.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _schoolNameController.text = userData['schoolName'] ?? 'Not Found';
          // Firebase users collection එකේ province/district නැහැ — 'office' field එකයි තියෙන්නේ
          _userOffice = userData['office'];
        });
        debugPrint("Principal office: $_userOffice");
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  Future<void> _loadIssueData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('issues').doc(widget.issueId!).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _schoolNameController.text = data['schoolName'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _selectedBuilding = data['buildingName'];
        _selectedDamageType = data['damageType'];
        _userOffice = data['office'];
        if (data['dateOfOccurance'] != null) {
          _selectedDate = (data['dateOfOccurance'] as Timestamp).toDate();
          _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        }
        _existingImageUrls = List<String>.from(data['imageUrls'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading issue: $e');
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() => _selectedImages.addAll(pickedFiles));
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    var uri = Uri.parse("https://buildcare.atigalle.x10.mx/index.php");
    var request = http.MultipartRequest("POST", uri);

    for (var imageFile in _selectedImages) {
      var fileBytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('images[]', fileBytes, filename: imageFile.name));
    }
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);
        return decodedResponse['status'] == 'success' ? List<String>.from(decodedResponse['imageUrls']) : [];
      }
      return [];
    } catch (e) {
      debugPrint("Upload Error: $e");
      return [];
    }
  }

  // Issue submit කරන main method
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Images upload කරගන්නවා
      List<String> uploadedImageUrls = await _uploadImages();
      List<String> finalUrls = [..._existingImageUrls, ...uploadedImageUrls];

      // 2. Issue data Map එකට දාගන්නවා
      // Firebase users collection එකේ 'office' field තමයි location — province/district නැහැ
      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': _selectedBuilding,
        'damageType': _selectedDamageType,
        'issueTitle': '$_selectedBuilding - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': finalUrls,
        'status': 'Pending',
        'addedByNic': widget.userNic,
        'office': _userOffice, // province/district වෙනුවට office
        if (!_isEditMode) 'timestamp': FieldValue.serverTimestamp(),
        if (_isEditMode) 'lastUpdated': FieldValue.serverTimestamp(),
      };

      // 3. Firestore issues collection එකට save කරනවා
      DocumentReference docRef;
      if (_isEditMode) {
        docRef = FirebaseFirestore.instance.collection('issues').doc(widget.issueId!);
        await docRef.update(issueData);
      } else {
        docRef = await FirebaseFirestore.instance.collection('issues').add(issueData);

        // 4. Notifications යවනවා - userTypes 4කටම
        await _sendNotificationsToAllRoles(docRef.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue submitted successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Firebase Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Notifications යවන method
  // Firebase users collection query කරලා userType සහ office match වෙන අයට notify කරනවා
  Future<void> _sendNotificationsToAllRoles(String issueDocId) async {
    final String schoolName = _schoolNameController.text.trim();
    final String notifTitle = 'New Building Issue Reported';
    final String notifBody = '$schoolName reported: $_selectedBuilding - $_selectedDamageType';
    final db = FirebaseFirestore.instance;

    // Firebase screenshot වලින් field names confirm කළා:
    // role field = 'userType'
    // location field = 'office'
    // userType values: "Technical Officer", "District Engineer", "Provincial Engineer", "Chief Engineer"

    final List<String> targetUserTypes = [
      'Technical Officer',
      'District Engineer',
      'Provincial Engineer',
      'Chief Engineer',
    ];

    final WriteBatch batch = db.batch();

    for (final userType in targetUserTypes) {
      try {
        Query query = db.collection('users').where('userType', isEqualTo: userType);

        // Technical Officer සහ District Engineer — same office (district) filter
        // Provincial Engineer සහ Chief Engineer — office filter නැහැ (ඔක්කොම)
        if ((userType == 'Technical Officer' || userType == 'District Engineer') && _userOffice != null) {
          query = query.where('office', isEqualTo: _userOffice);
        }

        final QuerySnapshot usersSnapshot = await query.get();
        debugPrint('Found ${usersSnapshot.docs.length} users for userType: $userType');

        if (usersSnapshot.docs.isNotEmpty) {
          for (final userDoc in usersSnapshot.docs) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final String? recipientNic = userData['nic'] as String?;

            final notifRef = db.collection('notifications').doc();
            batch.set(notifRef, {
              'title': notifTitle,
              'subtitle': notifBody, // chief_notification.dart uses 'subtitle'
              'body': notifBody,
              'issueId': issueDocId,
              'timestamp': FieldValue.serverTimestamp(), // ALL notification pages query 'timestamp'
              'type': 'new_issue',
              'isRead': false,
              'readBy': [],
              'office': _userOffice,
              'targetUserType': userType,
              'recipientNic': recipientNic,
              'schoolName': schoolName,
            });
          }
        } else {
          debugPrint('No users found for $userType — adding generic notification');
          final notifRef = db.collection('notifications').doc();
          batch.set(notifRef, {
            'title': notifTitle,
            'subtitle': notifBody,
            'body': notifBody,
            'issueId': issueDocId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'new_issue',
            'isRead': false,
            'readBy': [],
            'office': _userOffice,
            'targetUserType': userType,
            'recipientNic': null,
            'schoolName': schoolName,
          });
        }
      } catch (e) {
        debugPrint('Error for userType $userType: $e');
      }
    }

    await batch.commit();
    debugPrint('✅ All notifications committed to Firestore!');
  }

  @override
  Widget build(BuildContext context) {
    // Interface එකේ කිසිම වෙනසක් කරලා නැහැ
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(_isEditMode ? "Update Issue" : "Report Building Issue", 
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isPageLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? constraints.maxWidth * 0.1 : 16,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildFormCard(
                        title: "General Information",
                        children: [
                          _buildResponsiveRow(
                            isWide: isWide,
                            child1: _buildTextField("School Name", _schoolNameController, readOnly: true, icon: Icons.school),
                            child2: _buildDateField("Occurance Date", _dateController, () => _selectDate(context)),
                          ),
                          _buildResponsiveRow(
                            isWide: isWide,
                            child1: _buildDropdown("Building Name", _buildingTypes, _selectedBuilding, (v) => setState(() => _selectedBuilding = v)),
                            child2: _buildDropdown("Damage Category", _damageTypes, _selectedDamageType, (v) => setState(() => _selectedDamageType = v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFormCard(
                        title: "Issue Details & Evidence",
                        children: [
                          _buildTextField("Detailed Description", _descriptionController, maxLines: 4, icon: Icons.description),
                          const SizedBox(height: 16),
                          _buildImageSection(constraints.maxWidth),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSubmitButton(isWide),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // --- පහළ තියෙන ඔක්කොම UI Helper methods උඹේ කලින් code එකේ තිබ්බ ඒවාමයි ---

  Widget _buildFormCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor)),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResponsiveRow({required bool isWide, required Widget child1, required Widget child2}) {
    if (!isWide) return Column(children: [child1, child2]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child1),
        const SizedBox(width: 20),
        Expanded(child: child2),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: _primaryColor),
          filled: true,
          fillColor: readOnly ? Colors.grey[50] : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? val, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: val,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.apartment, size: 20, color: _primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildImageSection(double width) {
    int crossAxisCount = width > 1000 ? 6 : (width > 600 ? 4 : 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Evidence Photos", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        if (_existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: _existingImageUrls.length + _selectedImages.length,
            itemBuilder: (context, index) {
              if (index < _existingImageUrls.length) {
                return _buildPreviewItem(Image.network(_existingImageUrls[index], fit: BoxFit.cover), () => setState(() => _existingImageUrls.removeAt(index)));
              }
              int newIdx = index - _existingImageUrls.length;
              return _buildPreviewItem(
                FutureBuilder<Uint8List>(
                  future: _selectedImages[newIdx].readAsBytes(),
                  builder: (context, snap) => snap.hasData ? Image.memory(snap.data!, fit: BoxFit.cover) : const Center(child: CircularProgressIndicator()),
                ),
                () => setState(() => _selectedImages.removeAt(newIdx)),
              );
            },
          ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor.withOpacity(0.2), style: BorderStyle.solid),
            ),
            child: const Column(
              children: [
                Icon(Icons.add_a_photo, color: _primaryColor, size: 32),
                SizedBox(height: 8),
                Text("Add Damage Photos", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewItem(Widget child, VoidCallback onRemove) {
    return Stack(
      children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child)),
        Positioned(top: 4, right: 4, child: GestureDetector(onTap: onRemove, child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)))),
      ],
    );
  }

  Widget _buildSubmitButton(bool isWide) {
    return SizedBox(
      width: isWide ? 300 : double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : Text(_isEditMode ? "UPDATE REPORT" : "SUBMIT REPORT", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, 
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020), 
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildDateField(String label, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20, color: _primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }
}