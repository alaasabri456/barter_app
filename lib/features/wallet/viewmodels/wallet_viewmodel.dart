import 'package:flutter/foundation.dart';

import '../../../data/repositories/wallet_repository.dart';
import '../models/wallet_transaction_model.dart';
import '../models/withdrawal_request_model.dart';

/// ViewModel for wallet-related UI state and operations.
class WalletViewModel extends ChangeNotifier {
  final WalletRepository _walletRepository;

  WalletViewModel({required WalletRepository walletRepository})
      : _walletRepository = walletRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> requestWithdrawal(WithdrawalRequestModel request) async {
    _setLoading(true);
    try {
      await _walletRepository.requestWithdrawal(request);
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<WalletTransactionModel>> getWalletTransactions(String userId) {
    return _walletRepository.getWalletTransactions(userId);
  }

  Stream<List<WithdrawalRequestModel>> getSellerWithdrawalRequests(
      String sellerId) {
    return _walletRepository.getSellerWithdrawalRequests(sellerId);
  }

  Stream<List<WithdrawalRequestModel>> getAllWithdrawalRequests() {
    return _walletRepository.getAllWithdrawalRequests();
  }

  Future<void> updateWithdrawalStatus(
      String requestId, WithdrawalStatus newStatus) async {
    _setLoading(true);
    try {
      await _walletRepository.updateWithdrawalStatus(requestId, newStatus);
    } finally {
      _setLoading(false);
    }
  }
}
