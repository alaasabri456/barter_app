// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

import '../../../data/repositories/trade_repository.dart';
import '../../trade/models/trade_offer.dart';

/// ViewModel for trade-related UI state and operations.
class TradeViewModel extends ChangeNotifier {
  final TradeRepository _tradeRepository;

  TradeViewModel({required TradeRepository tradeRepository})
      : _tradeRepository = tradeRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ─── Trade CRUD ───────────────────────────────────────────────────────

  Future<String> createTradeOffer(TradeOffer trade) async {
    _setLoading(true);
    try {
      return await _tradeRepository.createTradeOffer(trade);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTradeStatus({
    required String tradeId,
    required TradeStatus newStatus,
    required String userId,
    required String userName,
  }) async {
    _setLoading(true);
    try {
      await _tradeRepository.updateTradeStatus(
        tradeId: tradeId,
        newStatus: newStatus,
        userId: userId,
        userName: userName,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addDeliveryProvidedByUser({
    required String tradeId,
    required String userId,
  }) async {
    await _tradeRepository.addDeliveryProvidedByUser(
      tradeId: tradeId,
      userId: userId,
    );
  }

  // ─── Trade queries ────────────────────────────────────────────────────

  Future<List<TradeOffer>> getReceivedTrades(String userId) async {
    return await _tradeRepository.getReceivedTrades(userId);
  }

  Stream<List<TradeOffer>> streamReceivedTrades(String userId) {
    return _tradeRepository.streamReceivedTrades(userId);
  }

  Future<List<TradeOffer>> getSentTrades(String userId) async {
    return await _tradeRepository.getSentTrades(userId);
  }

  Stream<List<TradeOffer>> streamSentTrades(String userId) {
    return _tradeRepository.streamSentTrades(userId);
  }

  Future<void> debugCheckReceivedTrades(String userId) async {
    await _tradeRepository.debugCheckReceivedTrades(userId);
  }

  Future<List<TradeOffer>> getPendingTradesForProduct(
      String productId) async {
    return await _tradeRepository.getPendingTradesForProduct(productId);
  }

  Future<List<TradeOffer>> getCounterOffersForTrade(
      String parentTradeId) async {
    return await _tradeRepository.getCounterOffersForTrade(parentTradeId);
  }

  Future<int> getPendingTradeCountForProduct(String productId) async {
    return await _tradeRepository.getPendingTradeCountForProduct(productId);
  }

  Future<bool> isProductInPendingTrade(String productId) async {
    return await _tradeRepository.isProductInPendingTrade(productId);
  }

  Future<bool> isDuplicateTrade({
    required String userId,
    required String targetProductId,
    required List<String> offeredProductIds,
  }) async {
    return await _tradeRepository.isDuplicateTrade(
      userId: userId,
      targetProductId: targetProductId,
      offeredProductIds: offeredProductIds,
    );
  }

  Future<TradeOffer?> getAcceptedTradeBetweenUsers({
    required String userId1,
    required String userId2,
    required String productId,
  }) async {
    return await _tradeRepository.getAcceptedTradeBetweenUsers(
      userId1: userId1,
      userId2: userId2,
      productId: productId,
    );
  }

  // ─── Counter offers ───────────────────────────────────────────────────

  Future<void> addCounterOffer({
    required String tradeId,
    required TradeCounterOffer counterOffer,
    required String userId,
    required String userName,
  }) async {
    _setLoading(true);
    try {
      await _tradeRepository.addCounterOffer(
        tradeId: tradeId,
        counterOffer: counterOffer,
        userId: userId,
        userName: userName,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptCounterOffer({
    required String tradeId,
    required String counterOfferId,
    required String userId,
    required String userName,
  }) async {
    _setLoading(true);
    try {
      await _tradeRepository.acceptCounterOffer(
        tradeId: tradeId,
        counterOfferId: counterOfferId,
        userId: userId,
        userName: userName,
      );
    } finally {
      _setLoading(false);
    }
  }

  // ─── Trade history ────────────────────────────────────────────────────

  Future<List<TradeHistory>> getTradeHistory(String tradeId) async {
    return await _tradeRepository.getTradeHistory(tradeId);
  }

  Future<void> checkAndExpireTrades() async {
    await _tradeRepository.checkAndExpireTrades();
  }

  Future<void> rejectOtherTradeOffers({
    required String productId,
    required String acceptedTradeId,
  }) async {
    await _tradeRepository.rejectOtherTradeOffers(
      productId: productId,
      acceptedTradeId: acceptedTradeId,
    );
  }
}
