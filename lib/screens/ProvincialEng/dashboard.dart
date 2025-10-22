import 'package:flutter/material.dart';


class ProvincialEngineerDashboard extends StatelessWidget {
  const ProvincialEngineerDashboard({super.key, required Map<String, dynamic> userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F2FF),
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Header Section
            const DashboardHeader(),

            // 2. User Management Grids
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.5,
                children: const <Widget>[
                  UserManagementCard(
                    title: 'Chief eng',
                    subtitle: 'Manage',
                    activeUsers: '04',
                    pendingUsers: '04',
                  ),
                  UserManagementCard(
                    title: 'District eng',
                    subtitle: 'Manage',
                    activeUsers: '10',
                    pendingUsers: '04',
                  ),
                  UserManagementCard(
                    title: 'TO',
                    subtitle: 'Manage',
                    activeUsers: '10',
                    pendingUsers: '04',
                  ),
                  UserManagementCard(
                    title: 'Principal',
                    subtitle: 'Manage',
                    activeUsers: '10',
                    pendingUsers: '04',
                  ),
                ],
              ),
            ),

            // 3. Latest Updates Section
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 8.0),
              child: Text(
                'Latest Updates',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const LatestUpdateItem(
              title: 'Thurstan Collage - Damaged Roof',
              locationStatus: 'Colombo - Status, Pending Review',
            ),
            const LatestUpdateItem(
              title: 'Christ Church Baddegama - Damaged Roof',
              locationStatus: 'Galle - Status, Pending Review',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // 4. Bottom Navigation Bar
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}



// DashboardHeader
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});
  // ... (Code as previously given) ...
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F2FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome !',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Provincial Engineer',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// UserManagementCard
class UserManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String activeUsers;
  final String pendingUsers;

  const UserManagementCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeUsers,
    required this.pendingUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.person, size: 20, color: Colors.black87),
                const SizedBox(width: 5),
                Text(
                  'Manage $title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.add_circle_outline, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a ${title.split(' ').first}:', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active Users', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(activeUsers, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pending Users', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(pendingUsers, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// LatestUpdateItem
class LatestUpdateItem extends StatelessWidget {
  final String title;
  final String locationStatus;

  const LatestUpdateItem({
    super.key,
    required this.title,
    required this.locationStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.house_outlined,
            size: 40,
            color: Colors.black87,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  locationStatus,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              // Add navigation/action logic here
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE8F2FF),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'View Details',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomBottomNavBar
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Icon(Icons.home_outlined, color: Colors.blue, size: 30),
          Icon(Icons.person, color: Colors.blue, size: 30),
          Icon(Icons.settings_outlined, color: Colors.black54, size: 30),
        ],
      ),
    );
  }
}