import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'login_screen.dart';

// Navigator key shared with NotificationService for foreground message display.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the background handler BEFORE Firebase initialises so it is
  // available as soon as a background message arrives.
  FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

  await Firebase.initializeApp(); // ✅ Firebase init

  // Initialise FCM: request permissions, set foreground options, listen for
  // incoming messages and show in-app SnackBars.
  await NotificationService.initialize(navigatorKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const LoginScreen(),
    );
  }
}