// lib/models/school.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class School {
  final String id; // Document ID from Firestore
  final String name;
  final String address;
  final String phoneNumber;
  final String type;
  final String zone;
  final int students;
  final int teachers;
  final int nonAcademicStaff;
  final int infrastructureComponents;

  // --- Original "valuable details" ---
  final Timestamp? addedAt;
  final String? addedByNic;
  final bool isActive;

  // --- NEW: Edit tracking details ---
  final Timestamp? lastEditedAt;
  final String? lastEditedByNic;

  School({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.type,
    required this.zone,
    required this.students,
    required this.teachers,
    required this.nonAcademicStaff,
    required this.infrastructureComponents,
    this.addedAt,
    this.addedByNic,
    this.isActive = false,
    this.lastEditedAt,
    this.lastEditedByNic,
  });

  // Factory constructor to create a School from a Firestore document
  factory School.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Calculate infrastructure components
    int infraCount = 0;
    if (data['infrastructure'] is Map) {
      (data['infrastructure'] as Map).forEach((key, value) {
        if (value == true) {
          infraCount++;
        }
      });
    }

    return School(
      id: doc.id,
      name: data['schoolName'] ?? 'No Name',
      address: data['schoolAddress'] ?? 'No Address',
      phoneNumber: data['schoolPhone'] ?? 'No Phone',
      type: data['schoolType'] ?? 'N/A',
      zone: data['educationalZone'] ?? 'N/A',
      students: data['numStudents'] ?? 0,
      teachers: data['numTeachers'] ?? 0,
      nonAcademicStaff: data['numNonAcademic'] ?? 0,
      infrastructureComponents: infraCount,
      addedAt: data['addedAt'] as Timestamp?,
      addedByNic: data['addedByNic'] ?? 'Unknown',
      isActive: data['isActive'] ?? false,
      lastEditedAt: data['lastEditedAt'] as Timestamp?,
      lastEditedByNic: data['lastEditedByNic'] as String?,
    );
  }

  // Helper to format the addedAt timestamp
  String get formattedAddedAt {
    if (addedAt == null) return 'N/A';
    return DateFormat('MMM d, yyyy \@ h:mm a').format(addedAt!.toDate());
  }

  // Helper to format the lastEditedAt timestamp
  String get formattedLastEditedAt {
    if (lastEditedAt == null) return 'N/A';
    return DateFormat('MMM d, yyyy \@ h:mm a').format(lastEditedAt!.toDate());
  }
}
