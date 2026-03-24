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
  
  // --- New Controller for Autocomplete Building Name ---
  final TextEditingController _buildingNameController = TextEditingController();
  final FocusNode _buildingNameFocusNode = FocusNode();

  String? _selectedDamageType;
  DateTime? _selectedDate;
  
  String? _userOffice; 

  bool get _isEditMode => widget.issueId != null;
  bool _isLoading = false;
  bool _isPageLoading = false;

  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryColor = Color(0xFF53BDFF);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardBg = Colors.white;

  // --- Dynamic Building Types ---
  List<String> _buildingTypes = [];
  String? _schoolDocumentId; // To store the exact school document ID

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

  @override
  void dispose() {
    _schoolNameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _buildingNameController.dispose();
    _buildingNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isPageLoading = true);
    
    await _fetchSchoolFromUserNic();
    
    if (_isEditMode) {
      await _loadIssueData();
    }
    
    // Fetch buildings directly from the school's document
    await _fetchBuildings();
    
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
          _userOffice = userData['office'];
        });
        
        // Find the school document ID from the 'schools' collection
        final String schoolName = _schoolNameController.text.trim();
        if (schoolName.isNotEmpty && schoolName != 'Not Found') {
           QuerySnapshot schoolQuery = await FirebaseFirestore.instance
              .collection('schools')
              .where('schoolName', isEqualTo: schoolName)
              .limit(1)
              .get();
              
           if (schoolQuery.docs.isNotEmpty) {
             _schoolDocumentId = schoolQuery.docs.first.id;
           }
        }
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
        _buildingNameController.text = data['buildingName'] ?? '';
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

  // --- FIREBASE BUILDING MANAGEMENT ---
  Future<void> _fetchBuildings() async {
    if (_schoolDocumentId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolDocumentId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Get the buildingNames array from the school document
        List<dynamic> buildingsArray = data['buildingNames'] ?? [];
        
        setState(() {
          _buildingTypes = List<String>.from(buildingsArray)..sort();
        });
      }
    } catch (e) {
      debugPrint("Error fetching buildings: $e");
    }
  }

  Future<void> _addBuilding(String newName) async {
    if (newName.isEmpty || _buildingTypes.contains(newName) || _schoolDocumentId == null) return;
    try {
      // Add to the buildingNames array in the schools collection
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolDocumentId)
          .update({
            'buildingNames': FieldValue.arrayUnion([newName])
          });
          
      setState(() {
        _buildingTypes.add(newName);
        _buildingTypes.sort(); 
      });
    } catch (e) {
      debugPrint("Error adding building: $e");
    }
  }

  Future<void> _removeBuilding(String nameToRemove) async {
    if (_schoolDocumentId == null) return;
    try {
      // Remove from the buildingNames array in the schools collection
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolDocumentId)
          .update({
            'buildingNames': FieldValue.arrayRemove([nameToRemove])
          });
      
      setState(() {
        _buildingTypes.remove(nameToRemove);
        // Clear text field if the user deleted the building they were currently typing
        if (_buildingNameController.text.trim() == nameToRemove) {
          _buildingNameController.clear();
        }
      });
    } catch (e) {
      debugPrint("Error removing building: $e");
    }
  }

  // --- IMAGE UPLOAD & FORM SUBMISSION ---
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() => _selectedImages.addAll(pickedFiles));
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    var uri = Uri.parse("http://98.94.30.13/index.php");
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date.')));
      return;
    }
    
    final String finalBuildingName = _buildingNameController.text.trim();
    if (finalBuildingName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Building Name.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // AUTO-SAVE: If the typed building name isn't in the list, save it to the school document!
      if (!_buildingTypes.contains(finalBuildingName) && _schoolDocumentId != null) {
        await _addBuilding(finalBuildingName);
      }

      List<String> uploadedImageUrls = await _uploadImages();
      List<String> finalUrls = [..._existingImageUrls, ...uploadedImageUrls];

      final issueData = {
        'schoolName': _schoolNameController.text.trim(),
        'buildingName': finalBuildingName, // Use the autocomplete value
        'damageType': _selectedDamageType,
        'issueTitle': '$finalBuildingName - $_selectedDamageType',
        'description': _descriptionController.text.trim(),
        'dateOfOccurance': Timestamp.fromDate(_selectedDate!),
        'imageUrls': finalUrls,
        'status': 'Pending',
        'addedByNic': widget.userNic,
        'office': _userOffice, 
        if (!_isEditMode) 'timestamp': FieldValue.serverTimestamp(),
        if (_isEditMode) 'lastUpdated': FieldValue.serverTimestamp(),
      };

      DocumentReference docRef;
      if (_isEditMode) {
        docRef = FirebaseFirestore.instance.collection('issues').doc(widget.issueId!);
        await docRef.update(issueData);
      } else {
        docRef = await FirebaseFirestore.instance.collection('issues').add(issueData);
        await _sendNotificationsToAllRoles(docRef.id, finalBuildingName);
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

  Future<void> _sendNotificationsToAllRoles(String issueDocId, String buildingName) async {
    final String schoolName = _schoolNameController.text.trim();
    final String notifTitle = 'New Building Issue Reported';
    final String notifBody = '$schoolName reported: $buildingName - $_selectedDamageType';

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': notifTitle,
      'subtitle': notifBody,
      'body': notifBody,
      'issueId': issueDocId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'new_issue',
      'isRead': false,
      'readBy': [],
      'office': _userOffice, 
      'targetRoles': [
        'Technical Officer',
        'District Engineer',
        'Provincial Engineer',
        'Chief Engineer'
      ],
      'schoolName': schoolName,
    });
  }

  // --- MANAGE BUILDINGS DIALOG ---
  void _showManageBuildingsDialog() {
    if (_schoolDocumentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: School data not found.'))
        );
        return;
    }
  
    final TextEditingController newBuildingCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Manage Buildings", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newBuildingCtrl,
                            decoration: InputDecoration(
                              labelText: 'Add New Building',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () async {
                              if (newBuildingCtrl.text.trim().isNotEmpty) {
                                await _addBuilding(newBuildingCtrl.text.trim());
                                newBuildingCtrl.clear();
                                setDialogState(() {}); 
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    if (_buildingTypes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No buildings added yet.", style: TextStyle(color: Colors.grey)),
                      ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _buildingTypes.length,
                        itemBuilder: (context, i) {
                          final bName = _buildingTypes[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(bName, style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                await _removeBuilding(bName);
                                setDialogState(() {}); 
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        ? const Center(child: CircularProgressIndicator(color: _primaryColor)) 
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
                            child1: _buildBuildingAutocomplete(constraints.maxWidth), // Updated Autocomplete
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

  // --- AUTOCOMPLETE BUILDING FIELD ---
  Widget _buildBuildingAutocomplete(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RawAutocomplete<String>(
              textEditingController: _buildingNameController,
              focusNode: _buildingNameFocusNode,
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) {
                  return _buildingTypes;
                }
                return _buildingTypes.where((b) => b.toLowerCase().contains(query));
              },
              onSelected: (String selection) {
                _buildingNameController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Building Name (Select or Type New)",
                    prefixIcon: const Icon(Icons.apartment, size: 20, color: _primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      width: screenWidth > 800 ? 300 : screenWidth - 80, 
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            title: Text(option, style: const TextStyle(fontSize: 14)),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_location_alt, color: _primaryColor),
                onPressed: _showManageBuildingsDialog,
                tooltip: "Manage Buildings",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? val, Function(String?) onChanged) {
    final safeVal = items.contains(val) ? val : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: safeVal,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: items.isEmpty ? null : onChanged, 
        decoration: InputDecoration(
          labelText: items.isEmpty ? "No options available" : label,
          prefixIcon: const Icon(Icons.warning_amber_rounded, size: 20, color: _primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: items.isEmpty ? Colors.grey.shade100 : Colors.white,
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