import 'package:buildcare/screens/ChiefEng/chief_notification.dart';
import 'package:buildcare/screens/ChiefEng/contract_details_page.dart';
import 'package:buildcare/screens/ChiefEng/sample/change_password_chied.dart';
import 'package:buildcare/screens/ChiefEng/sample/edit_profile_page.dart';
import 'package:buildcare/screens/ChiefEng/sample/sequrty_question_page.dart';
import 'package:buildcare/screens/ChiefEng/services_page_chief.dart';
import 'package:buildcare/screens/ChiefEng/view_contractor_detail.dart';
import 'package:buildcare/screens/ChiefEng/view_dage_detail_page.dart';
import 'package:buildcare/screens/ChiefEng/view_school_masterplan_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// --- FB Style Theme Colors ---
const Color fbBackground = Color(0xFFF0F2F5);
const Color fbBlue = Color(0xFF1877F2);
const Color fbDarkText = Color(0xFF050505);
const Color fbSecondaryText = Color(0xFF65676B);

class ChiefEngDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ChiefEngDashboard({super.key, required this.userData});

  @override
  State<ChiefEngDashboard> createState() => _ChiefEngineerDashboardState();
}

class _ChiefEngineerDashboardState extends State<ChiefEngDashboard> {
  int _selectedIndex = 0;

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
        await _uploadImageToFirebase(pickedFile);
      }
    } catch (e) {
      _showSnackBar('Image can\'t select: $e', Colors.red);
    }
  }

  Future<void> _uploadImageToFirebase(XFile pickedFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      String userId = widget.userData['uid'] ?? '';
      if (userId.isEmpty) throw Exception('User ID not found');

      final bytes = await pickedFile.readAsBytes();
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

      UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImage': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploading = false;
        });
        _showSnackBar('Profile image uploaded successfully! ✓', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        _showSnackBar('Upload failed: ${e.toString()}', Colors.red);
      }
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
    // Detect screen width for responsive web vs mobile
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: fbBackground,
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: fbBlue),
                  selectedLabelTextStyle: const TextStyle(color: fbBlue, fontWeight: FontWeight.bold),
                  unselectedIconTheme: const IconThemeData(color: fbSecondaryText),
                  backgroundColor: Colors.white,
                  elevation: 5,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _pages[_selectedIndex]),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: fbBlue,
                unselectedItemColor: fbSecondaryText,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                backgroundColor: Colors.white,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined, size: 28),
                    activeIcon: Icon(Icons.home, size: 28),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline, size: 28),
                    activeIcon: Icon(Icons.person, size: 28),
                    label: 'Profile',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined, size: 28),
                    activeIcon: Icon(Icons.settings, size: 28),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
    );
  }

  // Wraps main content in a constrained box so it doesn't stretch endlessly on huge screens
  Widget _buildResponsiveWrapper({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000), // Max width for web
        child: child,
      ),
    );
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      child: _buildResponsiveWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [fbBlue, Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: fbBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // StreamBuilder for real-time profile image updates
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userData['uid'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        String? imageUrl;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          imageUrl = data['profileImage'];
                        }

                        return GestureDetector(
                          onTap: _isUploading ? null : _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  image: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (imageUrl == null || imageUrl.isEmpty)
                                    ? const Icon(Icons.person,
                                        color: fbSecondaryText, size: 40)
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
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.userData['name'] ?? 'Chief Engineer'}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Chief Engineer Dashboard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const DashboardNotificationButton(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // User Management Section
              _buildSectionCard(
                title: 'User Management',
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.start,
                  children: [
                    SizedBox(width: 300, child: TechnicalOfficerDashboardCardStream()),
                    SizedBox(width: 300, child: DistrictEngineerDashboardCardStream()),
                    SizedBox(width: 300, child: SchoolsDashboardCard()),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Project Management Section
              _buildSectionCard(
                title: 'Project Management',
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.start,
                  children: [
                    SizedBox(width: 300, child: IssuesDashboardCardStream()),
                    SizedBox(width: 300, child: MasterPlansDashboardCardStream()),
                    SizedBox(width: 300, child: ContractDetailsDashboardCardStream()),
                    SizedBox(width: 300, child: ContractorDetailsDashboardCardStream()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable FB-style card wrapper for sections
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
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
              color: fbDarkText,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      child: _buildResponsiveWrapper(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Profile Image Logic
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userData['uid'])
                    .snapshots(),
                builder: (context, snapshot) {
                  String? imageUrl;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    imageUrl = data['profileImage'];
                  }

                  return GestureDetector(
                    onTap: _isUploading ? null : _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: fbBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                            image: (imageUrl != null && imageUrl.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? const Icon(Icons.person, size: 70, color: fbSecondaryText)
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: fbBackground,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 22, color: fbDarkText),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                widget.userData['name'] ?? 'Chief Engineer',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: fbDarkText),
              ),
              const SizedBox(height: 8),
              Text(
                widget.userData['email'] ?? 'chief@example.com',
                style: const TextStyle(fontSize: 16, color: fbSecondaryText),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            userData: widget.userData,
                          ),
                        ));
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fbBackground,
                    foregroundColor: fbDarkText,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildProfileCard({required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fbBackground, // Soft background for input-like fields
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: fbBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: fbSecondaryText, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fbDarkText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      child: _buildResponsiveWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Settings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: fbDarkText),
              ),
              const SizedBox(height: 24),
              _buildSettingsSection('Account Settings'),
              _buildSettingsItem(
                  icon: Icons.lock,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordPageChief()));
                  }),
              _buildSettingsItem(
                  icon: Icons.security,
                  title: 'Security Questions',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SecurityQuestionsScreen()));
                  }),
              const SizedBox(height: 20),
              _buildSettingsSection('App Settings'),
              _buildSettingsItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
                  }),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle Logout
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
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

  Widget _buildSettingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: fbSecondaryText, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: fbBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: fbDarkText),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fbDarkText),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: fbSecondaryText),
        onTap: onTap,
      ),
    );
  }
}

// Ensure your DashboardCarddash & IssueActivityCard files/classes use 'Container' layout instead of fixed width Row constraints so Wrap() takes effect properly.