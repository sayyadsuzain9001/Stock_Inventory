import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// The only accounts allowed to sign in (dashboard, add items, records).
const List<String> kAdminEmails = ['admin@stockinventory.com'];

bool isAdminEmail(String? email) =>
    email != null && kAdminEmails.contains(email.trim().toLowerCase());

/// The signed-in person.
class AppUser {
  final String uid;
  final String email;
  const AppUser({required this.uid, required this.email});

  bool get isAdmin => isAdminEmail(email);
}

/// Sign-in abstraction so the UI can be tested without Firebase.
/// Only admin accounts may sign in; any other account is signed straight
/// back out and gets a `not-admin` error.
abstract class AuthService {
  Stream<AppUser?> authStateChanges();
  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

/// Firebase Authentication (Email/Password provider).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this.auth);
  final FirebaseAuth auth;

  AppUser? _map(User? u) => u == null
      ? null
      : AppUser(uid: u.uid, email: (u.email ?? '').toLowerCase());

  @override
  Stream<AppUser?> authStateChanges() => auth.authStateChanges().map(_map);

  @override
  Future<void> signIn(String email, String password) async {
    final cred = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (!isAdminEmail(cred.user?.email)) {
      await auth.signOut();
      throw FirebaseAuthException(code: 'not-admin');
    }
  }

  @override
  Future<void> signOut() => auth.signOut();
}

/// In-memory auth used by widget tests.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? initial}) : _user = initial;
  AppUser? _user;
  final _ctrl = StreamController<AppUser?>.broadcast();
  final Map<String, String> accounts = {};

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _ctrl.stream;
  }

  void _emit(AppUser? u) {
    _user = u;
    _ctrl.add(u);
  }

  @override
  Future<void> signIn(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (accounts[e] != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    if (!isAdminEmail(e)) {
      throw FirebaseAuthException(code: 'not-admin');
    }
    _emit(AppUser(uid: 'uid-$e', email: e));
  }

  @override
  Future<void> signOut() async => _emit(null);
}

/// Human-friendly message for Firebase Auth error codes.
String authErrorMessage(Object e) {
  final code = e is FirebaseAuthException ? e.code : e.toString();
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
    case 'invalid-login-credentials':
      return 'Wrong email or password.';
    case 'not-admin':
      return 'Only the admin account can sign in.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'operation-not-allowed':
      return 'Email/Password sign-in is not enabled in Firebase yet.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a minute and try again.';
    case 'network-request-failed':
      return 'No connection to Firebase. Check your internet.';
  }
  return 'Sign-in failed ($code).';
}
