import 'dart:io';
import 'package:buildcare/screens/ChiefEng/chief_notification.dart';
import 'package:buildcare/screens/ChiefEng/contract_details_page.dart';
import 'package:buildcare/screens/ChiefEng/services_page_chief.dart';
import 'package:buildcare/screens/ChiefEng/view_contractor_detail.dart';
import 'package:buildcare/screens/ChiefEng/view_dage_detail_page.dart';
import 'package:buildcare/screens/ChiefEng/view_school_masterplan_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChiefEngDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ChiefEngDashboard({super.key, required this.userData});

  @override
  State<ChiefEngDashboard> createState() => _ChiefEngineerDashboardState();
}

class _ChiefEngineerDashboardState extends State<ChiefEngDashboard> {
  int _selectedIndex = 0;

  // Image variables
  File? _profileImage;
  String? _profileImageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingImage();
  }

  Future<void> _loadExistingImage() async {
    try {
      String userId = widget.userData['uid'] ?? '';
      if (userId.isEmpty) return;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('profileImage') && data['profileImage'] != null) {
          setState(() {
            _profileImageUrl = data['profileImage'];
          });
        }
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await _uploadImageToFirebase();
      }
    } catch (e) {
      _showSnackBar('Image can t select  $e', Colors.red);
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String userId = widget.userData['uid'] ?? '';
      if (userId.isEmpty) {
        throw Exception('User ID not find');
      }

      // Firebase Storage reference
      String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        try {
          Reference oldImageRef =
              FirebaseStorage.instance.refFromURL(_profileImageUrl!);
          await oldImageRef.delete();
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      UploadTask uploadTask = storageRef.putFile(_profileImage!);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImage': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploading = false;
      });

      _showSnackBar('Profile image faild upload', Colors.green);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnackBar('can t Upload : $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
                  GestureDetector(
                    onTap: _isUploading ? null : _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF64B5F6),
                            shape: BoxShape.circle,
                            image: _getProfileImageDecoration(),
                          ),
                          child: _shouldShowPersonIcon()
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        if (!_isUploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF64B5F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome !',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                            children: [
                              const TextSpan(text: 'ChiefEng-: '),
                              TextSpan(
                                text:
                                    widget.userData['name'] ?? 'Chief Engineer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const DashboardNotificationButton(),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // SchoolsDashboardCard(),
                          // DistrictEngineerDashboardCardStream()
                          // ,
                          TechnicalOfficerDashboardCardStream(),
                          DistrictEngineerDashboardCardStream(),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),

                      Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          SchoolsDashboardCard(),
                        ],
                      ),

                      //SchoolsDashboardCard(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // RecentActivitySection(),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '   Project Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 10),
            

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
              'View  issue Details',
              Icons.home_repair_service,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DamageDetailsListScreen()));

                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => IssueListScreen()));
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

  DecorationImage? _getProfileImageDecoration() {
    if (_profileImage != null) {
      return DecorationImage(
        image: FileImage(_profileImage!),
        fit: BoxFit.cover,
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_profileImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  bool _shouldShowPersonIcon() {
    return _profileImage == null &&
        (_profileImageUrl == null || _profileImageUrl!.isEmpty) &&
        !_isUploading;
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
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64B5F6),
                        shape: BoxShape.circle,
                        image: _getProfileImageDecoration(),
                      ),
                      child: _shouldShowPersonIcon()
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white)
                          : null,
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    if (!_isUploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF64B5F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
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
                value: widget.userData['mobilePhone'] ?? 'N/A',
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

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('issues')
                .orderBy('timestamp', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading activities',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      color: Color(0xFF64B5F6),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activities',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  var issueData = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IssueActivityCard(
                      issueData: issueData,
                      issueId: doc.id,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class IssueActivityCard extends StatelessWidget {
  final Map<String, dynamic> issueData;
  final String issueId;

  const IssueActivityCard({
    Key? key,
    required this.issueData,
    required this.issueId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String schoolName = issueData['schoolName'] ?? 'Unknown School';
    String issueTitle = issueData['issueTitle'] ?? 'No Title';
    String status = issueData['status'] ?? 'Pending';

    String subtitle = '$schoolName - Status: $status Review';

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
                  issueTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IssueDetailsPage(
                    issueId: issueId,
                    issueData: issueData,
                  ),
                ),
              );
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
}

class IssueDetailsPage extends StatelessWidget {
  final String issueId;
  final Map<String, dynamic> issueData;

  const IssueDetailsPage({
    Key? key,
    required this.issueId,
    required this.issueData,
  }) : super(key: key);

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Invalid Date';
      }

      String year = dateTime.year.toString();
      String month = _getMonthName(dateTime.month);
      String day = dateTime.day.toString().padLeft(2, '0');
      String hour = dateTime.hour > 12
          ? (dateTime.hour - 12).toString().padLeft(2, '0')
          : dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');
      String period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$month $day, $year - $hour:$minute $period';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Issue Details'),
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              'School Information',
              [
                _buildDetailRow('School Name', issueData['schoolName']),
                _buildDetailRow('Building Name', issueData['buildingName']),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Issue Information',
              [
                _buildDetailRow('Issue Title', issueData['issueTitle']),
                _buildDetailRow('Damage Type', issueData['damageType']),
                _buildDetailRow('Status', issueData['status']),
                _buildDetailRow('Description', issueData['description']),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Additional Details',
              [
                _buildDetailRow('Number of Classrooms',
                    issueData['numClassrooms']?.toString()),
                _buildDetailRow(
                    'Number of Floors', issueData['numFloors']?.toString()),
                _buildDetailRow('Date of Occurrence',
                    _formatDate(issueData['dateOfOccurance'])),
                _buildDetailRow(
                    'Reported On', _formatDate(issueData['timestamp'])),
                _buildDetailRow('Added By', issueData['addedByNic']),
              ],
            ),
            const SizedBox(height: 16),
            if (issueData['imageUrls'] != null &&
                (issueData['imageUrls'] as List).isNotEmpty)
              _buildImagesSection(issueData['imageUrls'] as List),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(List imageUrls) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Issue Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
