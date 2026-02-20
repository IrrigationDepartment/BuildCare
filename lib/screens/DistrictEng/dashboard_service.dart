<<<<<<< HEAD

//  FILENAME: dashboard_service.dart

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
=======
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardCounts {
  final int totalSchools;
  final int totalTOs; 
  final int totalPrincipals; 

  DashboardCounts({
    required this.totalSchools,
    required this.totalTOs,
    required this.totalPrincipals,
>>>>>>> main
  });
}

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

<<<<<<< HEAD
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
=======
  Future<DashboardCounts> fetchOverviewCounts() async {
    try {
      final schoolsSnapshot = await _db.collection('schools').get();

      final tosSnapshot = await _db
          .collection('users')
          .where('userType', isEqualTo: 'Technical Officer')
          .get();

      final principalsSnapshot = await _db
          .collection('users')
          .where('userType', isEqualTo: 'Principal')
          .get();

      return DashboardCounts(
        totalSchools: schoolsSnapshot.docs.length,
        totalTOs: tosSnapshot.docs.length,
        totalPrincipals: principalsSnapshot.docs.length,
      );
      
    } catch (e) {
>>>>>>> main
      print("Error fetching overview counts: $e");
      throw Exception('Failed to load dashboard data: $e');
    }
  }
}