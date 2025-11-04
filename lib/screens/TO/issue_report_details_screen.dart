import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting the date

class IssueReportDetailsScreen extends StatefulWidget {
  final String issueId;
  const IssueReportDetailsScreen({super.key, required this.issueId});

  @override
  State<IssueReportDetailsScreen> createState() =>
      _IssueReportDetailsScreenState();
}

class _IssueReportDetailsScreenState extends State<IssueReportDetailsScreen> {
  // --- Style Constants ---
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Repair Report Details',
            style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          // The "Save" button from your design
          TextButton(
            onPressed: () {
              // TODO: Add save/update logic if this is an edit page
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('issues')
            .doc(widget.issueId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Issue details not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Format the date
          String formattedDate = 'Not specified';
          if (data['dateOfOccurance'] != null) {
            final timestamp = data['dateOfOccurance'] as Timestamp;
            formattedDate = DateFormat('yyyy/MM/dd').format(timestamp.toDate());
          }

          // Get image list
          // This list correctly comes from Firestore (which are the server URLs)
          final List<dynamic> images = data['imageUrls'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('School Name:', data['schoolName']),
                  _buildDetailRow(
                      'Select Damage Building:', data['buildingName']),
                  _buildDetailRow(
                      'Building Area (sq. ft/m²):', data['buildingArea']),
                  _buildDetailRow(
                      'Number of Floors:', data['numFloors']?.toString()),
                  _buildDetailRow('Number of Classrooms:',
                      data['numClassrooms']?.toString()),
                  _buildDetailRow('Type Of Damage:', data['damageType']),
                  _buildDetailRow('Description of Issue:', data['description']),
                  _buildDetailRow('Date Of Damage Occurance:', formattedDate),
                  const SizedBox(height: 16),
                  const Text(
                    'Uploaded Images(JPG/PNG)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // This widget now correctly displays the server images
                  _buildImageGallery(images),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper to build the image gallery (MODIFIED) ---
  Widget _buildImageGallery(List<dynamic> images) {
    if (images.isEmpty) {
      return const Text('No images uploaded.',
          style: TextStyle(color: kSubTextColor));
    }
    
    // --- MODIFICATION: Wrapped the Row in a fixed-height SizedBox
    // and a SingleChildScrollView to allow horizontal scrolling ---
    return SizedBox(
      height: 100, // Give the gallery a fixed height
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: images.map((imageUrl) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl.toString(), // This is the server URL
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  // Loading and error builders for a better UX
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
    // --- END MODIFICATION ---
  }

  // --- Helper to build styled detail rows (Unchanged) ---
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // Fixed width for labels
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 15,
                color: kSubTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}