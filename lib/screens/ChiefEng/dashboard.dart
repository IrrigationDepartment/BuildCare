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
import 'package:firebase_auth/firebase_auth.dart'; // Added for logout logic

import '../../login.dart'; // IMPORTANT: Adjust this path to your actual login.dart file!

// --- Modern Soft Light Mode Theme ---
const Color appBackground = Color(0xFFF0F4F8); // Slightly cooler, modern light gray
const Color primaryBlue = Color(0xFF1877F2);
const Color primaryBlueDark = Color(0xFF0C56C7); // Added for gradient
const Color textDark = Color(0xFF111418);
const Color textGrey = Color(0xFF717680);

// Sleek modern gradient
const Gradient primaryGradient = LinearGradient(
  colors: [primaryBlue, primaryBlueDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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

  // --- EXISTING LOGIC RETAINED ---
  Future<void> _loadExistingImage() async {
    try {
      String userId = widget.userData['uid'] ?? '';
      if (userId.isEmpty) return;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('profileImage') && data['profileImage'] != null) {
          setState(() => _profileImageUrl = data['profileImage']);
        }
      }
    } catch (e) { print('Error loading image: $e'); }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 80);
      if (pickedFile != null) await _uploadImageToFirebase(pickedFile);
    } catch (e) { _showSnackBar('Image can\'t select: $e', Colors.red); }
  }

  Future<void> _uploadImageToFirebase(XFile pickedFile) async {
    setState(() => _isUploading = true);
    try {
      String userId = widget.userData['uid'] ?? '';
      if (userId.isEmpty) throw Exception('User ID not found');
      final bytes = await pickedFile.readAsBytes();
      String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('profile_images').child(fileName);

      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        try {
          Reference oldImageRef = FirebaseStorage.instance.refFromURL(_profileImageUrl!);
          await oldImageRef.delete();
        } catch (e) { print('Error deleting old image: $e'); }
      }

      UploadTask uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImage': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() { _profileImageUrl = downloadUrl; _isUploading = false; });
        _showSnackBar('Profile image uploaded successfully! ✓', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackBar('Upload failed: ${e.toString()}', Colors.red);
      }
    }
  }

  // --- NEW LOGOUT LOGIC ---
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (!mounted) return;
      
      // Navigate to your Login Screen and clear the history
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()), // CHANGE to LoginScreen() if your class name is different!
        (route) => false,
      );
      
    } catch (e) {
      _showSnackBar('Error logging out: $e', Colors.red);
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Logout', 
            style: TextStyle(fontWeight: FontWeight.w800, color: textDark)
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(color: textGrey, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: textGrey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF3F2),
                foregroundColor: const Color(0xFFD92D20),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logout(); // Call the logout function
              },
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
  // -------------------------

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)), 
        backgroundColor: color, 
        duration: const Duration(seconds: 2), 
        behavior: SnackBarBehavior.floating, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      )
    );
  }

  List<Widget> get _pages => [_buildDashboardPage(), _buildProfilePage(), _buildSettingsPage()];
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: appBackground,
      extendBody: true, // Allows content to scroll behind the floating nav bar
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: primaryBlue),
                  selectedLabelTextStyle: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                  unselectedIconTheme: const IconThemeData(color: textGrey),
                  backgroundColor: Colors.white,
                  elevation: 5,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                  ],
                ),
                Expanded(child: _pages[_selectedIndex]),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: isDesktop
          ? null
          : _buildFloatingBottomNav(),
    );
  }

  // Modern Floating Bottom Navigation
  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), 
            blurRadius: 25, 
            offset: const Offset(0, 10)
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: primaryBlue,
          unselectedItemColor: textGrey.withOpacity(0.6),
          backgroundColor: Colors.white,
          elevation: 0, // Handled by container shadow
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 26), activeIcon: Icon(Icons.home, size: 28), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 26), activeIcon: Icon(Icons.person, size: 28), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 26), activeIcon: Icon(Icons.settings, size: 28), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardPage() {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 800 ? 3 : 2; 

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: screenWidth > 800 ? 40 : 100), // Padding for floating nav
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 50),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12))],
            ),
            child: Row(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.userData['uid']).snapshots(),
                  builder: (context, snapshot) {
                    String? imageUrl = (snapshot.hasData && snapshot.data!.exists) ? (snapshot.data!.data() as Map<String, dynamic>)['profileImage'] : null;
                    return GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9), 
                              shape: BoxShape.circle, 
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                              image: (imageUrl != null && imageUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                            ),
                            child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.person, color: textGrey, size: 35) : null,
                          ),
                          if (_isUploading) Positioned.fill(child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good to see you,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(widget.userData['name'] ?? 'Chief Engineer', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const DashboardNotificationButton(),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Content Area
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
                    const SizedBox(height: 20),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.35, // Slightly wider for elegance
                      children: const [
                        TechnicalOfficerDashboardCardStream(),
                        DistrictEngineerDashboardCardStream(),
                        SchoolsDashboardCard(),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    const Text('Project Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
                    const SizedBox(height: 20),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.35,
                      children: const [
                        IssuesDashboardCardStream(),
                        MasterPlansDashboardCardStream(),
                        ContractDetailsDashboardCardStream(),
                        ContractorDetailsDashboardCardStream(),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            margin: const EdgeInsets.only(top: 60, left: 24, right: 24), 
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(32), 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 25, offset: const Offset(0, 10))]
            ),
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.userData['uid']).snapshots(),
                  builder: (context, snapshot) {
                    String? imageUrl = (snapshot.hasData && snapshot.data!.exists) ? (snapshot.data!.data() as Map<String, dynamic>)['profileImage'] : null;
                    return GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 140, height: 140,
                            decoration: BoxDecoration(
                              color: appBackground, 
                              shape: BoxShape.circle, 
                              border: Border.all(color: Colors.white, width: 6), 
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))], 
                              image: (imageUrl != null && imageUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null
                            ),
                            child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.person, size: 65, color: textGrey) : null,
                          ),
                          if (!_isUploading) 
                            Positioned(
                              bottom: 4, right: 4, 
                              child: Container(
                                padding: const EdgeInsets.all(10), 
                                decoration: BoxDecoration(
                                  gradient: primaryGradient, 
                                  shape: BoxShape.circle, 
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                                ), 
                                child: const Icon(Icons.camera_alt, size: 22, color: Colors.white)
                              )
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(widget.userData['name'] ?? 'Chief Engineer', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.userData['email'] ?? 'chief@example.com', style: const TextStyle(fontSize: 15, color: primaryBlueDark, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 40),
                _buildProfileCard(icon: Icons.person_outline, title: 'Full Name', value: widget.userData['name'] ?? 'N/A'),
                _buildProfileCard(icon: Icons.phone_outlined, title: 'Phone', value: widget.userData['mobilePhone'] ?? 'N/A'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(userData: widget.userData))),
                      icon: const Icon(Icons.edit_rounded, size: 20), 
                      label: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, 
                        foregroundColor: Colors.white, 
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 20), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), 
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: appBackground, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 2)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12), 
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]), 
            child: Icon(icon, color: primaryBlue, size: 26)
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: textGrey, fontWeight: FontWeight.w600, letterSpacing: 0.5)), 
                const SizedBox(height: 4), 
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark))
              ]
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settings', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -1)),
                const SizedBox(height: 30),
                _buildSettingsItem(icon: Icons.lock_outline_rounded, title: 'Change Password', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordPageChief()))),
                _buildSettingsItem(icon: Icons.security_rounded, title: 'Security Questions', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SecurityQuestionsScreen()))),
                const SizedBox(height: 16),
                _buildSettingsItem(icon: Icons.notifications_none_rounded, title: 'Notifications', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()))),
                const SizedBox(height: 40),
                
                // --- THE UPDATED LOGOUT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLogout, // Hooked up to the new confirm logic
                    icon: const Icon(Icons.logout_rounded, size: 20), 
                    label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF3F2), 
                      foregroundColor: const Color(0xFFD92D20), 
                      elevation: 0, 
                      padding: const EdgeInsets.symmetric(vertical: 20), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                    ),
                  ),
                ),
                // ---------------------------------
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12), 
                  decoration: BoxDecoration(color: appBackground, borderRadius: BorderRadius.circular(16)), 
                  child: Icon(icon, color: primaryBlue, size: 24)
                ),
                const SizedBox(width: 20),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark))),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: appBackground, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textGrey)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}