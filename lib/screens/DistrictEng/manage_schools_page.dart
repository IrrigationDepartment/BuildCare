// File: manage_schools_page.dart

import 'package:flutter/material.dart';

class ManageSchoolsPage extends StatelessWidget {
  const ManageSchoolsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'), // Matches the text in your screenshot
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // This navigates back to the dashboard
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            // --- Search Bar ---
            _buildSearchBar(),
            const SizedBox(height: 15),

            // --- List of Schools ---
            // The data is repeated multiple times as per your screenshot
            _buildSchoolCard(
              'Anula Devi Balika Vidyalaya',
              'Magalle, Galle.',
              'Mrs. Devika Haputhantry',
            ),
            _buildSchoolCard(
              'Anula Devi Balika Vidyalaya',
              'Magalle, Galle.',
              'Mrs. Devika Haputhantry',
            ),
            _buildSchoolCard(
              'Anula Devi Balika Vidyalaya',
              'Magalle, Galle.',
              'Mrs. Devika Haputhantry',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search Schools..........',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 10.0),
        ),
      ),
    );
  }

  Widget _buildSchoolCard(String schoolName, String location, String principal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              schoolName,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(location, style: const TextStyle(color: Colors.grey)),
            Text(principal),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Activation/Deactivation Buttons
                Row(
                  children: [
                    _buildStatusButton('Activate', Colors.green, Icons.check),
                    const SizedBox(width: 5),
                    _buildStatusButton('Deactivate', Colors.red, Icons.close),
                  ],
                ),
                // View and Edit Buttons
                Row(
                  children: [
                    _buildActionButton('View', Colors.blue, Icons.remove_red_eye),
                    const SizedBox(width: 5),
                    _buildActionButton('Edit', Colors.amber, Icons.edit),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}