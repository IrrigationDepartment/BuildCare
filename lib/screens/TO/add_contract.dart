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
  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kPrimaryDark = Color(0xFF312E81); // Indigo 900
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Form Controllers & State ---
  final TextEditingController _cidaController = TextEditingController();
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEditMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contractId != null && widget.initialData != null) {
      _isEditMode = true;
      _populateForm(widget.initialData!);
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    _cidaController.text = data['cidaNo'] ?? '';
    _contractorController.text = data['contractorName'] ?? '';
    _typeController.text = data['projectType'] ?? '';
    _valueController.text = (data['value'] ?? 0.0).toString();

    if (data['startDate'] != null) {
      _startDate = (data['startDate'] as Timestamp).toDate();
      _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (data['endDate'] != null) {
      _endDate = (data['endDate'] as Timestamp).toDate();
      _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
    }
  }

  @override
  void dispose() {
    _cidaController.dispose();
    _contractorController.dispose();
    _typeController.dispose();
    _valueController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // --- Date Picker Function ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: kTextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  // --- Main Save/Update Function with Notification Logic ---
  Future<void> _saveContract() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final contractData = {
        'cidaNo': _cidaController.text.trim(),
        'contractorName': _contractorController.text.trim(),
        'projectType': _typeController.text.trim(),
        'value': double.tryParse(_valueController.text.trim()) ?? 0.0,
        'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        // Update Existing
        await FirebaseFirestore.instance
            .collection('contracts')
            .doc(widget.contractId)
            .update(contractData);
      } else {
        // 1. Save new contract to Firestore
        DocumentReference contractRef = await FirebaseFirestore.instance
            .collection('contracts')
            .add(contractData);

        // 2. TRIGGER NOTIFICATION for the newly added contract
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New Project Contract Added',
          'subtitle': '${_typeController.text.trim()} by ${_contractorController.text.trim()}',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'contract', // Identify type for routing in notification.dart
          'contractId': contractRef.id, // Linking the ID so user can view details
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Contract updated successfully!' : 'Contract added successfully!',
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
            content: Text('Error: $e'), 
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
          _isEditMode ? 'Edit Contract' : 'New Contract',
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
                      'Contract Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'CIDA Registration No.',
                      hintText: 'Enter Registration No',
                      suffixIcon: Icons.badge_rounded,
                      controller: _cidaController,
                    ),
                    _buildTextField(
                      label: 'Name of the Contractor',
                      hintText: 'Enter Contractor Name',
                      suffixIcon: Icons.business_center_rounded,
                      controller: _contractorController,
                    ),
                    _buildTextField(
                      label: 'Type of the Project',
                      hintText: 'e.g. Building Construction',
                      suffixIcon: Icons.category_rounded,
                      controller: _typeController,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Start Date',
                            hintText: 'Select Date',
                            suffixIcon: Icons.calendar_today_rounded,
                            controller: _startDateController,
                            isDate: true,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'End Date',
                            hintText: 'Select Date',
                            suffixIcon: Icons.event_available_rounded,
                            controller: _endDateController,
                            isDate: true,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      label: 'Project Value (LKR)',
                      hintText: 'e.g. 5000000',
                      suffixIcon: Icons.attach_money_rounded,
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter value';
                        if (double.tryParse(value) == null) return 'Enter a valid number';
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
                        onPressed: _isLoading ? null : _saveContract,
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
                                _isEditMode ? 'Update Contract Details' : 'Save New Contract',
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
    required IconData suffixIcon,
    required TextEditingController controller,
    bool isDate = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
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
              color: kCardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03), 
                  blurRadius: 15, 
                  offset: const Offset(0, 5)
                )
              ]
            ),
            child: TextFormField(
              controller: controller,
              readOnly: isDate,
              onTap: onTap,
              keyboardType: keyboardType,
              style: const TextStyle(fontWeight: FontWeight.w600, color: kTextColor),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: kSubTextColor, fontWeight: FontWeight.normal),
                filled: true,
                fillColor: kCardColor,
                suffixIcon: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Icon(suffixIcon, color: kPrimaryColor.withOpacity(0.8), size: 22)
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
        ],
      ),
    );
  }
}