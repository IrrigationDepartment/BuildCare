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
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _cidaController = TextEditingController();
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.contractId != null && widget.initialData != null) {
      _isEditMode = true;
      _populateForm(widget.initialData!);
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    _cidaController.text = data['cidaRegisterNumber']?.toString() ?? '';
    _contractorController.text = data['contractorName']?.toString() ?? '';
    _typeController.text = data['typeOfContract']?.toString() ?? '';
    _valueController.text = data['contractValue']?.toString() ?? '0.0';

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
    _typeController.dispose();
    _valueController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

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

  Future<void> _saveContractDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both Start and End dates.')),
        );
        return;
      }

      final Map<String, dynamic> contractData = {
        'cidaRegisterNumber': _cidaController.text.trim(),
        'contractorName': _contractorController.text.trim(),
        'typeOfContract': _typeController.text.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
        'contractValue': double.tryParse(_valueController.text.trim()) ?? 0.0,
      };

      try {
        if (_isEditMode) {
          contractData['lastUpdated'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('contracts')
              .doc(widget.contractId!)
              .update(contractData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contract details updated successfully!')),
          );
          Navigator.of(context).pop(); 
          Navigator.of(context).pop(); 
        } else {
          contractData['timestamp'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('contracts')
              .add(contractData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contract details saved successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required IconData suffixIcon,
    required TextEditingController controller,
    bool isDate = false,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: isDate,
            onTap: isDate ? onTap : null,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Color(0xFF333333)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF757575)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Contract' : 'Add Contract Details',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveContractDetails,
            child: Text(
              _isEditMode ? 'Update' : 'Save',
              style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTextField(
                  label: 'CIDA Registration Number',
                  hintText: 'Enter Your Registration Number',
                  suffixIcon: Icons.badge,
                  controller: _cidaController,
                  validator: (value) => value!.isEmpty ? 'Please enter CIDA number' : null,
                ),
                _buildTextField(
                  label: 'Contractor Name',
                  hintText: 'Enter Contractor Name',
                  suffixIcon: Icons.person,
                  controller: _contractorController,
                  validator: (value) => value!.isEmpty ? 'Please enter contractor name' : null,
                ),
                _buildTextField(
                  label: 'Type of Contract',
                  hintText: 'Enter Contract Type',
                  suffixIcon: Icons.category,
                  controller: _typeController,
                  validator: (value) => value!.isEmpty ? 'Please enter contract type' : null,
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
                    if (value!.isEmpty) return 'Please enter project value';
                    if (double.tryParse(value) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}