import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractDetailsDashboardCardStream extends StatelessWidget {
  const ContractDetailsDashboardCardStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: ContractDetailsService().getContractsCountStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final count = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContractDetailsListScreen(),
              ),
            );
          },
          child: _buildOverviewCard(
            'Contracts',
            isLoading ? '...' : count.toString(),
            const Color.fromARGB(255, 76, 175, 80),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return DashboardCard(
      title: "Contract\nDetails",
      count: count,
      icon: Icons.description,
      iconColor: Colors.green.shade300,
      iconBackgroundColor: Colors.green.shade50,
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$count contracts",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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

class ContractDetailsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getContractsCountStream() {
    return _firestore
        .collection('contract_details')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<int> getTotalContractsCount() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('contract_details').get();
      return snapshot.size;
    } catch (e) {
      print('Error getting contracts count: $e');
      return 0;
    }
  }
}

class ContractDetailsListScreen extends StatefulWidget {
  const ContractDetailsListScreen({Key? key}) : super(key: key);

  @override
  State<ContractDetailsListScreen> createState() =>
      _ContractDetailsListScreenState();
}

class _ContractDetailsListScreenState
    extends State<ContractDetailsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentSnapshot> _filterContracts(List<DocumentSnapshot> contracts) {
    if (_searchQuery.isEmpty) {
      return contracts;
    }

    return contracts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final contractorName =
          (data['contractorName'] ?? '').toString().toLowerCase();
      final typeOfContract =
          (data['typeOfContract'] ?? '').toString().toLowerCase();
      final cidaNumber =
          (data['cidaRegistrationNumber'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return contractorName.contains(searchLower) ||
          typeOfContract.contains(searchLower) ||
          cidaNumber.contains(searchLower);
    }).toList();
  }

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
          'Contract Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, type, or CIDA number...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Contract List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contract_details')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Colors.grey[400],
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No contracts found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredContracts =
                    _filterContracts(snapshot.data!.docs);

                if (filteredContracts.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          color: Colors.grey[400],
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found for "$_searchQuery"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredContracts.length,
                  itemBuilder: (context, index) {
                    final doc = filteredContracts[index];
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
                            Icons.description,
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
                              'Type: ${data['typeOfContract'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Value: Rs. ${data['contractValue']?.toString() ?? 'N/A'}',
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
                              builder: (context) => ContractDetailsViewScreen(
                                contractId: doc.id,
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
          ),
        ],
      ),
    );
  }
}

class ContractDetailsViewScreen extends StatelessWidget {
  final String contractId;

  const ContractDetailsViewScreen({
    Key? key,
    required this.contractId,
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
          'Contract Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ContractDetailCard(contractId: contractId),
    );
  }
}

class ContractDetailCard extends StatelessWidget {
  final String contractId;

  const ContractDetailCard({
    super.key,
    required this.contractId,
  });

  Widget _buildDetailRow(String label, String value,
      {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: isImportant ? Colors.blue : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: isImportant ? Colors.blue : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isImportant ? Colors.blue : Colors.black54,
                    fontWeight:
                        isImportant ? FontWeight.w500 : FontWeight.normal,
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is Timestamp) {
        final DateTime dateTime = date.toDate();
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      }
      return date.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';
    try {
      final num value = amount is String ? double.parse(amount) : amount;
      return 'Rs. ${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } catch (e) {
      return 'Rs. ${amount.toString()}';
    }
  }

  String _getContractStatus(dynamic startDate, dynamic endDate) {
    if (startDate == null || endDate == null) return 'Unknown';

    try {
      final DateTime now = DateTime.now();
      final DateTime start = (startDate as Timestamp).toDate();
      final DateTime end = (endDate as Timestamp).toDate();

      if (now.isBefore(start)) {
        return 'Upcoming';
      } else if (now.isAfter(end)) {
        return 'Completed';
      } else {
        return 'Active';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contract_details')
          .doc(contractId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Contract details not found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
                          Icons.person,
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
                              data['typeOfContract'] ?? 'N/A',
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

                  // Contract Details
                  const Text(
                    'Contract Information',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow(
                    'CIDA Registration Number',
                    data['cidaRegistrationNumber']?.toString() ?? 'N/A',
                  ),

                  _buildDetailRow(
                    'Contractor Name',
                    data['contractorName'] ?? 'N/A',
                  ),

                  _buildDetailRow(
                    'Type of Contract',
                    data['typeOfContract'] ?? 'N/A',
                  ),

                  _buildDetailRow(
                    'Contract Value',
                    _formatCurrency(data['contractValue']),
                    isImportant: true,
                  ),

                  _buildDetailRow(
                    'Start Date',
                    _formatDate(data['startDate']),
                  ),

                  _buildDetailRow(
                    'End Date',
                    _formatDate(data['endDate']),
                  ),

                  _buildDetailRow(
                    'Submitted By',
                    data['submitBy']?.toString() ?? 'N/A',
                  ),

                  if (data['timestamp'] != null) ...[
                    _buildDetailRow(
                      'Created Date',
                      _formatDate(data['timestamp']),
                    ),
                  ],

                  // Status
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Contract is ${_getContractStatus(data['startDate'], data['endDate'])}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}