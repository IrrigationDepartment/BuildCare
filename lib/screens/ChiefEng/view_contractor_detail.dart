import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class ContractorDetailsDashboardCardStream extends StatelessWidget {
  const ContractorDetailsDashboardCardStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: ContractorDetailsService().getContractorsCountStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final count = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContractorDetailsListScreen(),
              ),
            );
          },
          child: _buildOverviewCard(
            'Contractors',
            isLoading ? '...' : count.toString(),
            const Color.fromARGB(255, 255, 152, 0),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return DashboardCard(
      title: "Contractor\nDetails",
      count: count,
      icon: Icons.business,
      iconColor: Colors.orange.shade300,
      iconBackgroundColor: Colors.orange.shade50,
      width: 163,
      height: 80,
    );
  }
}


class DashboardCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final double width;
  final double height;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$count contrators",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class ContractorDetailsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get total contractors count (Future)
  Future<int> getTotalContractorsCount() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('contractor_details').get();
      return snapshot.size;
    } catch (e) {
      print('Error getting contractors count: $e');
      return 0;
    }
  }

  // Get contractors count as Stream (real-time updates)
  Stream<int> getContractorsCountStream() {
    return _firestore
        .collection('contractor_details')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Get contractors count by company name
  Future<int> getContractorsCountByCompany(String companyName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('contractor_details')
          .where('companyName', isEqualTo: companyName)
          .get();
      return snapshot.size;
    } catch (e) {
      print('Error getting contractors count by company: $e');
      return 0;
    }
  }

  // Get all contractors as Stream
  Stream<QuerySnapshot> getContractorsStream() {
    return _firestore
        .collection('contractor_details')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get single contractor by ID
  Future<DocumentSnapshot> getContractor(String contractorId) async {
    try {
      return await _firestore
          .collection('contractor_details')
          .doc(contractorId)
          .get();
    } catch (e) {
      print('Error getting contractor: $e');
      rethrow;
    }
  }

  // Get contractors by CIDA registration number
  Future<List<DocumentSnapshot>> getContractorsByCIDA(String cidaNumber) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('contractor_details')
          .where('cidaRegistrationNumber', isEqualTo: cidaNumber)
          .get();

      return snapshot.docs;
    } catch (e) {
      print('Error getting contractors by CIDA: $e');
      return [];
    }
  }

  // Get contractors statistics
  Future<Map<String, dynamic>> getContractorsStatistics() async {
    try {
      final snapshot = await _firestore.collection('contractor_details').get();

      // Get unique companies
      Set<String> uniqueCompanies = {};
      int thisMonth = 0;
      int thisYear = 0;
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Count unique companies
        if (data['companyName'] != null && data['companyName'] != '') {
          uniqueCompanies.add(data['companyName']);
        }

        // Count registrations this month and year
        if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
          try {
            final date = (data['timestamp'] as Timestamp).toDate();

            if (date.year == now.year && date.month == now.month) {
              thisMonth++;
            }

            if (date.year == now.year) {
              thisYear++;
            }
          } catch (e) {
            print('Error parsing timestamp: $e');
          }
        }
      }

      return {
        'total': snapshot.size,
        'uniqueCompanies': uniqueCompanies.length,
        'thisMonth': thisMonth,
        'thisYear': thisYear,
      };
    } catch (e) {
      print('Error getting contractors statistics: $e');
      return {
        'total': 0,
        'uniqueCompanies': 0,
        'thisMonth': 0,
        'thisYear': 0,
      };
    }
  }

  // Search contractors by name or company
  Stream<QuerySnapshot> searchContractors(String searchQuery) {
    return _firestore
        .collection('contractor_details')
        .where('contractorName', isGreaterThanOrEqualTo: searchQuery)
        .where('contractorName', isLessThan: searchQuery + 'z')
        .snapshots();
  }

  // Get contractors registered in a date range
  Future<List<DocumentSnapshot>> getContractorsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('contractor_details')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs;
    } catch (e) {
      print('Error getting contractors by date range: $e');
      return [];
    }
  }

  // Get all unique company names
  Future<List<String>> getUniqueCompanyNames() async {
    try {
      final snapshot = await _firestore.collection('contractor_details').get();
      Set<String> companies = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['companyName'] != null && data['companyName'] != '') {
          companies.add(data['companyName']);
        }
      }

      return companies.toList()..sort();
    } catch (e) {
      print('Error getting unique company names: $e');
      return [];
    }
  }
}



class ContractorDetailsListScreen extends StatelessWidget {
  const ContractorDetailsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue, size: 20),
          onPressed: () => Navigator.pop(context),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contractor_details')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No contractors found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    data['contractorName'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Company: ${data['companyName'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'CIDA: ${data['cidaRegistrationNumber'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContractorDetailsViewScreen(
                          contractorId: doc.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class ContractorDetailsViewScreen extends StatelessWidget {
  final String contractorId;

  const ContractorDetailsViewScreen({
    Key? key,
    required this.contractorId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue, size: 20),
          onPressed: () => Navigator.pop(context),
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
      body: ContractorDetailCard(contractorId: contractorId),
    );
  }
}


class ContractorDetailCard extends StatelessWidget {
  final String contractorId;

  const ContractorDetailCard({
    super.key,
    required this.contractorId,
  });

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contractor_details')
          .doc(contractorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, color: Colors.grey, size: 60),
                SizedBox(height: 16),
                Text(
                  'Contractor details not found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.business_center,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['contractorName'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['companyName'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // Contractor Details
                  const Text(
                    'Contractor Information',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow(
                    'CIDA Registration Number',
                    data['cidaRegistrationNumber']?.toString() ?? 'N/A',
                  ),

                  _buildDetailRow(
                    'Contractor Company Name',
                    data['companyName'] ?? 'N/A',
                  ),

                  _buildDetailRow(
                    'Contractor Name',
                    data['contractorName'] ?? 'N/A',
                  ),

                  _buildDetailRow(
                    'Contact Number',
                    data['contactNumber']?.toString() ?? 'N/A',
                  ),

                  _buildDetailRow(
                    'NIC Number',
                    data['nicNumber']?.toString() ?? 'N/A',
                  ),

                  // Timestamp
                  if (data['timestamp'] != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Registered Date',
                      _formatTimestamp(data['timestamp']),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ContractorStatisticsWidget extends StatelessWidget {
  const ContractorStatisticsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ContractorDetailsService().getContractorsStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contractor Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Contractors', stats['total'].toString()),
                _buildStatRow(
                    'Unique Companies', stats['uniqueCompanies'].toString()),
                _buildStatRow(
                    'Registered This Month', stats['thisMonth'].toString()),
                _buildStatRow(
                    'Registered This Year', stats['thisYear'].toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
