import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart'; // <--- NEW: Import RxDart

// --- Data Model and ApprovalCard remain the same ---

class ApprovalItem {
  final String uid; // The unique ID from Firebase Auth to update the document
  final String name;
  final String email;
  final String officePhone;
  final String mobilePhone;
  final String district;
  final String role;
  final String nic;

  ApprovalItem({
    required this.uid,
    required this.name,
    required this.email,
    required this.officePhone,
    required this.mobilePhone,
    required this.district,
    required this.role,
    required this.nic,
  });
}

class ApprovalCard extends StatelessWidget {
  final ApprovalItem item;
  final Function(String uid) onApprove;
  final Function(String uid) onDecline;
  final Function(ApprovalItem item) onViewDetails;

  const ApprovalCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onDecline,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Name and Email Row
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        item.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                // Role Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.role == 'Technical Officer'
                        ? Colors.deepPurple.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.role,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: item.role == 'Technical Officer'
                          ? Colors.deepPurple
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 18),

            // District Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('District: ${item.district}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),

            const SizedBox(height: 10),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // View Details Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: OutlinedButton.icon(
                      onPressed: () => onViewDetails(item),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                // Decline Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton.icon(
                      onPressed: () => onDecline(item.uid),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red.shade400,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                // Approve Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: ElevatedButton.icon(
                      onPressed: () => onApprove(item.uid),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------
// --- The Main Page (RxDart Integration) ---
// ------------------------------------------------------

class PendingApprovalsPage extends StatefulWidget {
  const PendingApprovalsPage({super.key});

  @override
  State<PendingApprovalsPage> createState() => _PendingApprovalsPageState();
}

class _PendingApprovalsPageState extends State<PendingApprovalsPage> {
  // RxDart: Used to manage the asynchronous loading of the DE's office.
  // We use String? to represent loading (null initial state), failure (null after load), or success (String).
  final _deOfficeSubject = BehaviorSubject<String?>.seeded(null);

  @override
  void initState() {
    super.initState();
    _fetchDEOffice();
  }

  @override
  void dispose() {
    _deOfficeSubject.close();
    super.dispose();
  }

  // 1. Fetch the current District Engineer's assigned office
  Future<void> _fetchDEOffice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error: No District Engineer logged in.')));
      }
      _deOfficeSubject.add(null);
      return;
    }

    try {
      final deDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (deDoc.exists) {
        // Publish the fetched office to the stream
        _deOfficeSubject.add(deDoc.data()?['office'] as String?);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error: DE profile not found in database.')));
        }
        _deOfficeSubject.add(null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching DE office: $e')));
      }
      _deOfficeSubject.add(null);
    }
  }

  // 2. Handle the approval logic
  Future<void> _handleApproval(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isActive': true, // User is now active (approved)
        'approvedBy': FirebaseAuth.instance.currentUser!.uid,
        'approvedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('User approved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red, content: Text('Approval failed: $e')));
      }
    }
  }

  // 3. Handle the decline logic
  Future<void> _handleDecline(String uid) async {
    try {
      // Deleting the document is a clean way to handle a declined registration request
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Registration request declined and removed.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red, content: Text('Decline failed: $e')));
      }
    }
  }

  // 4. Show a dialog with full user details
  void _showUserDetailsDialog(ApprovalItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${item.name} Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('User Type:', item.role),
                _buildDetailRow('District:', item.district),
                _buildDetailRow('NIC:', item.nic),
                _buildDetailRow('Email:', item.email),
                _buildDetailRow('Mobile Phone:', item.mobilePhone),
                _buildDetailRow('Office Phone:', item.officePhone),
                const SizedBox(height: 10),
                const Text(
                    'Note: Please verify these details before approving.',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleApproval(item.uid);
              },
              child:
                  const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // 5. Build the main page with RxDart and Firebase Stream
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pending Approvals'),
        centerTitle: true,
      ),

      // The core fix is here: StreamBuilder listens to the DE's office status.
      body: StreamBuilder<String?>(
        stream: _deOfficeSubject.stream,
        builder: (context, snapshot) {
          final deOffice = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData && deOffice == null) {
            // Initial loading state while waiting for the first value from _fetchDEOffice()
            return const Center(child: CircularProgressIndicator());
          }

          if (deOffice == null || deOffice.isEmpty) {
            // Office data failed to load or the DE document didn't have an office
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                        'Cannot load approvals. Your assigned office is unknown or failed to fetch.',
                        textAlign: TextAlign.center)));
          }

          // Once the DE office is known, start streaming the pending users
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isActive',
                    isEqualTo: false) // Filter: Users waiting for approval
                .where('office',
                    isEqualTo:
                        deOffice) // Filter: Users in the DE's assigned office
                .where('userType', whereIn: [ 
              'Technical Officer',
              'Principal'
            ]) // Filter: Only show the roles the DE approves
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError) {
                return Center(
                    child:
                        Text('Error loading requests: ${userSnapshot.error}'));
              }
              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('✅ No pending requests found.'));
              }

              // Map Firebase documents to ApprovalItem list
              final List<ApprovalItem> pendingApprovals =
                  userSnapshot.data!.docs
                      .map((doc) => ApprovalItem(
                            uid: doc.id,
                            name: doc['name'] ?? 'N/A',
                            email: doc['email'] ?? 'N/A',
                            officePhone: doc['officePhone'] ?? 'N/A',
                            mobilePhone: doc['mobilePhone'] ?? 'N/A',
                            district: doc['office'] ?? 'N/A',
                            role: doc['userType'] ?? 'N/A',
                            nic: doc['nic'] ?? 'N/A',
                          ))
                      .toList();

              return ListView.builder(
                itemCount: pendingApprovals.length,
                itemBuilder: (context, index) {
                  final item = pendingApprovals[index];
                  return ApprovalCard(
                    item: item,
                    onApprove: _handleApproval,
                    onDecline: _handleDecline,
                    onViewDetails: _showUserDetailsDialog,
                  );
                },
              );
            },
          );
        },
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
        ],
        currentIndex: 1,
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }
}
