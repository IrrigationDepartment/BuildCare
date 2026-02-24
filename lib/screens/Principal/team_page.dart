import 'package:flutter/material.dart';

class TeamMember {
  final String name;
  final String role;
  final String bio;
  final String imageUrl;
  final bool isLeader;

  TeamMember({
    required this.name,
    required this.role,
    required this.bio,
    required this.imageUrl,
    this.isLeader = false,
  });
}

class DeveloperTeamPage extends StatelessWidget {
  const DeveloperTeamPage({super.key});

  // --- Mock Data for the Team ---
  static final List<TeamMember> _team = [
    TeamMember(
      name: "Vihanga Manodhya",
      role: "Lead Developer / Team Leader",
      bio:
          "Visionary technical leader specializing in Flutter, scalable architecture, and guiding the team to deliver high-quality, impactful software solutions.",
      imageUrl:
          "https://ui-avatars.com/api/?name=Vihanga+Manodhya&background=0D8ABC&color=fff&size=256",
      isLeader: true,
    ),
    TeamMember(
      name: "Pabasara Bhakthi",
      role: "Frontend Developer",
      bio:
          "Front End Developer.",
      imageUrl:
          "https://ui-avatars.com/api/?name=Sarah+Jenkins&background=random&color=fff&size=256",
    ),
    TeamMember(
      name: "Sithumini Devindi",
      role: "Backend Developer",
      bio:
          "Front End Developer.",
      imageUrl:
          "https://ui-avatars.com/api/?name=Marcus+Chen&background=random&color=fff&size=256",
    ),
    TeamMember(
      name: "Yashodara Rashmi",
      role: "UI/UX Designer",
      bio:
          "Front End Developer.",
      imageUrl:
          "https://ui-avatars.com/api/?name=Elena+Rodriguez&background=random&color=fff&size=256",
    ),
    TeamMember(
      name: "Devmi Sahithya",
      role: "QA Engineer & DevOps",
      bio:
          "Front End Developer.",
      imageUrl:
          "https://ui-avatars.com/api/?name=David+Smith&background=random&color=fff&size=256",
    ),
  ];

  static const Color kPrimaryBlue = Color(0xFF1877F2);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    // Separate leader from the rest of the team
    final TeamMember leader = _team.firstWhere((m) => m.isLeader);
    final List<TeamMember> members = _team.where((m) => !m.isLeader).toList();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Meet Our Developers',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine grid columns based on screen width
            int crossAxisCount = 1;
            if (constraints.maxWidth > 1000) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 2;
            }

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Page Header
                      const Text(
                        "The Brains Behind the Code",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2C3E50),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "A dedicated team of professionals working together to bring ideas to life.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // --- 1. HIGHLIGHTED TEAM LEADER ---
                      _buildLeaderCard(leader, constraints.maxWidth),

                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 30),

                      // --- 2. OTHER TEAM MEMBERS GRID ---
                      const Text(
                        "Core Development Team",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.8, // Adjust for card height
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          return _buildMemberCard(members[index]);
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // WIDGET: HIGHLIGHTED LEADER CARD
  // =========================================================
  Widget _buildLeaderCard(TeamMember leader, double screenWidth) {
    bool isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBlue.withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryBlue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          // Leader Avatar with Gold Crown Ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gold
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: CircleAvatar(
              radius: isMobile ? 60 : 70,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: isMobile ? 56 : 66,
                backgroundImage: NetworkImage(leader.imageUrl),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 0 : 32, height: isMobile ? 24 : 0),

          // Leader Details
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              crossAxisAlignment: isMobile
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                // Highlight Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "TEAM LEADER",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange.shade800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  leader.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                ),
                const SizedBox(height: 4),

                // Role
                Text(
                  leader.role,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryBlue,
                  ),
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                ),
                const SizedBox(height: 16),

                // Bio
                Text(
                  leader.bio,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                ),

                const SizedBox(height: 20),

                // Social Icons (Placeholder)
                Row(
                  mainAxisAlignment: isMobile
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    _buildSocialIcon(Icons.link),
                    const SizedBox(width: 12),
                    _buildSocialIcon(Icons.code),
                    const SizedBox(width: 12),
                    _buildSocialIcon(Icons.email_outlined),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // =========================================================
  // WIDGET: STANDARD TEAM MEMBER CARD
  // =========================================================
  Widget _buildMemberCard(TeamMember member) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 45,
            backgroundColor: kPrimaryBlue.withOpacity(0.1),
            child: CircleAvatar(
              radius: 42,
              backgroundImage: NetworkImage(member.imageUrl),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Role
          Text(
            member.role,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimaryBlue.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Bio
          Expanded(
            child: Text(
              member.bio,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Small helper for social icons
  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: Colors.blueGrey),
    );
  }
}
