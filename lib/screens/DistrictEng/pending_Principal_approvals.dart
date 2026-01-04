import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingPrincipalApprovalsPage extends StatelessWidget {
  const PendingPrincipalApprovalsPage({super.key, String? officeFilter});

  // --- Modern Professional Color Palette ---
  static const Color _bgLight = Color(0xFFF3F4F6); // Cool Gray Background
  static const Color _textDark = Color(0xFF1F2937); // Dark Slate
  static const Color _textLight = Color(0xFF6B7280); // Muted Gray
  static const Color _primaryBlue = Color(0xFF2563EB); // Royal Blue
  static const Color _successGreen = Color(0xFF10B981); // Emerald

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: _textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pending Principals', // Changed Title
          style: TextStyle(
              color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- QUERY: Filter by 'Principal' AND 'isActive: false' ---
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'Principal') // Changed to Principal
            .where('isActive', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primaryBlue));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final allDocs = snapshot.data!.docs;

          return Column(
            children: [
              // 1. Summary Header
              _buildSummaryHeader(allDocs.length),

              // 2. The List of Principals
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allDocs.length,
                  itemBuilder: (context, index) {
                    final doc = allDocs[index];
                    return _buildUserCard(context, doc);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSummaryHeader(int count) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.blue.shade50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pending Requests",
                    style: TextStyle(
                        color: _textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text("Principals", // Changed Label
                    style: TextStyle(
                        color: _textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                    color: _primaryBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'Unknown';
    final String email = data['email'] ?? 'No Email';
    final String? imageUrl = data['profile_image'];

    // Display 'School Name' for Principals
    final String schoolName = data['schoolName'] ?? 'Unassigned School';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Hero(
                  tag: doc.id,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: (imageUrl != null && imageUrl.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                      color: Colors.grey.shade200,
                    ),
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? Icon(Icons.school, // Changed icon to School for Principal
                            size: 30, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textDark),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          schoolName, // Showing School Name
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(email,
                          style:
                              const TextStyle(fontSize: 13, color: _textLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: Colors.grey.shade100),
          // Actions
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              PrincipalDetailsPage(data: data, docId: doc.id)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.only(bottomLeft: Radius.circular(16)),
                    ),
                    child: const Center(
                      child: Text(
                        "View Details",
                        style: TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                  width: 1,
                  height: 45,
                  color: Colors.grey.shade100), // Vertical Separator
              Expanded(
                child: InkWell(
                  onTap: () => _approveUser(context, doc.id, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(16)),
                    ),
                    child: const Center(
                      child: Text(
                        "Approve",
                        style: TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("All Caught Up!",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text("No pending Principals.",
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Future<void> _approveUser(
      BuildContext context, String userId, String name) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'isActive': true});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check, color: Colors.white),
              const SizedBox(width: 8),
              Text("Approved $name")
            ]),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}

// ---------------------------------------------------------
// PAGE: USER DETAILS SCREEN (For Principals)
// ---------------------------------------------------------
class PrincipalDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const PrincipalDetailsPage({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    // Safely get data
    final String name = data['name'] ?? 'N/A';
    final String email = data['email'] ?? 'N/A';
    final String mobile = data['mobilePhone'] ?? 'N/A';
    final String nic = data['nic'] ?? 'N/A';
    final String? imageUrl = data['profile_image'];

    // --- Principal Specific Data ---
    final String schoolName = data['schoolName'] ?? 'Unassigned School';
    // Often Principals might not have a separate office phone, 
    // but if they do, you can map it here. 
    final String region = data['region'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Principal Profile",
            style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Big Profile Image
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade100, width: 3),
                  image: (imageUrl != null && imageUrl.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                  color: Colors.grey.shade100,
                ),
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? Icon(Icons.person, size: 50, color: Colors.grey.shade300)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Principal",
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600)),

            const SizedBox(height: 32),

            // 2. Details Grid
            _buildSectionHeader("Contact Information"),
            _buildDetailRow(Icons.email_outlined, "Email", email),
            _buildDetailRow(Icons.phone_android_outlined, "Mobile", mobile),

            const SizedBox(height: 24),
            _buildSectionHeader("School Information"), // Changed Header
            _buildDetailRow(Icons.badge_outlined, "NIC Number", nic),
            _buildDetailRow(
                Icons.school_outlined, "School Name", schoolName), // Changed Icon/Label
            _buildDetailRow(Icons.map_outlined, "Region/Zone", region),

            const SizedBox(height: 40),

            // 3. Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _approveAndClose(context),
                child: const Text("Approve & Activate",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Very light gray
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151))),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _approveAndClose(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'isActive': true});
      if (context.mounted) {
        Navigator.pop(context); // Close details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Principal Approved"),
              backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}