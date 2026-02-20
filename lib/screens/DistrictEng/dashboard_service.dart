import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardCounts {
  final int totalSchools;
  final int totalTOs; 
  final int totalPrincipals; 

  DashboardCounts({
    required this.totalSchools,
    required this.totalTOs,
    required this.totalPrincipals,
  });
}

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      print("Error fetching overview counts: $e");
      throw Exception('Failed to load dashboard data: $e');
    }
  }
}