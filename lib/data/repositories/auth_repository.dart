// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../../features/authentication/models/login_request.dart';
import '../../features/authentication/models/register_request.dart';
import '../../features/authentication/models/user_model.dart';

/// Repository responsible for all authentication and user-profile operations.
class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AuthRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ─── Google Sign-In ───────────────────────────────────────────────────

  static final gsi.GoogleSignIn _google = gsi.GoogleSignIn.instance;
  static bool _isInitialized = false;

  Future<void> _initSignIn() async {
    if (!_isInitialized) {
      await _google.initialize(
        serverClientId:
            '460987873980-s29ubpkkass8m9c106sf491oc6rbrhrl.apps.googleusercontent.com',
      );
      _isInitialized = true;
    }
  }

  // ─── Collection helpers ───────────────────────────────────────────────

  CollectionReference<UserModel> getUsersCollection() {
    return _firestore.collection("Users").withConverter<UserModel>(
          fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );
  }

  // ─── Auth methods ─────────────────────────────────────────────────────

  Future<UserCredential> register(RegisterRequest request) async {
    return await _auth.createUserWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );
  }

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException) onVerificationFailed,
    required void Function(PhoneAuthCredential) onAutoVerified,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> login(LoginRequest request) async {
    return await _auth.signInWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _initSignIn();
    gsi.GoogleSignInAccount account = await _google.authenticate();

    final idToken = account.authentication.idToken;
    final authClient = account.authorizationClient;
    final gsi.GoogleSignInClientAuthorization? auth =
        await authClient.authorizationForScopes(['email', 'profile']);
    final accessToken = auth?.accessToken;

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<UserModel> handleGoogleSignInUser(User user) async {
    UserModel? existingUser = await getUserFromFireStore(user.uid);

    if (existingUser != null) {
      return existingUser;
    } else {
      UserModel newUser = UserModel(
        id: user.uid,
        name: user.displayName ?? 'Google User',
        email: user.email ?? '',
        favouriteProductIds: [],
        is2faEnabled: false,
      );

      await addUserToFireStore(newUser);
      return newUser;
    }
  }

  // ─── User CRUD ────────────────────────────────────────────────────────

  Future<void> addUserToFireStore(UserModel user) {
    final usersCollection = getUsersCollection();
    final usersDocument = usersCollection.doc(user.id);
    return usersDocument.set(user);
  }

  Future<UserModel?> getUserFromFireStore(String uid) async {
    final usersCollection = getUsersCollection();
    final usersDocument = usersCollection.doc(uid);
    final documentSnapshot = await usersDocument.get();
    return documentSnapshot.data();
  }

  Future<void> updateUserFcmToken(String userId, String token) async {
    try {
      final usersCollection = getUsersCollection();
      await usersCollection.doc(userId).update({'fcmToken': token});

      if (UserModel.currentUser?.id == userId) {
        UserModel.currentUser?.fcmToken = token;
      }
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  Future<void> updateUserLanguage(String userId, String languageCode) async {
    try {
      final usersCollection = getUsersCollection();
      await usersCollection.doc(userId).update({'languageCode': languageCode});

      if (UserModel.currentUser?.id == userId) {
        UserModel.currentUser?.languageCode = languageCode;
      }
    } catch (e) {
      print('Failed to update language code: $e');
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? profileImageUrl,
    bool? is2faEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (is2faEnabled != null) updates['is2faEnabled'] = is2faEnabled;

      if (updates.isEmpty) return;

      await getUsersCollection().doc(userId).update(updates);

      if (UserModel.currentUser?.id == userId) {
        if (name != null) UserModel.currentUser!.name = name;
        if (profileImageUrl != null) {
          UserModel.currentUser!.profileImageUrl = profileImageUrl;
        }
        if (is2faEnabled != null) {
          UserModel.currentUser!.is2faEnabled = is2faEnabled;
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // ─── Block / Unblock ──────────────────────────────────────────────────

  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      final usersCollection = getUsersCollection();
      await usersCollection.doc(userId).update({
        'blockedUserIds': FieldValue.arrayUnion([blockedUserId])
      });

      if (UserModel.currentUser?.id == userId) {
        if (!UserModel.currentUser!.blockedUserIds.contains(blockedUserId)) {
          UserModel.currentUser!.blockedUserIds.add(blockedUserId);
        }
      }
    } catch (e) {
      print('Failed to block user: $e');
      throw Exception('Failed to block user: $e');
    }
  }

  Future<void> unblockUser(String userId, String unblockedUserId) async {
    try {
      final usersCollection = getUsersCollection();
      await usersCollection.doc(userId).update({
        'blockedUserIds': FieldValue.arrayRemove([unblockedUserId])
      });

      if (UserModel.currentUser?.id == userId) {
        UserModel.currentUser!.blockedUserIds.remove(unblockedUserId);
      }
    } catch (e) {
      print('Failed to unblock user: $e');
      throw Exception('Failed to unblock user: $e');
    }
  }

  // ─── Admin whitelist ──────────────────────────────────────────────────

  Future<void> addToAdminWhitelist(String email) async {
    try {
      await _firestore
          .collection('AdminWhitelist')
          .doc(email.toLowerCase())
          .set({
        'email': email.toLowerCase(),
        'addedAt': Timestamp.now(),
        'addedBy': UserModel.currentUser?.id,
      });
    } catch (e) {
      throw Exception('Failed to whitelist admin: $e');
    }
  }

  Future<bool> isEmailWhitelistedAsAdmin(String email) async {
    try {
      final doc = await _firestore
          .collection('AdminWhitelist')
          .doc(email.toLowerCase())
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ─── Real-time user sync ─────────────────────────────────────────────

  Stream<UserModel?> currentUserStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('Users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
  }

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  /// Starts a persistent Firestore listener that keeps [UserModel.currentUser]
  /// in sync so the wallet balance updates without a restart.
  void initUserListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    _userSubscription?.cancel();

    _userSubscription = _firestore
        .collection('Users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        UserModel.currentUser = UserModel.fromJson(doc.data()!);
        print(
            'UserModel.currentUser synced. Balance: \${UserModel.currentUser?.walletBalance}');
      }
    });
  }

  /// Cancel the persistent user listener.
  void disposeUserListener() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }
}
