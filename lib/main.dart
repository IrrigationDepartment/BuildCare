import 'package:buildcare/screens/ChiefEng/dashboard.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'login.dart'; // Import the login screen
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore operations
import 'package:http/http.dart' as http; // Added to make requests to your custom PHP server
import 'firebase_options.dart'; // Import the generated Firebase options

// --- Main function updated to initialize Firebase ---
void main() async {
  // Ensure that Flutter bindings are initialized before calling Firebase.initializeApp
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase using the generated options file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Run the app first so the user doesn't wait
  runApp(const MyApp());
  
  // Run the image cleanup process in the background silently
  _runImageCleanupProcess();
}

// --- Background Image Cleanup Logic ---
Future<void> _runImageCleanupProcess() async {
  try {
    final firestore = FirebaseFirestore.instance;
    // Get all issues that actually have images
    final issuesSnapshot = await firestore
        .collection('issues')
        .where('imageUrls', isNotEqualTo: [])
        .get();

    final now = DateTime.now();

    for (var doc in issuesSnapshot.docs) {
      final data = doc.data();
      
      // Calculate date: Prioritize updatedAt, then fallback to added date (timestamp/dateOfOccurance)
      Timestamp? referenceTimestamp = data['updatedAt'] ?? data['timestamp'] ?? data['dateOfOccurance'];
      
      if (referenceTimestamp == null) continue; // Skip if no date found
      
      final referenceDate = referenceTimestamp.toDate();
      final daysOld = now.difference(referenceDate).inDays;
      
      // Check 1: Near Deletion Warning (Older than 5 months/150 days, but less than 180 days)
      if (daysOld >= 150 && daysOld < 180) {
        bool warningSent = data['deletionWarningSent'] ?? false;
        
        if (!warningSent) {
          // Send Warning Notification
          await _sendNotification(
            title: 'Image Deletion Warning',
            subtitle: 'Images for Issue ${doc.id} will be permanently deleted in ${180 - daysOld} days due to the 6-month retention policy.',
            issueId: doc.id,
            type: 'issue',
          );
          // Mark warning as sent so we don't spam them every day
          await doc.reference.update({'deletionWarningSent': true});
        }
      }
      
      // Check 2: Actual Deletion (Older than 6 months / 180 days)
      else if (daysOld >= 180) {
        List<dynamic> imageUrls = data['imageUrls'] ?? [];
        
        if (imageUrls.isNotEmpty) {
          // 1. Tell your PHP server to delete the files
          for (String url in imageUrls) {
            try {
              // IMPORTANT: You must create a delete_image.php file on your server to handle this POST request
              await http.post(
                Uri.parse('http://buildcare.atigalle.x10.mx/api/delete_image.php'), 
                body: {'file_url': url},
              );
            } catch (e) {
              debugPrint('Failed to ping PHP server to delete image: $url');
            }
          }

          // 2. Remove the URLs from Firestore
          await doc.reference.update({
            'imageUrls': [],
            'imagesDeletedAt': FieldValue.serverTimestamp(),
          });

          // 3. Send final deletion notification
          await _sendNotification(
            title: 'Images Automatically Deleted',
            subtitle: 'Images for Issue ${doc.id} were permanently removed as they exceeded the 6-month retention policy.',
            issueId: doc.id,
            type: 'issue',
          );
        }
      }
    }
  } catch (e) {
    debugPrint('Error running background image cleanup: $e');
  }
}

// Helper function to send notifications to TOs and Engineers
Future<void> _sendNotification({
  required String title,
  required String subtitle,
  required String issueId,
  required String type,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'title': title,
    'subtitle': subtitle,
    'body': subtitle,
    'type': type,
    'issueId': issueId,
    'timestamp': FieldValue.serverTimestamp(),
    // Targets specifically the user types handling your notifications
    'targetRoles': ['Technical Officer', 'District Engineer', 'Provincial Engineer', 'Chief Engineer'],
    'readBy': [], 
    'isSystemGenerated': true,
  });
}
// ---------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildCare',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- The Main Splash Screen Widget ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Add SingleTickerProviderStateMixin for animation controller
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // --- Initialize the Animation Controller and Animations ---
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Animation duration
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Slide animation
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start the animations
    _controller.forward();

    // After a delay, navigate to the login screen.
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed to free up resources
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // --- The Animated Logo Image ---
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                // Pointing to your GIF in the lib/src folder
                child: Image.asset(
                  'lib/src/my.gif', 
                  width: 250,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) {
                    // This will show if the asset fails to load
                    return const Icon(Icons.broken_image, size: 150, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Animated Text ---
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Building Connections',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}