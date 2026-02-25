import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- IMPORT ADD/EDIT SCREEN ---
import 'add_contractor_screen.dart';

class ViewContractorScreen extends StatefulWidget {
  final String contractorId;

  const ViewContractorScreen({super.key, required this.contractorId});

  @override
  State<ViewContractorScreen> createState() => _ViewContractorScreenState();
}

class _ViewContractorScreenState extends State<ViewContractorScreen> {
  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kPrimaryDark = Color(0xFF312E81); // Indigo 900
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500
  static const Color kDangerColor = Color(0xFFEF4444); // Red 500

  bool _isDeleting = false;

  // --- DELETE FUNCTION WITH LOADING STATE ---
  Future<void> _deleteContractor() async {
    // Show premium confirmation dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kDangerColor),
            SizedBox(width: 10),
            Text('Delete Contractor?', style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently remove this contractor? This action cannot be undone.',
          style: TextStyle(color: kSubTextColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: kSubTextColor, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDangerColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await FirebaseFirestore.instance
            .collection('contractor_details')
            .doc(widget.contractorId)
            .delete();
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Contractor deleted successfully', style: TextStyle(fontWeight: FontWeight.bold)), 
              backgroundColor: kDangerColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.of(context).pop(); // Go back to list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: kDangerColor),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
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
        title: const Text(
          'Contractor Profile',
          style: TextStyle(fontWeight: FontWeight.w800, color: kTextColor, fontSize: 20),
        ),
      ),
      // --- FETCH DATA FROM FIRESTORE ---
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('contractor_details').doc(widget.contractorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile.', style: TextStyle(color: kDangerColor)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Contractor not found.', style: TextStyle(color: kSubTextColor)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              // RESPONSIVE WRAPPER: Centers the profile on large screens
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- COMPANY DETAILS ---
                        const Text(
                          'Company Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextColor, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 20),
                        _buildProfileRow(
                          label: 'Company Name',
                          value: data['companyName'] ?? 'N/A',
                          icon: Icons.business_rounded,
                        ),
                        const Divider(height: 30, color: Colors.black12),
                        _buildProfileRow(
                          label: 'CIDA Reg. Number',
                          value: data['cidaNo'] ?? 'N/A',
                          icon: Icons.assignment_ind_rounded,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // --- PERSONAL DETAILS ---
                        const Text(
                          'Primary Contact',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextColor, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 20),
                        _buildProfileRow(
                          label: 'Contractor Name',
                          value: data['contractorName'] ?? 'N/A',
                          icon: Icons.person_rounded,
                        ),
                        const Divider(height: 30, color: Colors.black12),
                        _buildProfileRow(
                          label: 'NIC Number',
                          value: data['nic'] ?? 'N/A',
                          icon: Icons.badge_rounded,
                        ),
                        const Divider(height: 30, color: Colors.black12),
                        _buildProfileRow(
                          label: 'Contact Number',
                          value: data['contact'] ?? 'N/A',
                          icon: Icons.phone_rounded,
                        ),
                        
                        const SizedBox(height: 40),

                        // --- ACTION BUTTONS ---
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ]
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Pass data to Edit Screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddContractorScreen(
                                    contractorId: widget.contractorId,
                                    initialData: data,
                                  ),
                                ),
                              ).then((_) => setState(() {})); // Refresh when returning
                            },
                            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                            label: const Text('Edit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _isDeleting ? null : _deleteContractor,
                            icon: _isDeleting 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kDangerColor, strokeWidth: 2))
                                : const Icon(Icons.delete_outline_rounded, color: kDangerColor, size: 20),
                            label: const Text('Delete Contractor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kDangerColor, letterSpacing: 0.5)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kDangerColor, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- REUSABLE PREMIUM PROFILE ROW ---
  Widget _buildProfileRow({required String label, required String value, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: kSubTextColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: kTextColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}