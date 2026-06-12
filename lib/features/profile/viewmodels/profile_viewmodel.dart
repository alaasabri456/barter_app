import 'package:flutter/foundation.dart';

import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';

/// ViewModel for profile-related UI state.
class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AdminRepository _adminRepository;

  ProfileViewModel({
    required AuthRepository authRepository,
    required AdminRepository adminRepository,
  })  : _authRepository = authRepository,
        _adminRepository = adminRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> updateProfile({
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

  Stream<Map<String, int>> streamProfileStats(String userId) {
    return _adminRepository.streamProfileStats(userId);
  }
}
