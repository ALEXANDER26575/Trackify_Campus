import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'admin_dashboard.dart';
import 'student_dashboard.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const SplashScreen({super.key, required this.toggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Wait for 3 seconds to show off your logo
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No user? Go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: widget.toggleTheme)),
      );
    } else {
      // User exists? Check their role in Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (userDoc.exists && userDoc['role'] == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboard(toggleTheme: widget.toggleTheme)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentDashboard(toggleTheme: widget.toggleTheme)),
          );
        }
      } catch (e) {
        // If Firestore fails, default to Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: widget.toggleTheme)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF240b36), Color(0xFFc31432)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero-style logo
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Image.asset("assets/logo.png", height: 120, errorBuilder: (context, e, s) {
                return const Icon(Icons.school, size: 100, color: Colors.white);
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              "TRACKIFY",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}