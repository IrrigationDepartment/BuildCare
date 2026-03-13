import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_issue_screen.dart'; // <-- IMPORT AddIssueScreen
import 'package:cached_network_image/cached_network_image.dart'; // Add this at the top

class IssueReportDetailsScreen extends StatefulWidget {
  final String issueId;
  final String userNic; // <-- ADDED
  const IssueReportDetailsScreen({
    super.key,
    required this.issueId,
    required this.userNic, // <-- ADDED
  });

  @override
  State<IssueReportDetailsScreen> createState() =>
      _IssueReportDetailsScreenState();
}

class _IssueReportDetailsScreenState extends State<IssueReportDetailsScreen> {
  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color kPrimaryDark = Color(0xFF312E81); // Indigo 900
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); // Slate 800
  static const Color kSubTextColor = Color(0xFF64748B); // Slate 500
  static const Color kAccentColor = Color(0xFFEC4899); // Pink 500

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
          .doc(widget.issueId)
          .get();

      if (doc.exists) {
        _issueData = doc.data() as Map<String, dynamic>;

        // Handle date
        if (_issueData!['dateOfOccurance'] != null) {
          final DateTime selectedDate =
              (_issueData!['dateOfOccurance'] as Timestamp).toDate();
          _formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);
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
                content: Text('Issue details not found.'),
                backgroundColor: Colors.redAccent),
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
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // --- Dynamic Status Badge Colors ---
  Color _getStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in progress':
      case 'processing':
        return Colors.blue.shade50;
      case 'pending':
        return Colors.amber.shade50;
      case 'resolved':
      case 'completed':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in progress':
      case 'processing':
        return Colors.blue.shade700;
      case 'pending':
        return Colors.amber.shade700;
      case 'resolved':
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Repair Report Details',
            style: TextStyle(color: kTextColor, fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Edit Button Container
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_rounded, color: kAccentColor, size: 20),
                tooltip: 'Edit Report',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddIssueScreen(
                        userNic: widget.userNic,
                        issueId: widget.issueId,
                      ),
                    ),
                  ).then((value) {
                    // Refresh data if we return from edit screen
                    setState(() {
                      _isPageLoading = true;
                    });
                    _fetchIssueDetails();
                  });
                },
              ),
            ),
          )
        ],
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _issueData == null
              ? const Center(child: Text('Issue not found.', style: TextStyle(color: kSubTextColor)))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    // RESPONSIVE WRAPPER
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- HEADER / TITLE SECTION ---
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _issueData!['issueTitle'] ?? 'Untitled Issue',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: kTextColor,
                                      height: 1.2
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // STATUS BADGE
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusBgColor(_issueData!['status']),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _getStatusTextColor(_issueData!['status']).withOpacity(0.2))
                                  ),
                                  child: Text(
                                    (_issueData!['status'] ?? 'Unknown').toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusTextColor(_issueData!['status']),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.5
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // --- SECTION 1: IMAGES ---
                            const Text(
                              'Photographic Evidence',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kTextColor,
                                letterSpacing: -0.5
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildImageGallery(_images),
                            const SizedBox(height: 32),

                            // --- SECTION 2: ISSUE DETAILS CARD ---
                            _buildSectionCard(
                              title: 'Issue Details',
                              icon: Icons.info_outline_rounded,
                              children: [
                                _buildDetailRow(
                                  icon: Icons.category_rounded,
                                  label: 'Type of Damage',
                                  value: _issueData!['damageType'] ?? 'N/A',
                                ),
                                const Divider(height: 24, color: Colors.black12),
                                _buildDetailRow(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Date of Occurance',
                                  value: _formattedDate,
                                ),
                              ],
                            ),

                            // --- SECTION 3: DESCRIPTION CARD ---
                            _buildSectionCard(
                              title: 'Description',
                              icon: Icons.description_rounded,
                              children: [
                                Text(
                                  _issueData!['description'] ??
                                      'No description provided for this issue.',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: kTextColor,
                                      height: 1.5),
                                ),
                              ],
                            ),

                            // --- SECTION 4: LOCATION CARD ---
                            _buildSectionCard(
                              title: 'Location & Structure',
                              icon: Icons.location_on_rounded,
                              children: [
                                _buildDetailRow(
                                  icon: Icons.school_rounded,
                                  label: 'School',
                                  value: _issueData!['schoolName'] ?? 'N/A',
                                ),
                                const Divider(height: 24, color: Colors.black12),
                                _buildDetailRow(
                                  icon: Icons.meeting_room_rounded,
                                  label: 'Building',
                                  value: _issueData!['buildingName'] ?? 'N/A',
                                ),
                                const Divider(height: 24, color: Colors.black12),
                                _buildDetailRow(
                                  icon: Icons.square_foot_rounded,
                                  label: 'Building Area',
                                  value: _issueData!['buildingArea'] ?? 'N/A',
                                ),
                                const Divider(height: 24, color: Colors.black12),
                                _buildDetailRow(
                                  icon: Icons.layers_rounded,
                                  label: 'Total Floors',
                                  value: _issueData!['numFloors']?.toString() ?? 'N/A',
                                ),
                                const Divider(height: 24, color: Colors.black12),
                                _buildDetailRow(
                                  icon: Icons.chair_alt_rounded,
                                  label: 'Total Classrooms',
                                  value: _issueData!['numClassrooms']?.toString() ?? 'N/A',
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  // --- NEW: Helper to build section cards with icons ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kPrimaryColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kTextColor,
                    letterSpacing: -0.5
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children, 
          ],
        ),
      ),
    );
  }

  // --- NEW: Helper for Icon | Label | Value rows ---
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)
          ),
          child: Icon(icon, color: kPrimaryColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: kSubTextColor, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- IMAGE GALLERY WIDGETS ---
  Widget _buildImageGallery(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade300, size: 40),
            const SizedBox(height: 8),
            const Text('No images provided', style: TextStyle(color: kSubTextColor, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imageUrl = images[index].toString();
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _buildImageZoomScreen(imageUrl),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Hero(
                tag: imageUrl,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.network(
                    imageUrl,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 30),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }
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
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 50),
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