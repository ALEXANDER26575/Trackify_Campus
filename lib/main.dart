import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, 
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  await NotificationService.initialize();
  
  runApp(const TrackifyApp());
}

class TrackifyApp extends StatefulWidget {
  const TrackifyApp({super.key});

  @override
  State<TrackifyApp> createState() => _TrackifyAppState();
}

class _TrackifyAppState extends State<TrackifyApp> {
  bool darkMode = false;

  void toggleTheme() {
    setState(() {
      darkMode = !darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trackify Campus',
      
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFFc31432),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF240b36),
      ),
      
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,

      home: SplashScreen(toggleTheme: toggleTheme),
    );
  }
}