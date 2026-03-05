import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddContractScreen extends StatefulWidget {
  final String? contractId;
  final Map<String, dynamic>? initialData;

  const AddContractScreen({
    super.key,
    this.contractId,
    this.initialData,
  });

  @override
  State<AddContractScreen> createState() => _AddContractScreenState();
}

class _AddContractScreenState extends State<AddContractScreen> {
  // --- Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Form Controllers & State ---
  final TextEditingController _cidaController = TextEditingController();
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _companyController = TextEditingController(); // Added Company Name
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  
  // Date-picker
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEditMode = false;
  bool _isFetchingContractor = false; // Loading state for DB fetch
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Check if we are in 'Edit' mode
    if (widget.contractId != null && widget.initialData != null) {
      _isEditMode = true;
      _populateForm(widget.initialData!);
    }
  }

  // --- Helper: Populate form for 'Edit' mode ---
  void _populateForm(Map<String, dynamic> data) {
    // UPDATED: Keys matching 'contracts' database
    _cidaController.text = data['cidaNo']?.toString() ?? '';
    _contractorController.text = data['contractorName']?.toString() ?? '';
    _companyController.text = data['companyName']?.toString() ?? '';
    _typeController.text = data['projectType']?.toString() ?? '';
    _valueController.text = data['value']?.toString() ?? '';

    _startDate = _parseTimestamp(data['startDate']);
    _endDate = _parseTimestamp(data['endDate']);

    if (_startDate != null) {
      _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
    }
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  @override
  void dispose() {
    _cidaController.dispose();
    _contractorController.dispose();
    _companyController.dispose();
    _typeController.dispose();
    _valueController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // --- Auto-Fill Contractor Logic ---
  Future<void> _fetchContractorDetails() async {
    final cida = _cidaController.text.trim();
    if (cida.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a CIDA number first.')),
      );
      return;
    }

    setState(() => _isFetchingContractor = true);

    try {
      // Look for the contractor with the matching CIDA number
      // UPDATED: Query now searches using 'cidaNo' instead of 'cidaRegistrationNumber'
      final querySnapshot = await FirebaseFirestore.instance
          .collection('contractor_details')
          .where('cidaNo', isEqualTo: cida) 
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        setState(() {
          // Fill fields automatically based on Firebase data
          _contractorController.text = data['contractorName'] ?? '';
          _companyController.text = data['companyName'] ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Contractor details found & applied!'),
          ),
        );
      } else {
        // Clear fields if not found
        setState(() {
          _contractorController.clear();
          _companyController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('No contractor found with this CIDA number.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isFetchingContractor = false);
    }
  }

  // --- Date Picker Function ---
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  // --- Firebase Save / Update Logic ---
  Future<void> _saveContractDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select both Start and End dates.')),
        );
        return;
      }

      setState(() => _isSaving = true);

      // Data map to be saved/updated
      // UPDATED: Keys match the DB exactly
      final Map<String, dynamic> contractData = {
        'cidaNo': _cidaController.text.trim(),
        'contractorName': _contractorController.text.trim(),
        'companyName': _companyController.text.trim(),
        'projectType': _typeController.text.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
        'value': double.tryParse(_valueController.text.trim()) ?? 0.0,
      };

      try {
        if (_isEditMode) {
          contractData['updatedAt'] = FieldValue.serverTimestamp(); // Standardized to updatedAt
          await FirebaseFirestore.instance
              .collection('contracts')
              .doc(widget.contractId!)
              .update(contractData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('Contract details updated successfully!')),
            );
            Navigator.of(context).pop(); 
            Navigator.of(context).pop(); 
          }
        } else {
          contractData['updatedAt'] = FieldValue.serverTimestamp(); // Standardized to updatedAt
          await FirebaseFirestore.instance
              .collection('contracts')
              .add(contractData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('Contract details saved successfully!')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('Failed to save data: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  // --- Helper for Responsive Layout ---
  Widget _buildResponsiveRow(
      BoxConstraints constraints, Widget widget1, Widget widget2) {
    if (constraints.maxWidth >= 600) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: widget1),
          const SizedBox(width: 16),
          Expanded(child: widget2),
        ],
      );
    } else {
      return Column(
        children: [widget1, widget2],
      );
    }
  }

  // --- Widget for custom text fields ---
  Widget _buildTextField({
    required String label,
    required String hintText,
    IconData? suffixIcon,
    Widget? customSuffix, // Added for custom action buttons
    String? prefixText,   // Added for LKR prefix
    required TextEditingController controller,
    bool isDate = false,
    bool readOnly = false, // Added to lock fields
    VoidCallback? onTap,
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
            readOnly: isDate || readOnly,
            onTap: isDate ? onTap : null,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              color: readOnly && !isDate ? Colors.grey.shade700 : kTextColor,
              fontWeight: readOnly && !isDate ? FontWeight.bold : FontWeight.normal
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: kSubTextColor),
              prefixText: prefixText,
              prefixStyle: const TextStyle(color: kTextColor, fontWeight: FontWeight.bold, fontSize: 16),
              filled: true,
              fillColor: readOnly && !isDate ? Colors.grey.shade100 : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: customSuffix ?? (suffixIcon != null 
                ? Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(suffixIcon, color: readOnly && !isDate ? Colors.grey : kPrimaryBlue),
                ) : null),
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
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Contract' : 'Add Contract Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
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
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24.0),
                            child: Text(
                              'Manage Contract Details',
                              style: TextStyle(
                                fontSize: 15,
                                color: kSubTextColor,
                              ),
                            ),
                          ),

                          // 1. CIDA Registration Number (Full Width with Search Button)
                          _buildTextField(
                            label: 'CIDA Registration Number',
                            hintText: 'Enter CIDA and tap search to fetch details',
                            controller: _cidaController,
                            customSuffix: IconButton(
                              icon: _isFetchingContractor 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.search, color: kPrimaryBlue, size: 28),
                              onPressed: _isFetchingContractor ? null : _fetchContractorDetails,
                              tooltip: 'Verify CIDA & Auto-Fill',
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter CIDA number'
                                : null,
                          ),

                          // Row 1: Contractor Name & Company Name (Both Read Only)
                          _buildResponsiveRow(
                            constraints,
                            _buildTextField(
                              label: 'Contractor Name',
                              hintText: 'Auto-filled',
                              suffixIcon: Icons.person,
                              controller: _contractorController,
                              readOnly: true, // Locked to prevent manual typing
                              validator: (value) => value!.isEmpty
                                  ? 'Please verify CIDA number first'
                                  : null,
                            ),
                            _buildTextField(
                              label: 'Company Name',
                              hintText: 'Auto-filled',
                              suffixIcon: Icons.business,
                              controller: _companyController,
                              readOnly: true, // Locked
                            ),
                          ),

                          // Row 2: Type of Contract & Value
                          _buildResponsiveRow(
                            constraints,
                            _buildTextField(
                              label: 'Type of Contract',
                              hintText: 'E.g. Building, Road',
                              suffixIcon: Icons.category,
                              controller: _typeController,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter contract type'
                                  : null,
                            ),
                            _buildTextField(
                              label: 'Project Value (LKR)',
                              hintText: 'Enter value',
                              prefixText: 'LKR ', // Added LKR Formatting
                              controller: _valueController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value!.isEmpty) return 'Please enter project value';
                                if (double.tryParse(value) == null) return 'Enter a valid number';
                                return null;
                              },
                            ),
                          ),

                          // Row 3: Start Date & End Date
                          _buildResponsiveRow(
                            constraints,
                            _buildTextField(
                              label: 'Start Date',
                              hintText: 'Select Start Date',
                              suffixIcon: Icons.calendar_today,
                              controller: _startDateController,
                              isDate: true,
                              onTap: () => _selectDate(context, true),
                            ),
                            _buildTextField(
                              label: 'End Date',
                              hintText: 'Select End Date',
                              suffixIcon: Icons.calendar_today,
                              controller: _endDateController,
                              isDate: true,
                              onTap: () => _selectDate(context, false),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // --- Save/Update Button ---
                          _isSaving 
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveContractDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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