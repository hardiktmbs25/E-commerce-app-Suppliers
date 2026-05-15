// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../core/errors/failures.dart';
import '../core/utils/logger.dart';

/// Wraps FirebaseAuth. Controllers never import firebase_auth directly.
///
/// WHY IT EXISTS:
/// Centralizes all auth error mapping (FirebaseAuthException codes → human messages),
/// token refresh, and user stream observation. Makes controllers testable
/// by allowing this services to be mocked.
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register ──────────────────────────────────────────────────────────
  Future<Result<UserCredential>> register(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      return Result.success(cred);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      AppLogger.e('AuthService.register', e);
      return Result.failure(const UnknownFailure());
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────
  Future<Result<UserCredential>> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      return Result.success(cred);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      AppLogger.e('AuthService.login', e);
      return Result.failure(const UnknownFailure());
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      return Result.failure(const UnknownFailure());
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    AppLogger.i('AuthService: signed out');
  }

  // ── Error mapper ──────────────────────────────────────────────────────
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':          return 'No account found with this email.';
      case 'wrong-password':          return 'Incorrect password. Please try again.';
      case 'email-already-in-use':    return 'Email already registered. Please login.';
      case 'invalid-email':           return 'Invalid email address.';
      case 'weak-password':           return 'Password must be at least 6 characters.';
      case 'user-disabled':           return 'Account disabled. Contact support.';
      case 'too-many-requests':       return 'Too many attempts. Try again later.';
      case 'network-request-failed':  return 'No internet connection.';
      default: return e.message ?? 'Authentication failed.';
    }
  }
}