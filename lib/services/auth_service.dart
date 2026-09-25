import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'device_service.dart';

class GoogleSignInResult {
  final String? error;
  final bool isNewUser;
  GoogleSignInResult({this.error, this.isNewUser = false});
}

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final DeviceService _deviceService = DeviceService();
  bool _googleInitialized = false;

  fb_auth.User? get currentUser => _auth.currentUser;

  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<String> _generateReferralCode(String uid) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();

    for (int attempt = 0; attempt < 5; attempt++) {
      final code = List.generate(
          6, (_) => chars[rand.nextInt(chars.length)]).join();
      final codeRef = _firestore.collection('referral_codes').doc(code);
      final codeSnap = await codeRef.get();
      if (!codeSnap.exists) {
        await codeRef.set({'uid': uid});
        return code;
      }
    }
    return '${uid.substring(0, 6).toUpperCase()}${rand.nextInt(99)}';
  }

  Future<String?> linkReferralCode(String rawCode) async {
    final uid = currentUser?.uid;
    if (uid == null) return 'Not logged in';

    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return null;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final alreadyUsed = userSnap.data()?['referralCodeUsed'] ?? '';
      if (alreadyUsed.toString().isNotEmpty) {
        return 'A referral code has already been applied to your account';
      }

      final codeSnap =
          await _firestore.collection('referral_codes').doc(code).get();
      if (!codeSnap.exists) {
        return 'Invalid referral code';
      }
      final referrerUid = codeSnap.data()?['uid'];
      if (referrerUid == null || referrerUid == uid) {
        return 'You cannot use your own referral code';
      }

      await _firestore.collection('referrals').add({
        'referrerUid': referrerUid,
        'referredUid': uid,
        'referralCode': code,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userRef.update({'referralCodeUsed': code});

      return null;
    } catch (e) {
      return 'Could not apply referral code. Please try again.';
    }
  }

  // Returns null if OK to proceed, or an error message if this device
  // already has an account registered (Phase 15 fraud check).
  Future<String?> _checkAndRegisterDevice(String uid) async {
    try {
      final deviceId = await _deviceService.getDeviceId();
      if (deviceId == 'unknown_platform') return null; // don't block non-Android

      final deviceRef = _firestore.collection('devices').doc(deviceId);
      final deviceSnap = await deviceRef.get();

      if (deviceSnap.exists) {
        final existingUid = deviceSnap.data()?['uid'];
        if (existingUid != null && existingUid != uid) {
          return 'An account already exists on this device. Multiple accounts per device are not allowed.';
        }
      }

      await deviceRef.set({
        'uid': uid,
        'registeredAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (_) {
      // Don't block signup if the device check itself fails (e.g. offline)
      return null;
    }
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final deviceError = await _checkAndRegisterDevice(uid);
      if (deviceError != null) {
        await credential.user!.delete();
        return deviceError;
      }

      await credential.user!.updateDisplayName(name);

      final myReferralCode = await _generateReferralCode(uid);

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'walletBalance': 0,
        'lockedBonus': 10,
        'unlockedBonus': 0,
        'referralCode': myReferralCode,
        'referralCodeUsed': '',
        'signInMethod': 'email',
        'emailVerified': false,
      });

      await credential.user!.sendEmailVerification();

      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      return _friendlyAuthError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      return _friendlyAuthError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
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

      final docSnap = await _firestore.collection('users').doc(uid).get();
      bool isNewUser = false;

      if (!docSnap.exists) {
        final deviceError = await _checkAndRegisterDevice(uid);
        if (deviceError != null) {
          await _auth.signOut();
          await _googleSignIn.signOut();
          return GoogleSignInResult(error: deviceError);
        }

        isNewUser = true;
        final myReferralCode = await _generateReferralCode(uid);

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'name': userCred.user!.displayName ?? '',
          'email': userCred.user!.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'walletBalance': 0,
          'lockedBonus': 10,
          'unlockedBonus': 0,
          'referralCode': myReferralCode,
          'referralCodeUsed': '',
          'signInMethod': 'google',
          'emailVerified': true,
        });
      }

      return GoogleSignInResult(isNewUser: isNewUser);
    } catch (e) {
      return GoogleSignInResult(error: 'Google sign-in failed: $e');
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      return e.message ?? 'Could not send reset email.';
    }
  }

  Future<String?> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return null;
    } catch (e) {
      return 'Could not resend verification email.';
    }
  }

  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  bool get isEmailVerified {
    final user = _auth.currentUser;
    final isGoogleUser =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    return isGoogleUser || (user?.emailVerified ?? false);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}