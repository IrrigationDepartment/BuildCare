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
  bool _isLoading = false; // Added to prevent double-taps while checking DB

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
    _cidaController.text = data['cidaNo']?.toString() ?? ''; 
    _contractorNameController.text = data['contractorName']?.toString() ?? '';
    _nicController.text = data['nic']?.toString() ?? ''; 
    _contactController.text = data['contact']?.toString() ?? ''; 
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
    // 1. Validate the form fields
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading state
      });

      final cidaInput = _cidaController.text.trim();

      try {
        // --- 2. CHECK FOR DUPLICATE CIDA NUMBER ---
        final querySnapshot = await FirebaseFirestore.instance
            .collection('contractor_details')
            .where('cidaNo', isEqualTo: cidaInput)
            .get();

        bool isDuplicate = false;

        if (querySnapshot.docs.isNotEmpty) {
          if (_isEditMode) {
            // In Edit mode, it's only a duplicate if a DIFFERENT document has this CIDA
            for (var doc in querySnapshot.docs) {
              if (doc.id != widget.contractorId) {
                isDuplicate = true;
                break;
              }
            }
          } else {
            // In Add mode, ANY match is a duplicate
            isDuplicate = true;
          }
        }

        if (isDuplicate) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: This CIDA Registration Number is already added.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return; // Stop the save process here
        }

        // --- 3. Prepare data ---
        final Map<String, dynamic> contractorData = {
          'companyName': _companyNameController.text.trim(),
          'cidaNo': cidaInput, 
          'contractorName': _contractorNameController.text.trim(),
          'nic': _nicController.text.trim(), 
          'contact': _contactController.text.trim(), 
        };

        // --- 4. Save to Database ---
        if (_isEditMode) {
          contractorData['updatedAt'] = FieldValue.serverTimestamp(); 
          await FirebaseFirestore.instance
              .collection('contractor_details')
              .doc(widget.contractorId!)
              .update(contractorData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Contractor details updated successfully!')),
            );
            // Pop twice: Close Edit screen, then close View screen
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        } else {
          contractorData['updatedAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('contractor_details')
              .add(contractorData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Contractor details saved successfully!')),
            );
            // Pop once: Close Add screen
            Navigator.pop(context);
          }
        }
      } catch (e) {
        // 5. Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save data: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
            style: const TextStyle(color: kTextColor),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: kSubTextColor),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(suffixIcon, color: kPrimaryBlue),
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
      // --- App Bar (Adjusts title for Edit/Add) ---
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
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            // RESPONSIVE FIX: Constrain the maximum width to 600 pixels
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
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

                  // 1. Contractor Company Name
                  _buildTextField(
                    label: 'Contractor Company Name',
                    hintText: 'Enter Company Name',
                    suffixIcon: Icons.business,
                    controller: _companyNameController,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter company name' : null,
                  ),

                  // 2. CIDA Registration Number
                  _buildTextField(
                    label: 'CIDA Registration Number',
                    hintText: 'Enter Registration Number',
                    suffixIcon: Icons.badge,
                    controller: _cidaController,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter CIDA number' : null,
                  ),

                  // 3. Contractor Name
                  _buildTextField(
                    label: 'Contractor Name',
                    hintText: 'Enter Name',
                    suffixIcon: Icons.person,
                    controller: _contractorNameController,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter contractor name' : null,
                  ),

                  // 4. NIC number
                  _buildTextField(
                    label: 'NIC number',
                    hintText: 'Enter NIC number',
                    suffixIcon: Icons.credit_card,
                    controller: _nicController,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter NIC number' : null,
                  ),

                  // 5. Contact Number
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

                  const SizedBox(height: 32),

                  // --- Save/Update Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Disable button while loading to prevent double submission
                      onPressed: _isLoading ? null : _saveContractor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : Text(
                            _isEditMode ? 'Update Details' : 'Save Details',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}