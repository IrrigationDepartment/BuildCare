import 'package:flutter/material.dart';

class ViewMasterPlanScreen extends StatelessWidget {
  const ViewMasterPlanScreen({super.key});

  static const Color kTextColor = Color(0xFF333333);
  
  // Base URL derived from your screenshot
  final String baseUrl = "https://buildcare.atigalle.x10.mx/MasterPlan/";

  // List of filenames seen in your screenshot
  final List<String> masterPlans = const [
    "Richmond College_master_699eb47b315a3.jpg",
    "sangamiththa college_master_699d78a96191b.jpg",
    "sangamiththa college_master_699e90861f178.jpg",
    "sangamiththa college_master_699eb36ce9455.jpg",
    "sangamiththa college_master_699eb3d019387.jpg",
    "Test Scl_master_699d14e974b00.png",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: masterPlans.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          masterPlans[index].split('_')[0], // Shows the School Name
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              baseUrl + masterPlans[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Text(
                                      'Could not load image. Check server permissions.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              'View Master Plans',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer to balance the back button
        ],
      ),
    );
  }
}