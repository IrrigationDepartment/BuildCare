import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddContractorScreen extends StatefulWidget {
  // --- Fields for Edit Mode ---
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
  // --- Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Form Controllers & State ---
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cidaController = TextEditingController();
  final TextEditingController _contractorNameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isEditMode = false;
  bool _isLoading = false; // Added loading state

  @override
  void initState() {
    super.initState();
    // Check if we are in 'Edit' mode
    if (widget.contractorId != null && widget.initialData != null) {
      _isEditMode = true;
      _populateForm(widget.initialData!);
    }
  }

  // --- Helper: Populate form for 'Edit' mode ---
  void _populateForm(Map<String, dynamic> data) {
    _companyNameController.text = data['companyName']?.toString() ?? '';
    _cidaController.text = data['cidaRegistrationNumber']?.toString() ?? '';
    _contractorNameController.text = data['contractorName']?.toString() ?? '';
    _nicController.text = data['nicNumber']?.toString() ?? '';
    _contactController.text = data['contactNumber']?.toString() ?? '';
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

  // --- Firebase Save / Update Logic ---
  Future<void> _saveContractor() async {
    FocusScope.of(context).unfocus(); // Close keyboard

    // 1. Validate the form fields
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Normalize NIC to uppercase to prevent duplicates like '123v' and '123V'
      final String nic = _nicController.text.trim().toUpperCase();

      // 2. Prepare data
      final Map<String, dynamic> contractorData = {
        'companyName': _companyNameController.text.trim(),
        'cidaRegistrationNumber': _cidaController.text.trim(),
        'contractorName': _contractorNameController.text.trim(),
        'nicNumber': nic,
        'contactNumber': _contactController.text.trim(),
      };

      try {
        // Reference the document directly using the NIC as the Primary Key (Document ID)
        final docRef = FirebaseFirestore.instance.collection('contractor_details').doc(nic);

        if (_isEditMode) {
          // --- UPDATE Logic ---
          contractorData['lastUpdated'] = FieldValue.serverTimestamp();
          await docRef.update(contractorData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Contractor details updated successfully!')),
          );
          // Pop twice: Close Edit screen, then close View screen
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else {
          // --- ADD (New) Logic ---
          
          // CHECK FOR DUPLICATES FIRST
          final docSnapshot = await docRef.get();
          if (docSnapshot.exists) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('Error: A contractor with NIC $nic already exists!')),
            );
            setState(() => _isLoading = false);
            return; // Abort save
          }

          contractorData['timestamp'] = FieldValue.serverTimestamp();
          // Use .set() instead of .add() to force the NIC as the document ID
          await docRef.set(contractorData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Contractor details saved successfully!')),
          );
          // Pop once: Close Add screen
          Navigator.pop(context);
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Failed to save data: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- Helper for Responsive Layout ---
  Widget _buildResponsiveRow(
      BoxConstraints constraints, Widget widget1, Widget widget2) {
    if (constraints.maxWidth >= 600) {
      // Desktop / Tablet layout: Side by side
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: widget1),
          const SizedBox(width: 16),
          Expanded(child: widget2),
        ],
      );
    } else {
      // Mobile layout: Stacked vertically
      return Column(
        children: [widget1, widget2],
      );
    }
  }

  // --- Custom Text Field Widget ---
  Widget _buildTextField({
    required String label,
    required String hintText,
    required IconData suffixIcon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false, // Added readOnly property
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            readOnly: readOnly, // Apply readOnly here
            style: TextStyle(
                color: readOnly ? Colors.grey.shade600 : kTextColor,
                fontWeight: readOnly ? FontWeight.w500 : FontWeight.normal),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: kSubTextColor),
              filled: true,
              fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(suffixIcon, color: readOnly ? Colors.grey : kPrimaryBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // --- App Bar ---
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Contractor' : 'Add Contractor',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        centerTitle: true,
      ),
      // --- Body with Form ---
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Max width for large screens
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Sub-header text
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24.0),
                            child: Text(
                              'Manage Contractor Information',
                              style: TextStyle(
                                fontSize: 15,
                                color: kSubTextColor,
                              ),
                            ),
                          ),

                          // 1. Contractor Company Name (Full Width)
                          _buildTextField(
                            label: 'Contractor Company Name',
                            hintText: 'Enter Company Name',
                            suffixIcon: Icons.business,
                            controller: _companyNameController,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter company name'
                                : null,
                          ),

                          // 2 & 3. Row: CIDA Reg Number & Contractor Name
                          _buildResponsiveRow(
                            constraints,
                            _buildTextField(
                              label: 'CIDA Registration Number',
                              hintText: 'Enter Registration Number',
                              suffixIcon: Icons.badge,
                              controller: _cidaController,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter CIDA number'
                                  : null,
                            ),
                            _buildTextField(
                              label: 'Contractor Name',
                              hintText: 'Enter Name',
                              suffixIcon: Icons.person,
                              controller: _contractorNameController,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter contractor name'
                                  : null,
                            ),
                          ),

                          // 4 & 5. Row: NIC number & Contact Number
                          _buildResponsiveRow(
                            constraints,
                            _buildTextField(
                              label: _isEditMode ? 'NIC Number (Primary Key)' : 'NIC Number',
                              hintText: 'Enter NIC number',
                              suffixIcon: Icons.credit_card,
                              controller: _nicController,
                              readOnly: _isEditMode, // Prevent changing NIC if editing
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter NIC number'
                                  : null,
                            ),
                            _buildTextField(
                              label: 'Contact Number',
                              hintText: 'Enter Contact Number',
                              suffixIcon: Icons.phone,
                              controller: _contactController,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter a contact number';
                                }
                                if (value.length < 10) {
                                  return 'Number must be 10 digits';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 32),

                          // --- Save/Update Button ---
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saveContractor,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: Text(
                                      _isEditMode ? 'Update Details' : 'Save Details',
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}