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
            content: Text(_isEditMode ? 'Contract updated!' : 'Contract added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Contract' : 'Add New Contract',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : OutlinedButton(
                    onPressed: _saveContract,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryBlue,
                      side: const BorderSide(color: kPrimaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_isEditMode ? 'Update' : 'Save'),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                label: 'CIDA No',
                hintText: 'Enter Registration No',
                suffixIcon: Icons.badge,
                controller: _cidaController,
              ),
              _buildTextField(
                label: 'Name of the Contractor',
                hintText: 'Enter Contractor Name',
                suffixIcon: Icons.person,
                controller: _contractorController,
              ),
              _buildTextField(
                label: 'Type of the Project',
                hintText: 'e.g. Building Construction',
                suffixIcon: Icons.category,
                controller: _typeController,
              ),
              _buildTextField(
                label: 'Start date',
                hintText: 'Enter Project Start Date',
                suffixIcon: Icons.calendar_today,
                controller: _startDateController,
                isDate: true,
                onTap: () => _selectDate(context, true),
              ),
              _buildTextField(
                label: 'End date',
                hintText: 'Enter Project End Date',
                suffixIcon: Icons.calendar_today,
                controller: _endDateController,
                isDate: true,
                onTap: () => _selectDate(context, false),
              ),
              _buildTextField(
                label: 'Value',
                hintText: 'Value of the Project',
                suffixIcon: Icons.attach_money,
                controller: _valueController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter value';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: isDate,
            onTap: onTap,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Colors.white,
              suffixIcon: Icon(suffixIcon, color: Colors.grey, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: validator ?? (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
          ),
        ],
      ),
    );
  }
}