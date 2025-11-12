
//
// 📁 FILENAME: dashboard_service.dart
//
import 'package:cloud_firestore/cloud_firestore.dart';

// A class to hold the fetched data counts
class DashboardCounts {
  final int totalSchools;
  final int activeTOs;
  final int pendingRequests;

  DashboardCounts({
    required this.totalSchools,
    required this.activeTOs,
    required this.pendingRequests,
  });
}

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // This method fetches all counts and returns them in a single object
  Future<DashboardCounts> fetchOverviewCounts() async {
    try {
      // 1. Total Schools Count
      final schoolsSnapshot = await _db.collection('schools').get();
      
      // 2. Active TOs Count
      final tosSnapshot = await _db
          .collection('users')
          .where('userType', isEqualTo: 'Technical Officer')
          .where('status', isEqualTo: 'active')
          .get();
          
      // 3. Pending Approvals Count
      final pendingSnapshot = await _db
          .collection('approvals')
          .where('status', isEqualTo: 'pending')
          .get();

      // Return all counts in one object
      return DashboardCounts(
        totalSchools: schoolsSnapshot.docs.length,
        activeTOs: tosSnapshot.docs.length,
        pendingRequests: pendingSnapshot.docs.length,
      );
      
    } catch (e) {
      // Log the error and re-throw it so the UI can handle it
      print("Error fetching overview counts: $e");
      throw Exception('Failed to load dashboard data: $e');
    }
  }
}