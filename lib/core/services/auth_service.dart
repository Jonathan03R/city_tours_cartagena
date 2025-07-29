import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _fb = FirebaseAuth.instance;
  String _toAuthEmail(String user) => '$user@citytours.local';

  Future<UserCredential> signUp(String user, String pass) {
    return _fb.createUserWithEmailAndPassword(
      email: _toAuthEmail(user),
      password: pass,
    );
  }

  Future<UserCredential> signIn(String user, String pass) {
    return _fb.signInWithEmailAndPassword(
      email: _toAuthEmail(user),
      password: pass,
    );
  }

  Future<void> signOut() => _fb.signOut();
}