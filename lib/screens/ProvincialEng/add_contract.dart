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
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  // Date-picker
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEditMode = false;

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

      // Data map to be saved/updated
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
          // --- UPDATE Logic ---
          contractData['lastUpdated'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('contracts')
              .doc(widget.contractId!)
              .update(contractData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Contract details updated successfully!')),
          );
          // Close both the 'Edit' (this) and 'View' (previous) screens to return to the list
          Navigator.of(context).pop(); // Close Edit screen
          Navigator.of(context).pop(); // Close View screen
        } else {
          // --- ADD (New) Logic ---
          contractData['timestamp'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('contracts')
              .add(contractData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Contract details saved successfully!')),
          );
          // Close the 'Add' screen and return to the list
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
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

  // --- Widget for custom text fields ---
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller, // Pass the respective controller
            readOnly: isDate,
            onTap: isDate ? onTap : null,
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
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          // Change the title based on 'Edit' mode
          _isEditMode ? 'Edit Contract' : 'Add Contract Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        centerTitle: true,
        // Removed the actions[] block from here to move the button to the bottom
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Max width for web
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
                              'Manage Contract Details',
                              style: TextStyle(
                                fontSize: 15,
                                color: kSubTextColor,
                              ),
                            ),
                          ),

                          // Row 1: CIDA Reg Number & Contractor Name
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
                              hintText: 'Enter Contractor Name',
                              suffixIcon: Icons.person,
                              controller: _contractorController,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter contractor name'
                                  : null,
                            ),
                          ),

                          // Row 2: Type of Contract & Value
                          _buildResponsiveRow(
                            constraints,
                            _buildTextField(
                              label: 'Type of Contract',
                              hintText: 'Enter Contract Type',
                              suffixIcon: Icons.category,
                              controller: _typeController,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter contract type'
                                  : null,
                            ),
                            _buildTextField(
                              label: 'Value',
                              hintText: 'Value of the Project',
                              suffixIcon: Icons.attach_money,
                              controller: _valueController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter project value';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Row 3: Start Date & End Date
                          _buildResponsiveRow(
                            constraints,
                            _buildTextField(
                              label: 'Start Date',
                              hintText: 'Enter Project Start Date',
                              suffixIcon: Icons.calendar_today,
                              controller: _startDateController,
                              isDate: true,
                              onTap: () => _selectDate(context, true),
                            ),
                            _buildTextField(
                              label: 'End Date',
                              hintText: 'Enter Project End Date',
                              suffixIcon: Icons.calendar_today,
                              controller: _endDateController,
                              isDate: true,
                              onTap: () => _selectDate(context, false),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // --- Save/Update Button (Moved to Bottom) ---
                          SizedBox(
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