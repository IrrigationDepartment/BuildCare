import 'package:flutter/material.dart';
import 'dart:async';
import 'login.dart'; // Import the login screen
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import the generated Firebase options

// --- Main function updated to initialize Firebase ---
void main() async {
  // Ensure that Flutter bindings are initialized before calling Firebase.initializeApp
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase using the generated options file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

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
            // --- The Animated Image ---
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                // --- FIXED: Using a local asset is more reliable for splash screens ---
                // Make sure you have an 'assets' folder with this image in your project root
                // and have added it to your pubspec.yaml file.
                child: Image.asset(
                  'assets/splash_image.png',
                  width: 250,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) {
                    // This will show if the asset fails to load
                    return const Icon(Icons.map, size: 150, color: Colors.grey);
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

