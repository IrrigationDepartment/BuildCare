import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DamageDetailsDialog extends StatefulWidget {
  final String issueId;
  const DamageDetailsDialog({super.key, required this.issueId});

  @override
  State<DamageDetailsDialog> createState() => _DamageDetailsDialogState();
}

class _DamageDetailsDialogState extends State<DamageDetailsDialog> {
  // --- Style Constants ---
  static const Color kBackgroundColor = Color(0xFFF5F7FA);
  static const Color kTextColor = Color(0xFF333333);
  static const Color kSubTextColor = Color(0xFF757575);
  static const Color kCardColor = Colors.white;
  static const Color kIconColor = Color(0xFF9E9E9E);

  // --- State Variables ---
  bool _isPageLoading = true;
  Map<String, dynamic>? _issueData;
  String _formattedDate = 'N/A';
  List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    _fetchIssueDetails();
  }

  // --- Data Fetching ---
  Future<void> _fetchIssueDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('issues') 
          .collection('issues') // Assuming the collection name remains 'issues'
          .doc(widget.issueId)
          .get();

      if (doc.exists) {
        _issueData = doc.data() as Map<String, dynamic>;

        // Handle date
        if (_issueData!['dateOfOccurance'] != null) {
          final DateTime selectedDate =
              (_issueData!['dateOfOccurance'] as Timestamp).toDate();
          _formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
        }

        // Load images
        _images = _issueData!['imageUrls'] ?? [];

        setState(() {
          _isPageLoading = false;
        });
      } else {
        // Handle document not found
        setState(() {
          _isPageLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Damage report details not found.'),
                backgroundColor: Colors.red),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Handle error
      setState(() {
        _isPageLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error fetching details: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Damage Details',
        title: const Text('Damage Details', // Updated title
            style: TextStyle(color: kTextColor)),
        backgroundColor: kCardColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        // OPTIONAL: Add an "Edit" button to navigate to your editing screen
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Report',
            onPressed: () {
              // TODO: Navigate to an editable screen for the report
              // For a full-screen implementation of 'DamageDetailsDialog', this might push to itself or an edit form.
              // Example:
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => EditDamageReportScreen(issueId: widget.issueId),
              //   ),
              // );
            },
          )
        ],
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : _issueData == null
              ? const Center(child: Text('Damage report not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SECTION 1: IMAGES ---
                      const Text(
                        'Uploaded Images',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildImageGallery(_images),
                      const SizedBox(height: 24),

                      // --- SECTION 2: ISSUE DETAILS CARD ---
                      _buildSectionCard(
                        title: 'Damage Details',
                        title: 'Damage Details', // Updated title
                        children: [
                          _buildDetailRow(
                            icon: Icons.category_outlined,
                            label: 'Type of Damage',
                            value: _issueData!['damageType'] ?? 'N/A',
                          ),
                          _buildDetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date of Occurance',
                            value: _formattedDate,
                          ),
                        ],
                      ),

                      // --- SECTION 3: DESCRIPTION CARD ---
                      _buildSectionCard(
                        title: 'Description',
                        children: [
                          Text(
                            _issueData!['description'] ??
                                'No description provided.',
                            style: const TextStyle(
                                fontSize: 15,
                                color: kSubTextColor,
                                height: 1.4),
                          ),
                        ],
                      ),

                      // --- SECTION 4: BUILDING SPECS CARD ---
                      _buildSectionCard(
                        title: 'Building Specifications',
                        children: [
                          _buildDetailRow(
                            icon: Icons.square_foot_outlined,
                            label: 'Building Area',
                            value: _issueData!['buildingArea'] ?? 'N/A',
                          ),
                          _buildDetailRow(
                            icon: Icons.layers_outlined,
                            label: 'Number of Floors',
                            value:
                                _issueData!['numFloors']?.toString() ?? 'N/A',
                          ),
                          _buildDetailRow(
                            icon: Icons.chair_outlined,
                            label: 'Number of Classrooms',
                            value: _issueData!['numClassrooms']?.toString() ??
                                'N/A',
                          ),
                        ],
                      ),

                      // --- SECTION 5: LOCATION CARD ---
                      _buildSectionCard(
                        title: 'Location',
                        children: [
                          _buildLocationRow(
                            label: 'School',
                            value: _issueData!['schoolName'] ?? 'N/A',
                          ),
                          _buildLocationRow(
                            label: 'Building',
                            value: _issueData!['buildingName'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  //  HELPER WIDGETS FOR VIEW SCREEN 

  // Helper to build section cards
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      color: kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Divider(color: kBackgroundColor.withOpacity(0.8)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

            ...children, // Add all the child widgets
          ],
        ),
      ),
    );
  }

  //  Helper for Icon | Label | Value rows  
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kIconColor, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: kSubTextColor),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  //  Helper for Label: Value rows  
  Widget _buildLocationRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 15,
              color: kSubTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }

  //  IMAGE GALLERY WIDGETS (Unchanged from previous) 
 
  Widget _buildImageGallery(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Center(
          child: Text('No images uploaded.',
              style: TextStyle(color: kSubTextColor)),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: images.map((imageUrl) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        _buildImageZoomScreen(imageUrl.toString()),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Hero(
                  tag: imageUrl.toString(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      imageUrl.toString(),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildImageZoomScreen(String imageUrl) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child:
                        Icon(Icons.broken_image, color: Colors.grey, size: 50),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}