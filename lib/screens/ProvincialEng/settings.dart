// settings.dart
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// --- Settings Page Screen ---
// -----------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. App Bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // Back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // ආපහු Dashboard එකට යන්න
            Navigator.pop(context);
          },
        ),
        // Title
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // Save button
        actions: [
          TextButton(
            onPressed: () {
              // Save button එක click කලාම වෙන්න ඕන දේ
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),

      // 2. Body
      backgroundColor: const Color(0xFFF5F5F5), // අළු පාට background
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Account Section ---
          const _SectionHeader(title: 'Account'),
          _SettingsItem(
            title: 'Change Password',
            onTap: () {
              // "Change Password" click කලාම වෙන්න ඕන දේ
            },
          ),
          const SizedBox(height: 20),

          // --- Support Section ---
          const _SectionHeader(title: 'Support'),
          _SettingsItem(
            title: 'Developer Team',
            onTap: () {
              // "Developer Team" click කලාම වෙන්න ඕන දේ
            },
          ),
          _SettingsItem(
            title: 'Report a Problem',
            onTap: () {
              // "Report a Problem" click කලාම වෙන්න ඕන දේ
            },
          ),
          _SettingsItem(
            title: 'Privacy Policy',
            onTap: () {
              // "Privacy Policy" click කලාම වෙන්න ඕන දේ
            },
          ),
          const SizedBox(height: 40),

          // --- Log out Button ---
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // "Log out" click කලාම වෙන්න ඕන දේ
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), // රතු පාට
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Log out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),

      // 3. Bottom Navigation Bar
      // Settings page එකේදී Settings icon එක active (blue) කරලා
      // currentIndex: 2 මගින් Settings active බව පෙන්වයි.
      bottomNavigationBar: const SettingsBottomNavBar(currentIndex: 2),
    );
  }
}

// -----------------------------------------------------------------------------
// --- Helper Widgets for Settings Page ---
// -----------------------------------------------------------------------------

// "Account", "Support" වගේ headers හදන්න
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}

// "Change Password" වගේ list items හදන්න
class _SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- SettingsBottomNavBar (Settings Page එකට අදාල) ---
// -----------------------------------------------------------------------------
class SettingsBottomNavBar extends StatelessWidget {
  // currentIndex = 2: Settings
  final int currentIndex;
  const SettingsBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          // Home icon (Click කලාම ආපහු Dashboard එකට යන්න)
          IconButton(
            icon: Icon(
              Icons.home_outlined, 
              color: currentIndex == 0 ? Colors.blue : Colors.black54, // Settings page එකේදී black54
              size: 30
            ),
            onPressed: () {
              Navigator.pop(context); // ආපහු Dashboard එකට යනවා
            },
          ),
          // Profile icon
          IconButton(
            icon: Icon(
              Icons.person, 
              color: currentIndex == 1 ? Colors.blue : Colors.black54, 
              size: 30
            ),
            onPressed: () {
              // Profile Page navigation logic මෙතනට එන්න ඕන
            },
          ),
          // Settings icon (මේ page එකේදි Active)
          IconButton(
            icon: Icon(
              Icons.settings, 
              color: currentIndex == 2 ? Colors.blue : Colors.black54, // Settings page එකේදී Blue
              size: 30
            ),
            onPressed: () {
              // දැනටමත් Settings page එකේ සිටින නිසා කිසිවක් සිදු නොවේ (Navigation avoid කරයි)
            },
          ),
        ],
      ),
    );
  }
}