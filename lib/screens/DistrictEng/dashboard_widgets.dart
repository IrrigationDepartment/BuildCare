
//  FILENAME: dashboard_widgets.dart

import 'package:flutter/material.dart';

// Import the pages you need to navigate to
import 'manage_to_page.dart';
import 'manage_principals_page.dart';
import 'manage_schools_page.dart';
import 'pending_approvals_page.dart';

// --- MAIN WIDGETS ---

// This was _buildHeader
class DashboardHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DashboardHeader({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final userName = userData['name'] ?? 'User';
    final userType = userData['userType'] ?? 'District Engineer';

    return DashboardCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $userName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userType,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// This was _buildOverviewSection
class DashboardOverview extends StatelessWidget {
  final bool isLoading;
  final int totalSchools;
  final int activeTOs;
  final int pendingRequests;

  const DashboardOverview({
    super.key,
    required this.isLoading,
    required this.totalSchools,
    required this.activeTOs,
    required this.pendingRequests,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const DashboardCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _OverviewCard(
                  'Total Schools', totalSchools.toString()),
              _OverviewCard('Active TOs', activeTOs.toString()),
              _OverviewCard('Pending', pendingRequests.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ManageButton('Manage Schools'),
              _ManageButton('Manage TOs'),
              _ManageButton('Manage Principals'),
            ],
          ),
        ],
      ),
    );
  }
}

// This was _buildRecentActivitySection
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with a StreamBuilder or FutureBuilder from Firestore
    return DashboardCard(
      child: Column(
        children: [
          _ActivityItem('Thurstan College - Damaged Roof',
              'Colombo - Status, Pending Review'),
          const Divider(),
          _ActivityItem('Royal College - New Building',
              'Colombo - Status, Approved'),
        ],
      ),
    );
  }
}

// This was _buildApprovalRequestSection
class ApprovalRequestSection extends StatelessWidget {
  const ApprovalRequestSection({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with a StreamBuilder or FutureBuilder from Firestore
    return DashboardCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text('• Manel Withana requested to register as a TO.'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingApprovalsPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade300,
              foregroundColor: Colors.white,
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS (Used only within this file) ---

// This was _buildCard
class DashboardCard extends StatelessWidget {
  final Widget child;
  const DashboardCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }
}

// This was _buildSectionTitle
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// This was _buildOverviewCard
class _OverviewCard extends StatelessWidget {
  final String title;
  final String count;
  const _OverviewCard(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// This was _buildManageButton
class _ManageButton extends StatelessWidget {
  final String label;
  const _ManageButton(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            if (label == 'Manage Schools') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageSchoolsPage(),
                ),
              );
            } else if (label == 'Manage TOs') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageTechnicalOfficersPage(),
                ),
              );
            } else if (label == 'Manage Principals') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManagePrincipalsPage(),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ),
      ),
    );
  }
}

// This was _buildActivityItem
class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ActivityItem(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined, color: Colors.teal, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
}