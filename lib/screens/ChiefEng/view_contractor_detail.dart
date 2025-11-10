import 'package:flutter/material.dart';

class ContractorDetailsPage extends StatefulWidget {
  const ContractorDetailsPage({Key? key}) : super(key: key);

  @override
  State<ContractorDetailsPage> createState() => _ContractorDetailsPageState();
}

class _ContractorDetailsPageState extends State<ContractorDetailsPage> {
  final _companyNameController = TextEditingController();
  final _registrationController = TextEditingController();
  final _contractorNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _registrationController.dispose();
    _contractorNameController.dispose();
    _nicController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Contractor Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
             
              const Text(
                'Manage Contractor Information and Documents',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        label: 'Contractor Company Name:',
                        hint: 'Enter Your Company Name',
                        controller: _companyNameController,
                        icon: Icons.business,
                      ),
                      const SizedBox(height: 30),
                      _buildInputField(
                        label: 'CIDA Registration Number:',
                        hint: 'Enter Your Registration Number',
                        controller: _registrationController,
                        icon: Icons.card_membership,
                      ),
                      const SizedBox(height: 30),
                      _buildInputField(
                        label: 'Contractor Name:',
                        hint: 'Enter Your Name',
                        controller: _contractorNameController,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 30),
                      _buildInputField(
                        label: 'NIC number:',
                        hint: 'Enter your NIC number',
                        controller: _nicController,
                        icon: Icons.credit_card,
                      ),
                      const SizedBox(height: 30),
                      _buildInputField(
                        label: 'Contact Number:',
                        hint: 'Enter your Contact Number',
                        controller: _contactController,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Save functionality
                        print('Save button pressed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            suffixIcon: Icon(
              icon,
              color: const Color(0xFF64B5F6),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}