import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddContractorScreen extends StatefulWidget {
  final String? contractorId;
  final Map<String, dynamic>? initialData;

  const AddContractorScreen({
    super.key,
    this.contractorId,
    this.initialData,
  });

  @override
  State<AddContractorScreen> createState() => _AddContractorScreenState();
}

class _AddContractorScreenState extends State<AddContractorScreen> {
  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kPrimaryDark = Color(0xFF312E81); // Indigo 900
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Form Controllers & State ---
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cidaController = TextEditingController();
  final TextEditingController _contractorNameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isEditMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contractorId != null && widget.initialData != null) {
      _isEditMode = true;
      _populateForm(widget.initialData!);
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    _companyNameController.text = data['companyName'] ?? '';
    _cidaController.text = data['cidaNo'] ?? '';
    _contractorNameController.text = data['contractorName'] ?? '';
    _nicController.text = data['nic'] ?? '';
    _contactController.text = data['contact'] ?? '';
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _cidaController.dispose();
    _contractorNameController.dispose();
    _nicController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // --- Save / Update Function with Notification ---
  Future<void> _saveContractor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String nicValue = _nicController.text.trim();
      
      final contractorData = {
        'companyName': _companyNameController.text.trim(),
        'cidaNo': _cidaController.text.trim(),
        'contractorName': _contractorNameController.text.trim(),
        'nic': nicValue,
        'contact': _contactController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        // Update existing record
        await FirebaseFirestore.instance
            .collection('contractor_details')
            .doc(widget.contractorId) // In edit mode, we use the passed ID
            .update(contractorData);
      } else {
        // --- NEW LOGIC: Use NIC as the Document ID (Primary Key) ---
        
        // 1. First check if a contractor with this NIC already exists
        final docSnapshot = await FirebaseFirestore.instance
            .collection('contractor_details')
            .doc(nicValue)
            .get();
            
        if (docSnapshot.exists) {
           throw Exception('A contractor with this NIC already exists.');
        }

        // 2. Save new contractor using NIC as the Document ID
        await FirebaseFirestore.instance
            .collection('contractor_details')
            .doc(nicValue)
            .set(contractorData);

        // 3. TRIGGER NOTIFICATION for the new contractor
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New Contractor Registered',
          'subtitle': '${_companyNameController.text.trim()} (${_contractorNameController.text.trim()})',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'contractor',
          'contractorId': nicValue, // Linking the new Document ID (which is the NIC)
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Contractor updated successfully!' : 'Contractor registered successfully!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')), // Clean up exception text
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Contractor' : 'Register Contractor',
          style: const TextStyle(fontWeight: FontWeight.w800, color: kTextColor, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          // RESPONSIVE WRAPPER: Centers the content on large screens
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Company Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Company Name',
                      hintText: 'Enter Registered Company Name',
                      controller: _companyNameController,
                      icon: Icons.business_rounded,
                    ),
                    _buildTextField(
                      label: 'CIDA Registration No',
                      hintText: 'Enter CIDA Number',
                      controller: _cidaController,
                      icon: Icons.assignment_ind_rounded,
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 24),
                    const Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Contractor Full Name',
                      hintText: 'Enter Name of Proprietor',
                      controller: _contractorNameController,
                      icon: Icons.person_rounded,
                    ),
                    _buildTextField(
                      label: 'NIC Number',
                      hintText: 'Enter National Identity Card Number',
                      controller: _nicController,
                      icon: Icons.badge_rounded,
                      readOnly: _isEditMode, // NIC is primary key, cannot edit after creation
                      helperText: _isEditMode ? "NIC cannot be changed as it is the Primary Key." : null,
                    ),
                    _buildTextField(
                      label: 'Contact Number',
                      hintText: 'e.g., 071 234 5678',
                      controller: _contactController,
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'This field is required';
                        if (value.length < 10) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // --- PRIMARY ACTION BUTTON ---
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ]
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveContractor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kPrimaryColor.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24, 
                                height: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                              )
                            : Text(
                                _isEditMode ? 'Update Contractor Details' : 'Register New Contractor',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MODERN GLASS/TINTED TEXT FIELD ---
  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextColor)
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: readOnly ? Colors.grey.shade100 : kCardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: readOnly ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03), 
                  blurRadius: 15, 
                  offset: const Offset(0, 5)
                )
              ]
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              readOnly: readOnly,
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: readOnly ? Colors.grey.shade600 : kTextColor
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: kSubTextColor, fontWeight: FontWeight.normal),
                filled: true,
                fillColor: readOnly ? Colors.grey.shade100 : kCardColor,
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 8, right: 12),
                  child: Icon(
                    readOnly ? Icons.lock_outline_rounded : icon, 
                    color: readOnly ? Colors.grey.shade400 : kPrimaryColor.withOpacity(0.8), 
                    size: 22
                  )
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), 
                  borderSide: BorderSide.none
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              validator: validator ?? (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
            ),
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 4.0),
              child: Text(
                helperText,
                style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}