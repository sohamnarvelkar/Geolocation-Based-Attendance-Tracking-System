import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Top-level background message handler — must be a top-level function so the
/// Flutter isolate can call it when the app is terminated or in the background.
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  // Firebase is already initialised by the time this callback fires.
  // Heavy processing can be done here if needed; keep it short.
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ─── Initialise ─────────────────────────────────────────────────────────────

  /// Call once, after [Firebase.initializeApp()], in main().
  /// [navigatorKey] is used to show in-app SnackBars for foreground messages.
  static Future<void> initialize(
      GlobalKey<NavigatorState> navigatorKey) async {
    // Ask the user for notification permission (iOS / Android 13+).
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // On iOS, show notifications even when the app is in the foreground.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Display a SnackBar whenever a notification arrives while the app is open.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final notification = message.notification;
      if (notification == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (notification.body != null && notification.body!.isNotEmpty)
                Text(notification.body!),
            ],
          ),
        ),
      );
    });
  }

  // ─── Token management ────────────────────────────────────────────────────────

  /// Fetch the current FCM token and persist it in the signed-in user's
  /// Firestore document.  Also registers a listener to refresh the token.
  static Future<void> saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _fcm.getToken();
    if (token != null) {
      await _updateTokenInFirestore(user.uid, token);
    }

    // Keep the stored token fresh whenever Firebase rotates it.
    _fcm.onTokenRefresh.listen((newToken) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      await _updateTokenInFirestore(currentUser.uid, newToken);
    });
  }

  static Future<void> _updateTokenInFirestore(
      String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }

  /// Remove the FCM token from Firestore and delete it locally so no
  /// notifications are sent to this device after logout.
  static Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': null});
    }
    await _fcm.deleteToken();
  }

  // ─── Topic subscriptions ─────────────────────────────────────────────────────

  /// Subscribe to the topic that matches the user's role:
  /// • teachers → topic "teachers"
  /// • students → topic "students"
  static Future<void> subscribeToRoleTopic(String role) async {
    final topic = role == 'teacher' ? 'teachers' : 'students';
    await _fcm.subscribeToTopic(topic);
  }

  /// Unsubscribe from all role topics — called on logout.
  static Future<void> unsubscribeFromAllTopics() async {
    await _fcm.unsubscribeFromTopic('students');
    await _fcm.unsubscribeFromTopic('teachers');
  }
}
