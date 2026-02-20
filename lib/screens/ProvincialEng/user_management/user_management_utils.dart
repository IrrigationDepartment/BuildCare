import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagementUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> getUserCounts(String userType) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: userType)
          .get();

      int total = querySnapshot.docs.length;
      int active = querySnapshot.docs
          .where((doc) => (doc.data()['isActive'] ?? false) == true)
          .length;
      int inactive = total - active;

      return {
        'total': total,
        'active': active,
        'inactive': inactive,
      };
    } catch (e) {
      debugPrint('Error getting user counts: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  static Color getUserTypeColor(String userType) {
    switch (userType) {
      case 'Chief Engineer':
        return Colors.blue;
      case 'District Engineer':
        return Colors.green;
      case 'Technical Officer':
        return Colors.orange;
      case 'Principal':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static IconData getUserTypeIcon(String userType) {
    switch (userType) {
      case 'Chief Engineer':
        return Icons.person_pin;
      case 'District Engineer':
        return Icons.engineering;
      case 'Technical Officer':
        return Icons.build;
      case 'Principal':
        return Icons.school;
      default:
        return Icons.person;
    }
  }
}