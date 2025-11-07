import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorDetailsScreen extends StatefulWidget {
  const ContractorDetailsScreen({super.key});

  @override
  State<ContractorDetailsScreen> createState() => _ContractorDetailsScreenState();
}

class _ContractorDetailsScreenState extends State<ContractorDetailsScreen> {
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

  @override
  void dispose() {
    _companyNameController.dispose();
    _cidaController.dispose();
    _contractorNameController.dispose();
    _nicController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // --- Firebase Save Logic ---
  Future<void> _saveContractorDetails() async {
    // 1. Validate the form fields
    if (_formKey.currentState!.validate()) {
      try {
        // 2. Save data to Firestore
        await FirebaseFirestore.instance.collection('contractor_details').add({
          'companyName': _companyNameController.text.trim(),
          'cidaRegistrationNumber': _cidaController.text.trim(),
          'contractorName': _contractorNameController.text.trim(),
          'nicNumber': _nicController.text.trim(),
          'contactNumber': _contactController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 3. Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Contractor details saved successfully!')),
        );

        // 4. Navigate back
        Navigator.pop(context);
      } catch (e) {
        // 5. Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
      }
    }
  }

  // --- Custom Text Field Widget (Similar to contract_details.dart) ---
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
      // --- App Bar (Matches existing screen style) ---
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Contractor Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        centerTitle: true,
      ),
      // --- Body with Form ---
      body: SingleChildScrollView(
        child: Padding(
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
                    'Manage Contractor Information and Documents',
                    style: TextStyle(
                      fontSize: 15,
                      color: kSubTextColor,
                    ),
                  ),
                ),

                // 1. Contractor Company Name
                _buildTextField(
                  label: 'Contractor Company Name',
                  hintText: 'Enter Your Company Name',
                  suffixIcon: Icons.business, // Icon matches image
                  controller: _companyNameController,
                  validator: (value) => value!.isEmpty
                      ? 'Please enter the company name'
                      : null,
                ),

                // 2. CIDA Registration Number
                _buildTextField(
                  label: 'CIDA Registration Number',
                  hintText: 'Enter Your Registaion Number',
                  suffixIcon: Icons.badge, // Icon matches image
                  controller: _cidaController,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter CIDA number' : null,
                ),

                // 3. Contractor Name
                _buildTextField(
                  label: 'Contractor Name',
                  hintText: 'Enter Your Name',
                  suffixIcon: Icons.person, // Icon matches image
                  controller: _contractorNameController,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter contractor name' : null,
                ),

                // 4. NIC number
                _buildTextField(
                  label: 'NIC number',
                  hintText: 'Enter your NIC number',
                  suffixIcon: Icons.credit_card, // Icon matches image
                  controller: _nicController,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter NIC number' : null,
                ),

                // 5. Contact Number
                _buildTextField(
                  label: 'Contact Number',
                  hintText: 'Enter Your Contact Number',
                  suffixIcon: Icons.phone, // Icon matches image
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

                // --- Buttons (Matching style and colors) ---
                Row(
                  children: [
                    // Save Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveContractorDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // Rounded corners for button
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Save',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            borderRadius: BorderRadius.circular(20), // Rounded corners for button
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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