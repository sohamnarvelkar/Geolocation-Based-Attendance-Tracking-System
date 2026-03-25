import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTER USER
  Future<String?> register(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "email": email,
        "role": role,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // LOGIN USER
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // LOGOUT — clears FCM token so no stale notifications are delivered and
  // unsubscribes from all role topics before signing out.
  Future<void> logout() async {
    await NotificationService.unsubscribeFromAllTopics();
    await NotificationService.clearToken();
    await _auth.signOut();
  }
}
