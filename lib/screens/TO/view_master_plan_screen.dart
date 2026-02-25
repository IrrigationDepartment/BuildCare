import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewMasterPlanScreen extends StatelessWidget {
  final String schoolName;

  const ViewMasterPlanScreen({super.key, required this.schoolName});

  static const Color kPrimaryColor = Color(0xFF4F46E5);
  static const Color kBackgroundColor = Color(0xFFF8FAFC);
  static const Color kTextColor = Color(0xFF1E293B);
  static const Color kSubTextColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final String cleanSchoolName = schoolName.trim();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "All Master Plans: $cleanSchoolName",
          style: const TextStyle(color: kTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          // STEP 1: We removed .orderBy() here. 
          // This query ONLY filters by name, which does NOT require a composite index.
          stream: FirebaseFirestore.instance
              .collection('schoolMasterPlans')
              .where('schoolName', isEqualTo: cleanSchoolName)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            // STEP 2: Sort the data MANUALLY in Dart to avoid the Index Error.
            List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
            docs.sort((a, b) {
              Timestamp t1 = (a.data() as Map<String, dynamic>)['createdAt'] ?? Timestamp.now();
              Timestamp t2 = (b.data() as Map<String, dynamic>)['createdAt'] ?? Timestamp.now();
              return t2.compareTo(t1); // Descending order (Newest first)
            });

            return LayoutBuilder(
              builder: (context, constraints) {
                int columns = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildPlanCard(context, data);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Map<String, dynamic> data) {
    final String url = data['masterPlanUrl'] ?? "";
    final String desc = data['description'] ?? "No description";
    final String date = data['uploadDate'] ?? "N/A";
    final String time = data['uploadTime'] ?? "";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: GestureDetector(
                onTap: () => _viewFullScreen(context, url, desc),
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: kSubTextColor),
                        const SizedBox(width: 4),
                        Text(date, style: const TextStyle(fontSize: 12, color: kSubTextColor)),
                      ],
                    ),
                    Text(time, style: const TextStyle(fontSize: 12, color: kSubTextColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewFullScreen(BuildContext context, String url, String title) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), title: Text(title)),
      body: Center(child: InteractiveViewer(child: Image.network(url))),
    )));
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No master plans found.", style: TextStyle(color: kSubTextColor)));
  }
}