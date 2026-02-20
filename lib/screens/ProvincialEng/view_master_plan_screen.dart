import 'package:flutter/material.dart';
<<<<<<< HEAD

class ViewMasterPlanScreen extends StatelessWidget {
  const ViewMasterPlanScreen({super.key});

  static const Color kTextColor = Color(0xFF333333);
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewMasterPlanScreen extends StatelessWidget {
  final String schoolName; // SchoolDetailsPage වෙතින් ලැබෙන පාසලේ නම

  const ViewMasterPlanScreen({
    super.key,
    required this.schoolName,
  });

  static const Color kTextColor = Color(0xFF333333);
  static const Color kPrimaryBlue = Color(0xFF42A5F5);
>>>>>>> main

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.white, // Or a background color matching your app
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child:
                          //
                          Image.asset(
                        'assets/master_plan.jpg', // **REPLACE WITH YOUR IMAGE PATH**
                        fit: BoxFit.contain, // Adjust as needed
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'Master plan image not found.\nPlease add "assets/master_plan.jpg" to your pubspec.yaml and project.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
=======
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Master Plan - $schoolName',
          style: const TextStyle(color: kTextColor, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          // schoolMasterPlans collection එකේ schoolName එකට සමාන document එකක් සෙවීම
          future: FirebaseFirestore.instance
              .collection('schoolMasterPlans')
              .where('schoolName', isEqualTo: schoolName)
              .limit(1)
              .get(),
          builder: (context, snapshot) {
            // 1. Data load වන තෙක් බලා සිටීම
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: kPrimaryBlue),
              );
            }

            // 2. Error එකක් ආවොත් පෙන්වීම
            if (snapshot.hasError) {
              return _buildErrorWidget("Error loading master plan.");
            }

            // 3. Document එකක් හමු නොවුණහොත් පෙන්වීම
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildErrorWidget("No Master Plan found for this school.");
            }

            // 4. දත්ත සාර්ථකව ලැබුණු විට URL එක ලබා ගැනීම
            final planData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final String? imageUrl = planData['masterPlanUrl'];

            if (imageUrl == null || imageUrl.isEmpty) {
              return _buildErrorWidget("Master plan image URL is missing.");
            }

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            // Image එක load වන අතරතුර පෙන්වන Placeholder එක
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            // URL එකේ දෝෂයක් ඇත්නම් පෙන්වන Widget එක
                            errorWidget: (context, url, error) => const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text("Failed to load image"),
                              ],
                            ),
                          ),
                        ),
>>>>>>> main
                      ),
                    ),
                  ),
                ),
<<<<<<< HEAD
              ),
            ),
          ],
=======
                // පහළින් ඇති විස්තර (Optional)
                _buildInfoSection(planData),
              ],
            );
          },
>>>>>>> main
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'View Master Plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kTextColor), // 'x' icon
            onPressed: () => Navigator.of(context).pop(),
=======
  // දෝෂ පණිවිඩ පෙන්වීමට භාවිතා කරන Widget එක
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
>>>>>>> main
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
}
=======

  // රූපයට පහළින් ඇති අමතර තොරතුරු පෙන්වීමට (උදා: Uploaded Date)
  Widget _buildInfoSection(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            "This is the official master plan for $schoolName.",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
>>>>>>> main
