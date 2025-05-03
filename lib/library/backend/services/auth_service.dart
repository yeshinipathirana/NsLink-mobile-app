// Auth Service
// Handles authentication operations for the library booking system, including admin credential verification and session management.

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Default admin credentials
  static const String defaultUsername = 'Admin';
  static const String defaultPassword = 'Admin123';

  // Verifies admin credentials and signs in
  Future<bool> loginAdmin(String username, String password) async {
    // Simple local check, no Firebase
    if (username == defaultUsername && password == defaultPassword) {
      return true;
    }
    return false;
  }

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Signs out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
