// In screens/TO/contract_details.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ContractDetailsScreen extends StatefulWidget {
  const ContractDetailsScreen({super.key});

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  // --- Constants ---
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Form Controllers & State ---
  final TextEditingController _cidaController = TextEditingController();
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _cidaController.dispose();
    _contractorController.dispose();
    _typeController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  // --- Date Picker Function ---
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // --- Firebase Save Logic ---
  Future<void> _saveContractDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both Start and End dates.')),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('contract_details').add({
          'cidaRegistrationNumber': _cidaController.text.trim(),
          'contractorName': _contractorController.text.trim(),
          'typeOfContract': _typeController.text.trim(),
          'startDate': _startDate,
          'endDate': _endDate,
          'contractValue': double.tryParse(_valueController.text.trim()) ?? 0.0,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract details saved successfully!')),
        );
        Navigator.pop(context);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
      }
    }
  }

  // --- Widget for custom text fields (FIXED to prevent assertion error) ---
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
    String displayValue = controller.text;
    if (isDate) {
      if (label == 'Start date' && _startDate != null) {
        displayValue = DateFormat('yyyy-MM-dd').format(_startDate!);
      } else if (label == 'End date' && _endDate != null) {
        displayValue = DateFormat('yyyy-MM-dd').format(_endDate!);
      } else {
        displayValue = '';
      }
    }

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
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            // FIX: Use controller for regular fields, but null for read-only date fields
            controller: isDate ? null : controller, 
            
            // FIX: Use initialValue for read-only date fields
            initialValue: isDate ? displayValue : null, 
            
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
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Contract Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 1. CIDA Registration Number
                _buildTextField(
                  label: 'CIDA Registration Number',
                  hintText: 'Enter Your Registaion Number',
                  suffixIcon: Icons.badge,
                  controller: _cidaController,
                  validator: (value) => value!.isEmpty ? 'Please enter CIDA number' : null,
                ),

                // 2. Contractor Name
                _buildTextField(
                  label: 'Contractor Name',
                  hintText: 'Enter Contractor Name',
                  suffixIcon: Icons.person,
                  controller: _contractorController,
                  validator: (value) => value!.isEmpty ? 'Please enter contractor name' : null,
                ),

                // 3. Type of Contract
                _buildTextField(
                  label: 'Type of Contract',
                  hintText: 'Enter Conterct Type',
                  suffixIcon: Icons.category,
                  controller: _typeController,
                  validator: (value) => value!.isEmpty ? 'Please enter contract type' : null,
                ),

                // 4. Start Date (Uses the corrected logic)
                _buildTextField(
                  label: 'Start date',
                  hintText: 'Enter Project Start Date',
                  suffixIcon: Icons.calendar_today,
                  // Passing a dummy/unrelated controller since it will be ignored by isDate logic:
                  controller: _cidaController, 
                  isDate: true,
                  onTap: () => _selectDate(context, true),
                  validator: (value) => _startDate == null ? 'Please select a start date' : null,
                ),

                // 5. End Date (Uses the corrected logic)
                _buildTextField(
                  label: 'End date',
                  hintText: 'Enter Project End Date',
                  suffixIcon: Icons.calendar_today,
                  // Passing a dummy/unrelated controller since it will be ignored by isDate logic:
                  controller: _cidaController,
                  isDate: true,
                  onTap: () => _selectDate(context, false),
                  validator: (value) => _endDate == null ? 'Please select an end date' : null,
                ),

                // 6. Value
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

                // --- Buttons ---
                Row(
                  children: [
                    // Save Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveContractDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Back Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                          side: const BorderSide(color: kPrimaryBlue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}