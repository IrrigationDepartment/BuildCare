import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 0: Home, 1: Profile, 2: Settings

  // The list of screens to navigate between
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body changes based on the selected index
      body: _widgetOptions.elementAt(_selectedIndex),
      // Using a custom-built bottom navigation bar to match the image
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(Icons.home, 0),
              _buildNavIcon(Icons.person, 1),
              _buildNavIcon(Icons.settings, 2),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build each navigation icon
  Widget _buildNavIcon(IconData icon, int index) {
    // Check if this icon is the currently selected one
    final bool isSelected = _selectedIndex == index;
    final Color iconColor = isSelected ? const Color(0xFF37B5FA) : Colors.grey;

    return IconButton(
      icon: Icon(icon, color: iconColor, size: 32),
      onPressed: () => _onItemTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
