import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  fb_auth.User? get currentUser => _auth.currentUser;

  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email & password + create Firestore user doc + send verification email
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await credential.user!.updateDisplayName(name);

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'walletBalance': 0,
        'lockedBonus': 20,
        'referralCodeUsed': referralCode ?? '',
        'signInMethod': 'email',
        'emailVerified': false,
      });

      // Send verification email (required for email/password signups)
      await credential.user!.sendEmailVerification();

      return null; // null means success
    } on fb_auth.FirebaseAuthException catch (e) {
      return e.message ?? 'Signup failed. Please try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // Login with email & password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // null means success
    } on fb_auth.FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed. Please try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // Sign in with Google — no email verification needed, Google already verifies it
  Future<String?> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await _googleSignIn.initialize();
        _googleInitialized = true;
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final idToken = googleUser.authentication.idToken;

      final authClient = googleUser.authorizationClient;
      final authorization =
          await authClient.authorizationForScopes(['email', 'profile']) ??
              await authClient.authorizeScopes(['email', 'profile']);

      final credential = fb_auth.GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final uid = userCred.user!.uid;

      // Create Firestore doc only if it's a first-time Google sign-in
      final docSnap = await _firestore.collection('users').doc(uid).get();
      if (!docSnap.exists) {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'name': userCred.user!.displayName ?? '',
          'email': userCred.user!.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'walletBalance': 0,
          'lockedBonus': 20,
          'referralCodeUsed': '',
          'signInMethod': 'google',
          'emailVerified': true,
        });
      }

      return null; // null means success
    } catch (e) {
      // ignore: avoid_print
      print('GOOGLE SIGN-IN ERROR: $e');
      return 'Google sign-in failed: $e';
    }
  }

  // Forgot password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      return e.message ?? 'Could not send reset email.';
    }
  }

  // Resend verification email
  Future<String?> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return null;
    } catch (e) {
      return 'Could not resend verification email.';
    }
  }

  // Reload user and check if email is now verified
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  bool get isEmailVerified {
    final user = _auth.currentUser;
    // Google sign-in users are always considered verified
    final isGoogleUser = user?.providerData
            .any((p) => p.providerId == 'google.com') ??
        false;
    return isGoogleUser || (user?.emailVerified ?? false);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}