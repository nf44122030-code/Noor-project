import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<User?> _user = Rx<User?>(null);
  final RxMap<String, dynamic> _userProfile = <String, dynamic>{}.obs;
  final RouterRefreshListenable routerRefreshListenable = RouterRefreshListenable();
  final RxBool _isLoading = true.obs;
  final RxBool _isEmailVerified = false.obs;
  final RxBool _isGuestMode = false.obs;
  final RxBool _isExpertMode = false.obs;
  final RxMap<String, dynamic> _expertProfile = <String, dynamic>{}.obs;
  final RxnString _lastErrorMessage = RxnString();
  StreamSubscription? _stripeSubscription;

  User? get user => _user.value;
  bool get isAuthenticated => _user.value != null || _isGuestMode.value;
  bool get isGuest => _isGuestMode.value || (_user.value?.isAnonymous ?? false);
  bool get isEmailVerified => _isEmailVerified.value;
  bool get isLoading => _isLoading.value;
  bool get isExpertMode => _isExpertMode.value;
  Map<String, dynamic> get expertProfile => _expertProfile;
  String? get lastErrorMessage => _lastErrorMessage.value;

  String get userEmail => _user.value?.email ?? '';
  String get userName => _userProfile['name'] ?? _user.value?.displayName ?? '';
  String get phone => _userProfile['phone'] ?? '';
  String get location => _userProfile['location'] ?? '';
  String get bio => _userProfile['bio'] ?? '';
  String get profileImage => _userProfile['profile_image'] ?? '';
  int get userId => (_userProfile['id'] ?? 0);
  int get sessionsCount => (_userProfile['sessions_count'] ?? 0);
  int get queriesCount => (_userProfile['queries_count'] ?? 0);
  int get reportsCount => (_userProfile['reports_count'] ?? 0);

  // Subscription Details
  String get currentPlanId => _userProfile['current_plan_id'] ?? 'free';
  String get currentPlanName => _userProfile['current_plan_name'] ?? 'Starter';
  bool get isYearlyPlan => _userProfile['is_yearly_plan'] ?? false;
  DateTime? get planExpiration {
    final exp = _userProfile['plan_expiration'];
    if (exp is Timestamp) return exp.toDate();
    if (exp is String) return DateTime.tryParse(exp);
    return null;
  }
  bool get isPremium => (_userProfile['stripe_active'] == true) || (currentPlanId != 'free' && (planExpiration == null || planExpiration!.isAfter(DateTime.now())));

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_auth.authStateChanges());
    ever(_user, (_) {
      if (!_isGuestMode.value) {
        _onAuthStateChanged(_user.value);
      }
      routerRefreshListenable.notify();
    });
    ever(_isLoading, (_) {
       routerRefreshListenable.notify();
    });
    ever(_isEmailVerified, (_) {
      routerRefreshListenable.notify();
    });
    ever(_isGuestMode, (_) {
      routerRefreshListenable.notify();
    });
    ever(_isExpertMode, (_) {
      routerRefreshListenable.notify();
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      _isEmailVerified.value = user.emailVerified;
      await _fetchUserProfile(user.uid);
    } else {
      _userProfile.clear();
      _expertProfile.clear();
      _isEmailVerified.value = false;
      _isExpertMode.value = false;
    }
    _isLoading.value = false;
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile.assignAll(doc.data()!);
      } else {
        // Create profile if it doesn't exist
        final profile = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'name': _user.value?.displayName ?? '',
          'email': _user.value?.email ?? '',
          'sessions_count': 0,
          'queries_count': 0,
          'reports_count': 0,
          'created_at': FieldValue.serverTimestamp(),
          'current_plan_id': 'free',
          'current_plan_name': 'Starter',
          'is_yearly_plan': false,
          'plan_expiration': null,
        };
        await _firestore.collection('users').doc(uid).set(profile);
        _userProfile.assignAll(profile);
      }

      // Listen to Stripe subscriptions subcollection for real-time Premium status
      await _stripeSubscription?.cancel();
      _stripeSubscription = _firestore
          .collection('customers')
          .doc(uid)
          .collection('subscriptions')
          .where('status', whereIn: ['trialing', 'active'])
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final subData = snapshot.docs.first.data();
          _userProfile['current_plan_id'] = subData['role'] ?? 'premium';
          _userProfile['stripe_active'] = true;
        } else {
          _userProfile['stripe_active'] = false;
        }
        _userProfile.refresh();
      });

      // Check if user is an expert
      if (_user.value?.email != null) {
        final expertQuery = await _firestore
            .collection('experts')
            .where('email', isEqualTo: _user.value!.email)
            .limit(1)
            .get();
        if (expertQuery.docs.isNotEmpty) {
          _isExpertMode.value = true;
          _expertProfile.assignAll(expertQuery.docs.first.data());
        } else {
          _isExpertMode.value = false;
          _expertProfile.clear();
        }
      }

    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<bool> loginAsGuest() async {
    try {
      _isLoading.value = true;
      _isGuestMode.value = true;
      _isEmailVerified.value = true;
      _isExpertMode.value = false;
      _userProfile.assignAll({'name': 'Guest', 'email': ''});
      _isLoading.value = false;
      return true;
    } catch (e) {
      _lastErrorMessage.value = e.toString();
      _isGuestMode.value = false;
      _isLoading.value = false;
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading.value = true;
      _lastErrorMessage.value = null;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _lastErrorMessage.value = e.message;
      debugPrint('Login error: ${e.message}');
      return false;
    } catch (e) {
      _lastErrorMessage.value = e.toString();
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _lastErrorMessage.value = null;

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        _isLoading.value = false;
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // If it's a new user, create their Firestore profile
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Google User',
            'email': user.email,
            'role': 'student',
            'grade': 'unassigned',
            'created_at': FieldValue.serverTimestamp(),
          });
        }
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _lastErrorMessage.value = e.message;
      debugPrint('Google Sign-In Firebase Error: ${e.message}');
      return false;
    } catch (e) {
      _lastErrorMessage.value = e.toString();
      debugPrint('Google Sign-In Error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    try {
      _isLoading.value = true;
      _lastErrorMessage.value = null;

      // ── Security: Prevent multiple accounts with the same email ──────────
      // Use the modern approach: attempt creation and catch the specific error.
      // (fetchSignInMethodsForEmail is deprecated per Google's security guidance)
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);

        // Send email verification
        await credential.user!.sendEmailVerification();
        _isEmailVerified.value = false;

        final profile = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'name': name,
          'email': email,
          'sessions_count': 0,
          'queries_count': 0,
          'reports_count': 0,
          'created_at': FieldValue.serverTimestamp(),
          'current_plan_id': 'free',
          'current_plan_name': 'Starter',
          'is_yearly_plan': false,
          'plan_expiration': null,
        };
        await _firestore.collection('users').doc(credential.user!.uid).set(profile);
        _userProfile.assignAll(profile);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _lastErrorMessage.value =
            'An account with this email already exists. Please sign in instead.';
      } else {
        _lastErrorMessage.value = e.message;
      }
      debugPrint('SignUp error: ${e.message}');
      return false;
    } catch (e) {
      _lastErrorMessage.value = e.toString();
      debugPrint('SignUp error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _stripeSubscription?.cancel();
    _stripeSubscription = null;
    _isGuestMode.value = false;
    _isExpertMode.value = false;
    _isEmailVerified.value = false;
    if (_user.value != null) {
      await _auth.signOut();
    }
  }

  /// Reloads the Firebase user and returns whether email is now verified.
  Future<bool> checkEmailVerification() async {
    try {
      await _auth.currentUser?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;
      if (verified != _isEmailVerified.value) {
        _isEmailVerified.value = verified;
      }
      return verified;
    } catch (e) {
      debugPrint('checkEmailVerification error: $e');
      return false;
    }
  }

  /// Resends the verification email to the current user.
  Future<bool> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } catch (e) {
      _lastErrorMessage.value = e.toString();
      debugPrint('resendVerificationEmail error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _lastErrorMessage.value = e.toString();
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  /// Re-authenticates the current user with their password.
  /// Used by the Re-auth Gate before sensitive account operations.
  Future<bool> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      _lastErrorMessage.value = e.message;
      return false;
    } catch (e) {
      _lastErrorMessage.value = e.toString();
      return false;
    }
  }

  Future<void> updateFullProfile({
    String? name,
    String? email,
    String? phone,
    String? location,
    String? bio,
  }) async {
    if (_user.value == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (location != null) updates['location'] = location;
      if (bio != null) updates['bio'] = bio;
      updates['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(_user.value!.uid).update(updates);
      
      if (name != null) await _user.value!.updateDisplayName(name);
      if (email != null) await _user.value!.verifyBeforeUpdateEmail(email);

      _userProfile.addAll(updates);
    } catch (e) {
      debugPrint('Update profile error: $e');
    }
  }

  void updateSubscriptionStatus(Map<String, dynamic> data) {
    _userProfile.addAll(data);
  }

  Future<void> deleteAccount() async {
    if (_user.value == null) return;
    try {
      final uid = _user.value!.uid;
      await _firestore.collection('users').doc(uid).delete();
      await _user.value!.delete();
    } catch (e) {
      debugPrint('Delete account error: $e');
    }
  }

  Future<bool> uploadProfilePicture(Uint8List imageBytes) async {
    if (_user.value == null) return false;
    try {
      final uid = _user.value!.uid;
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$uid.jpg');

      // putData works on web + native. Add a 30s timeout to detect CORS/rules hangs.
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          uploadTask.cancel();
          throw TimeoutException(
              'Upload timed out. Check Firebase Storage CORS config and security rules.');
        },
      );

      final downloadUrl = await ref.getDownloadURL();
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'profile_image': downloadUrl});
      _userProfile['profile_image'] = downloadUrl;
      return true;
    } on TimeoutException catch (e) {
      debugPrint('Upload timeout: $e');
      _lastErrorMessage.value =
          'Upload timed out — Firebase Storage may need CORS configuration. See console.';
      return false;
    } catch (e) {
      debugPrint('Upload profile picture error: $e');
      _lastErrorMessage.value = 'Upload failed: ${e.toString().split("]").last.trim()}';
      return false;
    }
  }
}

class RouterRefreshListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
