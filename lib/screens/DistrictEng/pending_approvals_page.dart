import 'package:flutter/material.dart';
//  Data Model for a Single Approval Item


class ApprovalItem {
  final String name;
  final String email;
  final String phone;
  final String district;
  final String role;

  ApprovalItem({
    required this.name,
    required this.email,
    required this.phone,
    required this.district,
    required this.role,
  });
}

//  Sample Data

final List<ApprovalItem> dummyApprovals = [
  ApprovalItem(
    name: 'Madushan Gunawardana',
    email: 'madush.19@gmail.com',
    phone: '+ 76 58 25 479',
    district: 'Galle',
    role: 'TO',
  ),
  ApprovalItem(
    name: 'Pasidu Rajapaksha',
    email: 'pasid@email.com',
    phone: '+ 71 59 59 479',
    district: 'Matara',
    role: 'Principle',
  ),
  ApprovalItem(
    name: 'Ravi Karunarathna',
    email: 'ravi.2002@gmail.com',
    phone: '+ 78 54 12 369',
    district: 'Hambantota',
    role: 'TO',
  ),
];

//  The Custom Card Widget for an Approval Item

class ApprovalCard extends StatelessWidget {
  final ApprovalItem item;

  const ApprovalCard({super.key, required this.item});

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
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 18),

            // Details and Role Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Details (Phone and District)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      Text(item.phone,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('District',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      Text(item.district,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Role
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Role',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    Text(item.role,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // View Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Handle View action
                        print('View ${item.name}');
                      },
                      icon: const Icon(Icons.remove_red_eye, size: 18),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                // Edit Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Handle Edit action
                        print('Edit ${item.name}');
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
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
                      onPressed: () {
                        // Handle Approve action
                        print('Approve ${item.name}');
                      },
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

// The Main Page

class PendingApprovalsPage extends StatelessWidget {
  const PendingApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the default back arrow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Handle back button press
            Navigator.pop(context);
          },
        ),
        title: const Text('Pending Approvels'),
        centerTitle: true,
      ),

      // Body: List of Approval Cards
      body: ListView.builder(
        itemCount: dummyApprovals.length,
        itemBuilder: (context, index) {
          return ApprovalCard(item: dummyApprovals[index]);
        },
      ),

      // Bottom Navigation Bar 
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Essential for > 3 items
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '', // Empty label as in the screenshot
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
        currentIndex: 1, // 'person' icon selected
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }
}

