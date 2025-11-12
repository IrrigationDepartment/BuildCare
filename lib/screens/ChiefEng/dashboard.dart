import 'package:buildcare/screens/ChiefEng/contract_details_page.dart';
import 'package:buildcare/screens/ChiefEng/view_contractor_detail.dart';
import 'package:buildcare/screens/ChiefEng/view_dage_detail_page.dart';
import 'package:buildcare/screens/ChiefEng/view_distric_eng_page.dart';
import 'package:buildcare/screens/ChiefEng/view_school_details.dart';
import 'package:buildcare/screens/ChiefEng/view_school_masterplan_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChiefEngDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ChiefEngDashboard({super.key, required this.userData});

  @override
  State<ChiefEngDashboard> createState() => _ChiefEngineerDashboardState();
}

class _ChiefEngineerDashboardState extends State<ChiefEngDashboard> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
        _buildDashboardPage(),
        _buildProfilePage(),
        _buildSettingsPage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF64B5F6),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 30),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings, size: 30),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Welcome Text
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome !',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chief Engineer',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SchoolsDashboardCard(),

                      // _buildOverviewCard(
                      //     'Total Schools', '150', const Color(0xFFB3E5FC)),
                      _buildOverviewCard(
                          'Active TOs', '25', const Color(0xFFB3E5FC)),
                      _buildOverviewCard(
                          'Active DE', '3', const Color(0xFFB3E5FC)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent Activity Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildActivityItem(
                    'Thurstan College - Damaged Roof',
                    'Colombo - Status: Pending Review',
                  ),
                  const SizedBox(height: 10),
                  _buildActivityItem(
                    'Thurstan College - Damaged Roof',
                    'Colombo - Status: Pending Review',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Approval Request Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Approval Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'J. Manel Withana request to',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'register as a DE.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64B5F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'View Approve',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButton(
              'View District Engineer Details',
              Icons.engineering,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ActiveDistrictEngineerScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'View School Master Plan',
              Icons.description,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SchoolMasterPlanScreen()));
              },
            ),

            _buildActionButton(
              'View Damage Details',
              Icons.home_repair_service,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DamageDetailsListScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'View Contract Details',
              Icons.receipt_long,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ContractDetailsListScreen()));
              },
            ),
            const SizedBox(height: 12),

            

            _buildActionButton(
              'View Contractor Details ',
              Icons.person_search,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ContractorDetailsListScreen()));
              },
            ),

            

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business,
              size: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ManageSchoolView()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              'View Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Icon(
              icon,
              color: const Color(0xFF64B5F6),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF64B5F6),
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                widget.userData['name'] ?? 'Chief Engineer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.userData['email'] ?? 'chief@example.com',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              _buildProfileCard(
                icon: Icons.person,
                title: 'Full Name',
                value: widget.userData['name'] ?? 'N/A',
              ),
              _buildProfileCard(
                icon: Icons.email,
                title: 'Email',
                value: widget.userData['email'] ?? 'N/A',
              ),
              _buildProfileCard(
                icon: Icons.phone,
                title: 'Phone',
                value: widget.userData['phone'] ?? 'N/A',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFB3E5FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF64B5F6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingsSection('Account Settings'),
          _buildSettingsItem(
              icon: Icons.person, title: 'Edit Profile', onTap: () {}),
          _buildSettingsItem(
              icon: Icons.lock, title: 'Change Password', onTap: () {}),
          _buildSettingsItem(
              icon: Icons.security, title: 'Privacy & Security', onTap: () {}),
          const SizedBox(height: 20),
          _buildSettingsSection('App Settings'),
          _buildSettingsItem(
              icon: Icons.notifications, title: 'Notifications', onTap: () {}),
          _buildSettingsItem(
              icon: Icons.language, title: 'Language', onTap: () {}),
          _buildSettingsItem(
              icon: Icons.dark_mode, title: 'Theme', onTap: () {}),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFB3E5FC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF64B5F6)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

//todo:view the total of  school

// services/school_service.dart

class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<int> getTotalSchoolsCount() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('schools').get();
      return snapshot.size;
    } catch (e) {
      print('Error getting schools count: $e');
      return 0;
    }
  }

  
  Stream<int> getSchoolsCountStream() {
    return _firestore.collection('schools').snapshots().map(
          (snapshot) => snapshot.size,
        );
  }
}

class SchoolsDashboardCard extends StatefulWidget {
  const SchoolsDashboardCard({Key? key}) : super(key: key);

  @override
  State<SchoolsDashboardCard> createState() => _SchoolsDashboardCardState();
}

class _SchoolsDashboardCardState extends State<SchoolsDashboardCard> {
  final SchoolService _schoolService = SchoolService();
  int _schoolsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolsCount();
  }

  Future<void> _loadSchoolsCount() async {
    try {
      final count = await _schoolService.getTotalSchoolsCount();
      setState(() {
        _schoolsCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading schools count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildOverviewCard(
      'Total Schools',
      _isLoading ? '...' : _schoolsCount.toString(),
      const Color(0xFFB3E5FC),
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class SchoolsDashboardCardStream extends StatelessWidget {
  const SchoolsDashboardCardStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: SchoolService().getSchoolsCountStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final count = snapshot.data ?? 0;

        return _buildOverviewCard(
          'Total Schools',
          isLoading ? '...' : count.toString(),
          const Color(0xFFB3E5FC),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String count, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
