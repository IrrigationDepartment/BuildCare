import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddContractorScreen extends StatefulWidget {
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Form Controllers & State ---
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cidaController = TextEditingController();
  final TextEditingController _contractorNameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isEditMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contractorId != null && widget.initialData != null) {
      _isEditMode = true;
      _populateForm(widget.initialData!);
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    _companyNameController.text = data['companyName'] ?? '';
    _cidaController.text = data['cidaNo'] ?? '';
    _contractorNameController.text = data['contractorName'] ?? '';
    _nicController.text = data['nic'] ?? '';
    _contactController.text = data['contact'] ?? '';
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

  // --- Save / Update Function with Notification ---
  Future<void> _saveContractor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final contractorData = {
        'companyName': _companyNameController.text.trim(),
        'cidaNo': _cidaController.text.trim(),
        'contractorName': _contractorNameController.text.trim(),
        'nic': _nicController.text.trim(),
        'contact': _contactController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        // Update existing record
        await FirebaseFirestore.instance
            .collection('contractor_details')
            .doc(widget.contractorId)
            .update(contractorData);
      } else {
        // 1. Save new contractor to Firestore
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('contractor_details')
            .add(contractorData);

        // 2. TRIGGER NOTIFICATION for the new contractor
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New Contractor Registered',
          'subtitle': '${_companyNameController.text.trim()} (${_contractorNameController.text.trim()})',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'contractor', // Used for routing in notification.dart
          'contractorId': docRef.id, // Linking the document ID
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Contractor updated!' : 'Contractor registered successfully!'),
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
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Contractor' : 'Register Contractor',
          style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                label: 'Company Name',
                hintText: 'Enter Registered Company Name',
                controller: _companyNameController,
                icon: Icons.business,
              ),
              _buildTextField(
                label: 'CIDA Registration No',
                hintText: 'Enter CIDA Number',
                controller: _cidaController,
                icon: Icons.assignment_ind,
              ),
              _buildTextField(
                label: 'Contractor Full Name',
                hintText: 'Enter Name of Proprietor',
                controller: _contractorNameController,
                icon: Icons.person,
              ),
              _buildTextField(
                label: 'NIC Number',
                hintText: 'Enter NIC',
                controller: _nicController,
                icon: Icons.badge,
              ),
              _buildTextField(
                label: 'Contact Number',
                hintText: '07X XXXXXXX',
                controller: _contactController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveContractor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditMode ? 'Update Contractor' : 'Register Contractor',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
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
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextColor)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon, color: kPrimaryBlue, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: validator ?? (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
          ),
        ],
      ),
    );
  }
}