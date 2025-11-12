import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ActiveDistrictEngineerScreen extends StatefulWidget {
  const ActiveDistrictEngineerScreen({Key? key}) : super(key: key);

  @override
  State<ActiveDistrictEngineerScreen> createState() => _ActiveDistrictEngineerScreenState();
}

class _ActiveDistrictEngineerScreenState extends State<ActiveDistrictEngineerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Engineer> _engineers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _loadDistrictEngineers();
    } catch (e) {
      print("Firebase initialization error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDistrictEngineers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'District Engineer')
          .get();

      List<Engineer> engineers = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        engineers.add(Engineer(
          id: doc.id,
          name: data['name'] ?? 'No Name',
          phone: data['nobll@Phone'] ?? data['officePhone'] ?? 'No Phone',
          district: data['office'] ?? 'No District',
          email: data['email'] ?? 'No Email',
          nic: data['nic'] ?? 'No NIC',
          isActive: data['isActive'] ?? false,
          createdAt: _parseDate(data['create64t']),
        ));
      }

      setState(() {
        _engineers = engineers;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading engineers: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _parseDate(dynamic dateData) {
    try {
      if (dateData is Timestamp) {
        return dateData.toDate();
      } else if (dateData is String) {
        // Handle your specific date format "November 7,2025 at 31:53dPM UTC+530"
        return DateTime.now(); // Replace with actual parsing logic
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _approveEngineer(String engineerId) async {
    try {
      await _firestore.collection('users').doc(engineerId).update({
        'isActive': true,
      });
      
      // Refresh the list
      _loadDistrictEngineers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Engineer approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving engineer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewEngineerDetails(Engineer engineer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EngineerDetailScreen(engineer: engineer),
      ),
    );
  }

  void _editEngineer(Engineer engineer) {
    // TODO: Implement edit functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Engineer'),
        content: Text('Edit functionality for ${engineer.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Active District Engineer',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadDistrictEngineers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _engineers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.engineering, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No District Engineers Found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._engineers.map((engineer) => Column(
                          children: [
                            EngineerCard(
                              engineer: engineer,
                              onView: () => _viewEngineerDetails(engineer),
                              onEdit: () => _editEngineer(engineer),
                              onApprove: () => _approveEngineer(engineer.id),
                            ),
                            const SizedBox(height: 12),
                          ],
                        )),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
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
      ),
    );
  }
}

class Engineer {
  final String id;
  final String name;
  final String phone;
  final String district;
  final String email;
  final String nic;
  final bool isActive;
  final DateTime createdAt;

  Engineer({
    required this.id,
    required this.name,
    required this.phone,
    required this.district,
    required this.email,
    required this.nic,
    required this.isActive,
    required this.createdAt,
  });
}

class EngineerCard extends StatelessWidget {
  final Engineer engineer;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onApprove;

  const EngineerCard({
    Key? key,
    required this.engineer,
    required this.onView,
    required this.onEdit,
    required this.onApprove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.person, color: Colors.blue[700]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      engineer.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      engineer.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: engineer.isActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  engineer.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: engineer.isActive ? Colors.green[800] : Colors.red[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      engineer.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NIC',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      engineer.nic,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'District',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            engineer.district,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.remove_red_eye, size: 18),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!engineer.isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: Icon(Icons.check, size: 18),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EngineerDetailScreen extends StatelessWidget {
  final Engineer engineer;

  const EngineerDetailScreen({Key? key, required this.engineer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Engineer Details',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, size: 40, color: Colors.blue[700]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    engineer.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: engineer.isActive ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      engineer.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: engineer.isActive ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Details
            _buildDetailItem('Email', engineer.email),
            _buildDetailItem('Phone', engineer.phone),
            _buildDetailItem('NIC', engineer.nic),
            _buildDetailItem('District', engineer.district),
            _buildDetailItem('Status', engineer.isActive ? 'Active' : 'Inactive'),
            _buildDetailItem('Joined Date', '${engineer.createdAt.day}/${engineer.createdAt.month}/${engineer.createdAt.year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}