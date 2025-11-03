import 'package:flutter/material.dart';

class ContractDetailsScreen extends StatefulWidget {
  const ContractDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationNumberController = TextEditingController();
  final _contractorNameController = TextEditingController();
  final _contractTypeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _registrationNumberController.dispose();
    _contractorNameController.dispose();
    _contractTypeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Contract Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('CIDA Registration Number:'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _registrationNumberController,
                hint: 'Enter Your Registration Number',
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('Contractor Name:'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _contractorNameController,
                hint: 'Enter Contractor Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('Type of Contract'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _contractTypeController,
                hint: 'Enter Contract Type',
                icon: Icons.description_outlined,
                borderColor: Colors.blue,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('Start date'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _startDateController,
                hint: 'Enter Project Start Date',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectDate(context, _startDateController),
              ),
              const SizedBox(height: 20),
              
              _buildLabel('End date'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _endDateController,
                hint: 'Enter Project End Date',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectDate(context, _endDateController),
              ),
              const SizedBox(height: 20),
              
              _buildLabel('Value'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _valueController,
                hint: 'Value of the Project',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Handle save action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contract details saved')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle back action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Color? borderColor,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        suffixIcon: Icon(
          icon,
          color: Colors.blue[300],
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: borderColor ?? Colors.grey[300]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: borderColor ?? Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
      ),
    );
  }
}