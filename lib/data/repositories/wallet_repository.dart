// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/wallet/models/wallet_transaction_model.dart';
import '../../features/wallet/models/withdrawal_request_model.dart';

/// Repository responsible for wallet and withdrawal data operations.
class WalletRepository {
  final FirebaseFirestore _firestore;

  WalletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> requestWithdrawal(WithdrawalRequestModel request) async {
    try {
      final ref = _firestore.collection('WithdrawalRequests').doc();
      final withId = WithdrawalRequestModel(
        id: ref.id,
        sellerId: request.sellerId,
        sellerName: request.sellerName,
        amount: request.amount,
        bankDetails: request.bankDetails,
        status: WithdrawalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.set(withId.toJson());
    } catch (e) {
      throw Exception('Failed to request withdrawal: $e');
    }
  }

  Stream<List<WalletTransactionModel>> getWalletTransactions(String userId) {
    return _firestore
        .collection('WalletTransactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransactionModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<WithdrawalRequestModel>> getSellerWithdrawalRequests(
      String sellerId) {
    return _firestore
        .collection('WithdrawalRequests')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalRequestModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<WithdrawalRequestModel>> getAllWithdrawalRequests() {
    return _firestore
        .collection('WithdrawalRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalRequestModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> updateWithdrawalStatus(
      String requestId, WithdrawalStatus newStatus) async {
    try {
      await _firestore
          .collection('WithdrawalRequests')
          .doc(requestId)
          .update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update withdrawal status: $e');
    }
  }
}
