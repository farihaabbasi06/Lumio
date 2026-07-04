import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SIGN UP
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // LOGIN
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // CURRENT USER
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // AUTH STATE STREAM (important for auto-login)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}