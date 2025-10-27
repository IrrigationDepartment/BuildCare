// dashboard.dart
import 'package:flutter/material.dart';
// manage_users.dart ගොනුවෙන් ManageUsersPage එක import කර ඇත
import 'manage_users.dart'; 

// -----------------------------------------------------------------------------
// --- Dashboard Screen (Main Dashboard) ---
// -----------------------------------------------------------------------------
class ProvincialEngineerDashboard extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const ProvincialEngineerDashboard({super.key, this.userData});

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

            // 2. User Management Grids (Clicking these navigates to ManageUsersPage)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.5,
                children: <Widget>[ 
                  UserManagementCard(
                    title: 'Chief Engineer',
                    subtitle: 'Manage',
                    activeUsers: '04',
                    pendingUsers: '04',
                  ),
                  UserManagementCard(
                    title: 'District Engineer',
                    subtitle: 'Manage',
                    activeUsers: '10',
                    pendingUsers: '04',
                  ),
                  UserManagementCard(
                    title: 'Technical Officer',
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

            // 3. User Approvals/Latest Users Section
           /* const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 8.0),
              child: Text(
                'Pending User Approvals', 
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // UserCard Widgets
            UserCard(
              userName: 'Nimal Bandara',
              userRole: 'District Engineer - Colombo',
              isApproved: false, 
            ),
            UserCard(
              userName: 'Kamani Perera',
              userRole: 'Technical Officer - Galle',
              isApproved: false, 
            ),
            UserCard(
              userName: 'Jayantha Sirisena',
              userRole: 'Principal - Kandy',
              isApproved: true, 
            ),*/
            const SizedBox(height: 20),
          ],
        ),
      ),
      // 4. Bottom Navigation Bar
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

// -----------------------------------------------------------------------------
// --- DashboardHeader (The Blue Header) ---
// -----------------------------------------------------------------------------
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

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

// -----------------------------------------------------------------------------
// --- UserManagementCard (The Grid Cards on Dashboard) ---
// -----------------------------------------------------------------------------
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
    return GestureDetector(
      onTap: () {
        String pageTitle = 'Manage $title';
        // Navigates to the ManageUsersPage (imported from manage_users.dart)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageUsersPage(
              roleTitle: pageTitle,
            ),
          ),
        );
      },
      child: Card(
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
                    'Manage ${title.split(' ').first}',
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
                  Text('Add a ${title.split(' ').first}:',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Active Users',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(activeUsers,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pending Users',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(pendingUsers,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- UserCard (Dashboard Approval List Item) ---
// -----------------------------------------------------------------------------
class UserCard extends StatelessWidget {
  final String userName;
  final String userRole;
  final bool isApproved;

  const UserCard({
    super.key,
    required this.userName,
    required this.userRole,
    required this.isApproved,
  });

  // Common navigation function for buttons
  void _navigateToBlankPage(BuildContext context, String action) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlankActionPage(
          action: action,
          target: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.account_circle, size: 40, color: Colors.blueGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isApproved ? Icons.check_circle : Icons.pending,
                    color: isApproved ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. View Button
                  _ActionButton(
                    text: 'View',
                    color: Colors.blue,
                    onPressed: () => _navigateToBlankPage(context, 'View Details'),
                  ),
                  // 2. Edit Button
                  _ActionButton(
                    text: 'Edit',
                    color: Colors.deepOrange,
                    onPressed: () => _navigateToBlankPage(context, 'Edit User'),
                  ),
                  // 3. Approve Button (Show only if not approved)
                  if (!isApproved)
                    _ActionButton(
                      text: 'Approve',
                      color: Colors.green,
                      onPressed: () => _navigateToBlankPage(context, 'Approve User'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Buttons (Used in Dashboard UserCard)
class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            elevation: 1,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// --- CustomBottomNavBar (Used in Dashboard) ---
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// --- Blank Action Page (for button clicks on Dashboard UserCard) ---
// -----------------------------------------------------------------------------
class BlankActionPage extends StatelessWidget {
  final String action;
  final String target;

  const BlankActionPage({super.key, required this.action, required this.target});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(action),
        backgroundColor: const Color(0xFFE8F2FF),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'This is the blank page for the "$action" action on user: $target.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}