import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth (sign up, sign in, sign out, current
/// user), abstracted so screens don't call FirebaseAuth.instance directly.
abstract class AuthService {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password});
  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<String?> currentIdToken();
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<String?> currentIdToken() async {
    final user = _auth.currentUser;
    return user == null ? null : await user.getIdToken();
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
