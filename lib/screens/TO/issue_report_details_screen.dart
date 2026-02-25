import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_issue_screen.dart'; 

class IssueReportDetailsScreen extends StatefulWidget {
  final String issueId;
  final String userNic; 
  const IssueReportDetailsScreen({
    super.key,
    required this.issueId,
    required this.userNic, 
  });

  @override
  State<IssueReportDetailsScreen> createState() =>
      _IssueReportDetailsScreenState();
}

class _IssueReportDetailsScreenState extends State<IssueReportDetailsScreen> {
  // --- EYE-CATCHING MODERN COLOR PALETTE ---
  static const Color kPrimaryColor = Color(0xFF4F46E5); 
  static const Color kPrimaryDark = Color(0xFF312E81); 
  static const Color kBackgroundColor = Color(0xFFF8FAFC); 
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF1E293B); 
  static const Color kSubTextColor = Color(0xFF64748B); 
  static const Color kAccentColor = Color(0xFFEC4899); 

  bool _isPageLoading = true;
  Map<String, dynamic>? _issueData;
  String _formattedDate = 'N/A';
  List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    _fetchIssueDetails();
  }

  Future<void> _fetchIssueDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .get();

      if (doc.exists) {
        _issueData = doc.data() as Map<String, dynamic>;

        if (_issueData!['dateOfOccurance'] != null) {
          final DateTime selectedDate =
              (_issueData!['dateOfOccurance'] as Timestamp).toDate();
          _formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);
        }
        _images = _issueData!['imageUrls'] ?? [];

        setState(() {
          _isPageLoading = false;
        });
      } else {
        setState(() => _isPageLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Issue details not found.'), backgroundColor: Colors.redAccent),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isPageLoading = false);
    }
  }

  Color _getStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in progress': return Colors.blue.shade50;
      case 'pending': return Colors.amber.shade50;
      case 'resolved': return Colors.green.shade50;
      default: return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in progress': return Colors.blue.shade700;
      case 'pending': return Colors.amber.shade700;
      case 'resolved': return Colors.green.shade700;
      default: return Colors.grey.shade700;
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
                    setState(() => _isPageLoading = true);
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
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        const Text('Photographic Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)),
                        const SizedBox(height: 12),
                        _buildImageGallery(_images),
                        const SizedBox(height: 32),
                        _buildSectionCard(
                          title: 'Issue Details',
                          icon: Icons.info_outline_rounded,
                          children: [
                            _buildDetailRow(icon: Icons.category_rounded, label: 'Type of Damage', value: _issueData!['damageType'] ?? 'N/A'),
                            const Divider(height: 24),
                            _buildDetailRow(icon: Icons.calendar_today_rounded, label: 'Date of Occurance', value: _formattedDate),
                          ],
                        ),
                        _buildSectionCard(
                          title: 'Description',
                          icon: Icons.description_rounded,
                          children: [
                            Text(_issueData!['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 15, color: kTextColor, height: 1.5)),
                          ],
                        ),

                        // --- NEW: REVIEWS / REPORTS SUB-COLLECTION SECTION ---
                        _buildReviewsSection(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(_issueData!['issueTitle'] ?? 'Untitled Issue',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextColor)),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: _getStatusBgColor(_issueData!['status']),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusTextColor(_issueData!['status']).withOpacity(0.2))),
          child: Text((_issueData!['status'] ?? 'Unknown').toUpperCase(),
              style: TextStyle(color: _getStatusTextColor(_issueData!['status']), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  // --- PROGRESS REVIEWS LOGIC ---
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Progress Updates & Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          // Fetching from the sub-collection 'reviews'
          stream: FirebaseFirestore.instance
              .collection('issues')
              .doc(widget.issueId)
              .collection('reviews')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // If you see the "Index Required" error from your screenshot, 
              // click the link in your console to create the composite index.
              return Text('Error loading reports: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reviews = snapshot.data?.docs ?? [];

            if (reviews.isEmpty) {
              return _buildSectionCard(
                title: 'No Updates Yet',
                icon: Icons.history,
                children: [const Text('No repair progress reports have been submitted for this issue.', style: TextStyle(color: kSubTextColor))],
              );
            }

            return Column(
              children: reviews.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                DateTime? date;
                if (data['timestamp'] != null) {
                   date = (data['timestamp'] as Timestamp).toDate();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: kPrimaryColor.withOpacity(0.05))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(radius: 12, backgroundColor: kPrimaryColor, child: Icon(Icons.person, size: 14, color: Colors.white)),
                              const SizedBox(width: 8),
                              Text(data['reviewerNic'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          if (date != null)
                            Text(DateFormat('MMM dd, hh:mm a').format(date), style: const TextStyle(color: kSubTextColor, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(data['reviewText'] ?? '', style: const TextStyle(fontSize: 14, color: kTextColor, height: 1.4)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: kPrimaryColor, size: 22), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextColor))]),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: kPrimaryColor, size: 18)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 13, color: kSubTextColor)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])),
      ],
    );
  }

  Widget _buildImageGallery(List<dynamic> images) {
    if (images.isEmpty) return const Text('No images provided');
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imageUrl = images[index].toString();
          return Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(imageUrl, width: 140, height: 140, fit: BoxFit.cover)),
          );
        },
      ),
    );
  }
}