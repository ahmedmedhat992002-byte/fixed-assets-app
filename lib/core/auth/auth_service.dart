import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../sync/models/company_user_local.dart';
import '../utils/data_utils.dart'; // Added for safe extraction
import '../chat/fcm_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Auth Error Domain
// ═══════════════════════════════════════════════════════════════════════════

enum AuthErrorKind {
  invalidEmail,
  wrongPassword,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  userDisabled,
  tooManyRequests,
  networkError,
  userProfileMissing,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.kind, this.message);

  final AuthErrorKind kind;
  final String message;

  factory AuthException.fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthException(
          AuthErrorKind.invalidEmail,
          'The email address is not valid.',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Deliberately vague — never reveal which is wrong.
        return const AuthException(
          AuthErrorKind.wrongPassword,
          'Incorrect email or password. Please try again.',
        );
      case 'email-already-in-use':
        return const AuthException(
          AuthErrorKind.emailAlreadyInUse,
          'An account already exists for this email address.',
        );
      case 'weak-password':
        return const AuthException(
          AuthErrorKind.weakPassword,
          'Password is too weak. Use at least 8 characters.',
        );
      case 'user-disabled':
        return const AuthException(
          AuthErrorKind.userDisabled,
          'This account has been disabled. Contact support.',
        );
      case 'too-many-requests':
        return const AuthException(
          AuthErrorKind.tooManyRequests,
          'Too many failed attempts. Please try again later.',
        );
      case 'network-request-failed':
        return const AuthException(
          AuthErrorKind.networkError,
          'Network error. Check your internet connection.',
        );
      default:
        return AuthException(
          AuthErrorKind.unknown,
          e.message ?? 'An unexpected error occurred.',
        );
    }
  }

  @override
  String toString() => 'AuthException($kind): $message';
}

// ═══════════════════════════════════════════════════════════════════════════
//  Auth Status
// ═══════════════════════════════════════════════════════════════════════════

enum AuthStatus {
  /// Firebase hasn't yet reported auth state (cold boot, first frame).
  initial,

  /// An async operation is in progress.
  loading,

  /// User is signed in and email is verified.
  authenticated,

  /// User is signed in but email is NOT yet verified.
  emailVerificationRequired,

  /// No user is signed in.
  unauthenticated,

  /// The last operation produced an error.
  error,
}

// ═══════════════════════════════════════════════════════════════════════════
//  Social Provider Enum  (scalable for Google, Apple, etc.)
// ═══════════════════════════════════════════════════════════════════════════

/// Social sign-in providers. Add entries here as you enable them in Firebase.
enum SocialProvider { google }

// ═══════════════════════════════════════════════════════════════════════════
//  AuthService
// ═══════════════════════════════════════════════════════════════════════════

/// Production-ready Firebase Auth service.
///
/// Responsibilities:
///  • Email/password sign-in, registration, sign-out
///  • Email verification lifecycle (send + check + resend)
///  • Password reset via email
///  • Provider-based social sign-in scaffold (Google-ready)
///  • User profile caching in Hive for offline access
///  • [AuthStatus] + [AuthException] exposed for clean UI binding
class AuthService extends ChangeNotifier {
  /// Safe to call at any point — does NOT touch Firebase.
  AuthService();

