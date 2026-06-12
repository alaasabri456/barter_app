// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../admin/models/admin_stats_model.dart';
import '../../admin/models/category_suggestion_model.dart';
import '../../admin/models/report_model.dart';
import '../../authentication/models/user_model.dart';
import '../../products/models/product_model.dart';

/// ViewModel for all admin dashboard operations.
class AdminViewModel extends ChangeNotifier {
  final AdminRepository _adminRepository;
  final ReportRepository _reportRepository;
  final CategoryRepository _categoryRepository;

  AdminViewModel({
    required AdminRepository adminRepository,
    required ReportRepository reportRepository,
    required CategoryRepository categoryRepository,
  })  : _adminRepository = adminRepository,
        _reportRepository = reportRepository,
        _categoryRepository = categoryRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ─── User management ─────────────────────────────────────────────────

  Future<List<UserModel>> getAllUsers() async {
    return await _adminRepository.getAllUsers();
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _adminRepository.streamAllUsers();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    return await _adminRepository.searchUsers(query);
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    _setLoading(true);
    try {
      await _adminRepository.updateUserRole(userId: userId, newRole: newRole);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> suspendUser(String userId) async {
    _setLoading(true);
    try {
      await _adminRepository.suspendUser(userId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unsuspendUser(String userId) async {
    _setLoading(true);
    try {
      await _adminRepository.unsuspendUser(userId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUserData(String userId) async {
    _setLoading(true);
    try {
      await _adminRepository.deleteUserData(userId);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Product management ───────────────────────────────────────────────

  Future<void> deleteProductById(String productId) async {
    _setLoading(true);
    try {
      await _adminRepository.deleteProductById(productId);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<ProductModel>> getAllProductsAdmin() async {
    return await _adminRepository.getAllProductsAdmin();
  }

  // ─── Statistics ───────────────────────────────────────────────────────

  Future<AdminStats> getSystemStats() async {
    return await _adminRepository.getSystemStats();
  }

  Stream<AdminStats> streamSystemStats() {
    return _adminRepository.streamSystemStats();
  }

  Stream<Map<String, int>> streamProfileStats(String userId) {
    return _adminRepository.streamProfileStats(userId);
  }

  // ─── Reports ──────────────────────────────────────────────────────────

  Future<void> submitReport(ReportModel report) async {
    await _reportRepository.submitReport(report);
  }

  Future<List<ReportModel>> getAllReports() async {
    return await _reportRepository.getAllReports();
  }

  Stream<List<ReportModel>> streamAllReports() {
    return _reportRepository.streamAllReports();
  }

  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? adminNote,
  }) async {
    _setLoading(true);
    try {
      await _reportRepository.updateReportStatus(
        reportId: reportId,
        newStatus: newStatus,
        adminNote: adminNote,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> notifyAdminsOfReport(ReportModel report) async {
    await _reportRepository.notifyAdminsOfReport(report);
  }

  // ─── Categories ───────────────────────────────────────────────────────

  Future<String> suggestCategory({
    required String name,
    required String userId,
    required String userName,
  }) async {
    return await _categoryRepository.suggestCategory(
      name: name,
      userId: userId,
      userName: userName,
    );
  }

  Future<List<CategorySuggestion>> getCategorySuggestions({
    CategoryStatus? status,
  }) async {
    return await _categoryRepository.getCategorySuggestions(status: status);
  }

  Future<void> approveCategorySuggestion({
    required String suggestionId,
    required String adminId,
    required String adminName,
  }) async {
    _setLoading(true);
    try {
      await _categoryRepository.approveCategorySuggestion(
        suggestionId: suggestionId,
        adminId: adminId,
        adminName: adminName,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectCategorySuggestion({
    required String suggestionId,
    required String adminId,
    required String adminName,
  }) async {
    _setLoading(true);
    try {
      await _categoryRepository.rejectCategorySuggestion(
        suggestionId: suggestionId,
        adminId: adminId,
        adminName: adminName,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<List<ApprovedCategory>> getApprovedCategories() async {
    return await _categoryRepository.getApprovedCategories();
  }

  Future<void> deleteCategorySuggestion(String suggestionId) async {
    await _categoryRepository.deleteCategorySuggestion(suggestionId);
  }

  // ─── Admin helpers ────────────────────────────────────────────────────

  Future<void> addToAdminWhitelist(String email) async {
    // This delegates to the auth_repository via admin_repository's user collection
    // However since it's a shared concern, we'll use the admin repository directly
    await _adminRepository.getAdminUsers(); // placeholder; the actual method is on AuthViewModel
  }

  Future<List<UserModel>> getAdminUsers() async {
    return await _adminRepository.getAdminUsers();
  }
}
