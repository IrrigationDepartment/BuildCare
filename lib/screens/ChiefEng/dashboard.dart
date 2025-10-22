import 'package:flutter/material.dart';

class ChiefEngineerPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ChiefEngineerPage({super.key, required this.userData});

  @override
  State<ChiefEngineerPage> createState() => _ChiefEngineerPageStatee();
}

class _ChiefEngineerPageStatee extends State<ChiefEngineerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        shadowColor: Colors.blue.withOpacity(0.5),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            //  backgroundColor: Colors.blue.shade100,
            backgroundColor: Colors.red.shade50,

            backgroundImage: const AssetImage("assets/user_pro.png"),



            // If image doesn't load, show icon
            onBackgroundImageError: (exception, stackTrace) {},
            child: const Icon(Icons.person, color: Colors.blue),

          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              "Chief Engineer",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Section
              const Text(
                "Overview",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),

              // Overview Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFF5F5F5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewButton(
                      textName: "Total\nSchool",
                      amount: 45,
                    ),
                    _buildOverviewButton(
                      textName: "Active\nTO",
                      amount: 25,
                    ),
                    _buildOverviewButton(
                      textName: "Active\nDE",
                      amount: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Recent Activity Section
              const Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 350),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFF5F5F5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildActivityItem(
                        title: "Thurstan College - Damaged Roof",
                        subtitle: "Colombo - Status: Pending Review",
                        onViewDetails: () {
                          // Handle view details
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActivityItem(
                        title: "Royal College - Classroom Repair",
                        subtitle: "Colombo - Status: Under Review",
                        onViewDetails: () {
                          // Handle view details
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActivityItem(
                        title: "Ananda College - New Building",
                        subtitle: "Colombo - Status: Approved",
                        onViewDetails: () {
                          // Handle view details
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Approval Request Section
              const Text(
                "Approval Request",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFF5F5F5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.pending_actions,
                        size: 32,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manel Withana',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Request register as a DE.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.blue,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Quick Action Buttons
              _buildMessageBorder(
                textName: "View District Engineer Details",
                icon: Icons.engineering,
                onTap: () {
                  // Uncomment when you have the page
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => DistricEngineerDetails(),
                  //   ),
                  // );
                },
              ),
              const SizedBox(height: 12),

              _buildMessageBorder(
                textName: "View School Master Plan",
                icon: Icons.description,
                onTap: () {
                  // Uncomment when you have the page
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => ViewMasterPlanePage(),
                  //   ),
                  // );
                },
              ),
              const SizedBox(height: 12),

              _buildMessageBorder(
                textName: "View Contracts",
                icon: Icons.gavel,
                onTap: () {
                  // Uncomment when you have the page
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => ViewContarctPage(),
                  //   ),
                  // );
                },
              ),
              const SizedBox(height: 12),

              _buildMessageBorder(
                textName: "View Damage Details",
                icon: Icons.report_problem,
                onTap: () {
                  // Add your navigation here
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Overview Button Widget (CustomOverwivebutton replacement)
  Widget _buildOverviewButton({
    required String textName,
    required int amount,
  }) {
    return Container(
      width: 100,
      





      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xff9AD8FF),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            amount.toString(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            textName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Activity Item Widget
  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required VoidCallback onViewDetails,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.apartment,
              size: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onViewDetails,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'View Details',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Message Border Widget (MessageBorders replacement)
  Widget _buildMessageBorder({
    required String textName,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF5F5F5),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                textName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
