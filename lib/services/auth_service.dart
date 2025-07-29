import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen for auth changes
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  Future<Map<String, dynamic>?> getUserRoleAndName(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('userRoles').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('Firestore: Found data for UID $uid: $data');
        return {'role': data['role'], 'userName': data['name']}; // Assuming 'name' is the field in Firestore
      }
      print('Firestore: No role or name found for UID $uid');
      return null;
    } catch (e) {
      print('Error getting user role and name: $e');
      return null;
    }
  }

  // Sign in with email & password
  Future<Map<String, dynamic>?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        Map<String, dynamic>? roleAndName = await getUserRoleAndName(user.uid);
        String? role = roleAndName?['role'];
        return {'user': user, 'role': role};
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return;
    }
  }
}