  /// Must be called ONCE, AFTER [Firebase.initializeApp()] has completed.
  /// Starts listening to [FirebaseAuth.authStateChanges] and resolves
  /// the initial auth state before the first frame is rendered.
  void initialize() {
    bool authResolved = false;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      authResolved = true;
      _onAuthStateChanged(user);
      if (user != null) {
        updatePresence(true);
        FcmService().listenToForegroundMessages();
      }
    });

    // Safety timeout: if Firebase Auth stream hasn't fired in 5 seconds
    // (common on sideloaded iOS apps), force the user to the login screen.
    Future.delayed(const Duration(seconds: 5), () {
      if (!authResolved) {
        debugPrint(
          '[AuthService] Auth stream timeout — forcing unauthenticated',
        );
        _setStatus(AuthStatus.unauthenticated);
      }
    });
  }

  // ── State ─────────────────────────────────────────────────────────────────

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get requiresEmailVerification =>
      _status == AuthStatus.emailVerificationRequired;

  CompanyUserLocal? _profile;
  CompanyUserLocal? get profile => _profile;

  /// The raw Firebase user, useful for email / displayName access in UI.
  User? get firebaseUser => FirebaseAuth.instance.currentUser;

  AuthException? _lastError;
  AuthException? get lastError => _lastError;

  // ── Public Auth API ───────────────────────────────────────────────────────

  /// Signs in with email and password.
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Ensure the Firestore user document exists with the email for chat lookup.
      // We wrap this in a try-catch to ensure that even if Firestore rules are
      // not yet fully propagated, the user can still enter the app.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'email': email.trim().toLowerCase(),
              'name': cred.user!.displayName ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        // Silently fail sync
      }

      await _handleSignedInUser(cred.user!);
      await updatePresence(true);
      // Save FCM token for push notifications
      FcmService().initForUser(cred.user!.uid).ignore();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthException.fromFirebase(e));
      return false;
    } catch (e) {
      _setError(
        AuthException(AuthErrorKind.unknown, 'SIGNIN_ERR: ${e.toString()}'),
      );
      return false;
    }
  }

  /// Registers a new account and sends a verification email.
  /// On success, status becomes [AuthStatus.emailVerificationRequired].
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading();
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Optionally set display name.
      if (displayName != null && displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }

      // Send verification email immediately after account creation.
      await cred.user?.sendEmailVerification();

      // 3. Create/update the Firestore user document with basic info.
      // This is essential for the Chat search to work by email.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'email': email.trim().toLowerCase(),
              'name': displayName?.trim() ?? '',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[AuthService] Registration Firestore sync failed: $e');
      }

      _setStatus(AuthStatus.emailVerificationRequired);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthException.fromFirebase(e));
      return false;
    } catch (e) {
      _setError(
        AuthException(AuthErrorKind.unknown, 'REG_ERR: ${e.toString()}'),
      );
      return false;
    }
  }

  /// Re-sends the email verification link to the current user.
  Future<bool> resendEmailVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthException.fromFirebase(e));
      return false;
    }
  }

  /// Reloads the Firebase user and checks if email is now verified.
  /// Call this after the user taps "I've verified my email".
  Future<bool> checkEmailVerified() async {
    _setLoading();
    await FirebaseAuth.instance.currentUser?.reload();
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (verified) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      try {
        await _fetchAndCacheProfile(uid);
        return true;
      } catch (e) {
        // Profile doesn't exist yet (new user) — still mark authenticated.
        _setStatus(AuthStatus.authenticated);
        return true;
      }
    }

    _setStatus(AuthStatus.emailVerificationRequired);
    return false;
  }

  /// Sends a password reset email. Returns true on success.
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      _setStatus(AuthStatus.unauthenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthException.fromFirebase(e));
      return false;
    }
  }

  /// Signs out, clears local Hive cache, and transitions to unauthenticated.
  /// Throws [AuthException] on failure — callers should catch and show UI.
  Future<void> signOut() async {
    _setLoading();
    try {
      if (firebaseUser != null) {
        await updatePresence(false);
        FcmService().removeTokenForUser(firebaseUser!.uid).ignore();
      }
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      _setError(AuthException.fromFirebase(e));
      rethrow;
    } catch (e) {
      final err = AuthException(
        AuthErrorKind.unknown,
        'Sign-out failed: ${e.toString()}',
      );
      _setError(err);
      rethrow;
    } finally {
      // Always clear local cache — even if Firebase signOut fails, the
      // local session should be invalidated so the user is not stuck.
      if (!Hive.isBoxOpen('current_user')) {
        await Hive.openBox<CompanyUserLocal>('current_user');
      }
      final box = Hive.box<CompanyUserLocal>('current_user');
      await box.clear();
      _profile = null;
      if (_status == AuthStatus.loading) {
        _setStatus(AuthStatus.unauthenticated);
      }
    }
  }

  /// Clears the last error (e.g. after user dismisses the error banner).
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Called by the splash safety timeout when Firebase hasn't responded
  /// in time. Moves the user to [AuthStatus.unauthenticated] so they see
  /// the login screen instead of being stuck on the splash.
  void forceUnauthenticated() {
    if (_status == AuthStatus.initial || _status == AuthStatus.loading) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Google Sign-In
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initiates the Google Sign-In flow.
  ///
  /// Returns [true] if sign-in was successful, [false] otherwise.
  /// Handles user cancellation gracefully without throwing an error.
  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      // 1. Trigger the Google authentication flow
      final googleUser = await GoogleSignIn().signIn();

      // If user cancels the sign-in modal, googleUser is null
      if (googleUser == null) {
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }

      // 2. Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // 3. Create a new Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // 5. Hand off to the standard auth pipeline
      // 5. Ensure the Firestore user document exists with the email for chat lookup.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': userCredential.user!.email?.trim().toLowerCase(),
              'name': userCredential.user!.displayName?.trim() ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[AuthService] Google Sign-In Firestore sync failed: $e');
      }

      await _handleSignedInUser(userCredential.user!);
      // Save FCM token for push notifications
      FcmService().initForUser(userCredential.user!.uid).ignore();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _setError(
          const AuthException(
            AuthErrorKind.emailAlreadyInUse,
            'An account already exists with the same email address but different sign-in credentials.',
          ),
        );
      } else {
        _setError(AuthException.fromFirebase(e));
      }
      return false;
    } catch (e) {
      _setError(
        AuthException(
          AuthErrorKind.unknown,
          'Google Sign-In failed: ${e.toString()}',
        ),
      );
      return false;
    }
  }

  // ── Internal auth state listener ──────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _profile = null;
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    if (!user.emailVerified) {
      _setStatus(AuthStatus.emailVerificationRequired);
      return;
    }

    // Try Hive cache before hitting Firestore.
    if (!Hive.isBoxOpen('current_user')) {
      await Hive.openBox<CompanyUserLocal>('current_user');
    }
    final box = Hive.box<CompanyUserLocal>('current_user');
    final cached = box.get('profile');
    if (cached != null && cached.uid == user.uid) {
      _profile = cached;
      _setStatus(AuthStatus.authenticated);
      FcmService().initForUser(user.uid).ignore(); // Initialize FCM token for cached user
      return;
    }

    _setLoading();
    try {
      await _fetchAndCacheProfile(user.uid);
      FcmService().initForUser(user.uid).ignore(); // Initialize FCM token after fetch
    } catch (_) {
      // New user — profile not in Firestore yet.
      _setStatus(AuthStatus.authenticated);
      FcmService().initForUser(user.uid).ignore(); // Initialize FCM token for new user
    }
  }

  Future<void> _handleSignedInUser(User user) async {
    if (!user.emailVerified) {
      _setStatus(AuthStatus.emailVerificationRequired);
      return;
    }
    await _fetchAndCacheProfile(user.uid);
  }

  Future<void> _fetchAndCacheProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        // New user — no Firestore profile yet (will be created by admin).
        _setStatus(AuthStatus.authenticated);
        return;
      }

      final data = doc.data()!;
      final deviceId = await _resolveDeviceId();

      final p = CompanyUserLocal(
        uid: uid,
        companyId: DataUtils.asString(data['companyId']),
        role: DataUtils.asString(data['role'], 'viewer'),
        name: DataUtils.asString(
          data['name'] ?? data['firstName'] ?? data['displayName'],
        ),
        email: DataUtils.asString(data['email']),
        deviceId: deviceId,
      );

      if (!Hive.isBoxOpen('current_user')) {
        await Hive.openBox<CompanyUserLocal>('current_user');
      }
      final box = Hive.box<CompanyUserLocal>('current_user');
      await box.put('profile', p);
      _profile = p;
      _setStatus(AuthStatus.authenticated);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint(
          '[AuthService] Firestore permission-denied — rules may not be '
          'deployed yet. Marking user as authenticated. Error: $e',
        );
      } else {
        debugPrint('[AuthService] FirebaseException (${e.code}): $e');
      }
      _useCachedProfileOrAuthenticate();
    } catch (e) {
      // Catches PlatformException (offline), SocketException, or any other
      // unexpected error thrown by the Firestore plugin before it has a chance
      // to wrap it into a FirebaseException.
      debugPrint('[AuthService] Unexpected error fetching profile: $e');
      _useCachedProfileOrAuthenticate();
    }
  }

  /// Falls back to the local Hive-cached profile when Firestore is
  /// unreachable, then marks the user as authenticated regardless.
  void _useCachedProfileOrAuthenticate() {
    final box = Hive.box<CompanyUserLocal>('current_user');
    final cached = box.get('profile');
    if (cached != null) {
      _profile = cached;
    }
    _setStatus(AuthStatus.authenticated);
  }

  // ── State helpers ─────────────────────────────────────────────────────────

  void _setLoading() {
    _lastError = null;
    _status = AuthStatus.loading;
    notifyListeners();
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  void _setError(AuthException e) {
    _lastError = e;
    _status = AuthStatus.error;
    notifyListeners();
  }

  static Future<String> _resolveDeviceId() async {
    if (kIsWeb) return 'web';
    final info = DeviceInfoPlugin();
    try {
      return (await info.androidInfo).id;
    } catch (_) {}
    try {
      return (await info.iosInfo).identifierForVendor ?? 'ios_unknown';
    } catch (_) {}
    return 'unknown_device';
  }

  /// Updates the user's online status in Firestore.
  Future<void> updatePresence(bool isOnline) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AuthService] updatePresence failed: $e');
    }
  }
}
