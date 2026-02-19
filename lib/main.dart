import 'package:flutter/material.dart';
import 'dart:async';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// NEW: Import workmanager and your background service
import 'package:workmanager/workmanager.dart';
import 'services/issue_cleanup_service.dart'; // contains callbackDispatcher

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize Workmanager (background task) ---
  await Workmanager().initialize(
    callbackDispatcher, // top-level function from issue_cleanup_service.dart
    isInDebugMode: true, // set to false in production
  );

  // Register a periodic task (runs every ~12 hours)
  // This is a one-time registration – Workmanager handles duplicates automatically.
  Workmanager().registerPeriodicTask(
    'issue-cleanup-task',
    'issueCleanup',
    frequency: const Duration(hours: 12),
  );

  // Run the app (splash screen will show)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash Screen with Animation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- SplashScreen remains unchanged from your original ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final firebaseInitFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final splashDelayFuture = Future.delayed(const Duration(seconds: 3));

    await Future.wait([firebaseInitFuture, splashDelayFuture]);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
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
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/splash_image.png',
                  width: 250,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.map, size: 150, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Building Connections',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}