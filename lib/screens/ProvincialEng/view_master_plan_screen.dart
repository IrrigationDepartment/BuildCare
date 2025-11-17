import 'package:flutter/material.dart';

class ViewMasterPlanScreen extends StatelessWidget {
  const ViewMasterPlanScreen({super.key});

  static const Color kTextColor = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      ),
                    ),
                  ),
                ),
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
          ),
        ],
      ),
    );
  }
}
