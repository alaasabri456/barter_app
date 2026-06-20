// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/repositories/auth_repository.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';

/// ViewModel for authentication state and operations.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Auth operations ──────────────────────────────────────────────────

  Future<UserCredential?> login(LoginRequest request) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final userCredential = await _authRepository.login(request);
      if (userCredential.user != null) {
        UserModel.currentUser = await _authRepository.getUserFromFireStore(
          userCredential.user!.uid,
        );
        _authRepository.initUserListener();
      }
      return userCredential;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> register(RegisterRequest request) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final userCredential = await _authRepository.register(request);
      return userCredential;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException) onVerificationFailed,
    required void Function(PhoneAuthCredential) onAutoVerified,
    int? forceResendingToken,
  }) async {
    try {
      await _authRepository.sendPhoneOtp(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onVerificationFailed: onVerificationFailed,
        onAutoVerified: onAutoVerified,
        forceResendingToken: forceResendingToken,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final userCredential = await _authRepository.signInWithGoogle();
      if (userCredential.user != null) {
        UserModel userModel =
            await _authRepository.handleGoogleSignInUser(userCredential.user!);
        UserModel.currentUser = userModel;
        _authRepository.initUserListener();
      }
      return userCredential;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── User profile ─────────────────────────────────────────────────────

  Future<void> addUserToFireStore(UserModel user) async {
    await _authRepository.addUserToFireStore(user);
  }

  Future<UserModel?> getUserFromFireStore(String uid) async {
    return await _authRepository.getUserFromFireStore(uid);
  }

  Future<void> updateUserFcmToken(String userId, String token) async {
    await _authRepository.updateUserFcmToken(userId, token);
  }

  Future<void> updateUserLanguage(String userId, String languageCode) async {
    await _authRepository.updateUserLanguage(userId, languageCode);
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? profileImageUrl,
    bool? is2faEnabled,
  }) async {
    _setLoading(true);
    try {
      await _authRepository.updateUserProfile(
        userId: userId,
        name: name,
        profileImageUrl: profileImageUrl,
        is2faEnabled: is2faEnabled,
      );
    } finally {
      _setLoading(false);
    }
  }

  // ─── Block / Unblock ──────────────────────────────────────────────────

  Future<void> blockUser(String userId, String blockedUserId) async {
    await _authRepository.blockUser(userId, blockedUserId);
    notifyListeners();
  }

  Future<void> unblockUser(String userId, String unblockedUserId) async {
    await _authRepository.unblockUser(userId, unblockedUserId);
    notifyListeners();
  }

  // ─── Admin whitelist ──────────────────────────────────────────────────

  Future<bool> isEmailWhitelistedAsAdmin(String email) async {
    return await _authRepository.isEmailWhitelistedAsAdmin(email);
  }

  Future<void> addToAdminWhitelist(String email) async {
    await _authRepository.addToAdminWhitelist(email);
  }

  // ─── User sync ────────────────────────────────────────────────────────

  void initUserListener() {
    _authRepository.initUserListener();
  }

  Stream<UserModel?> currentUserStream() {
    return _authRepository.currentUserStream();
  }

  @override
  void dispose() {
    _authRepository.disposeUserListener();
    super.dispose();
  }
}
