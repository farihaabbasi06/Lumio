import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. SIGN UP FUNCTION
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String university,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Save additional user info to Firestore matching our UserModel structure
        await _db.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'university': university,
        });
      }
      return null; // Success (Returns null if there is no error)
    } on FirebaseAuthException catch (e) {
      return e.message; // Returns the specific Firebase error message
    } catch (e) {
      return e.toString();
    }
  }

  // 2. SIGN IN FUNCTION
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 3. SIGN OUT FUNCTION
  Future<void> signOut() async {
    await _auth.signOut();
  }
}